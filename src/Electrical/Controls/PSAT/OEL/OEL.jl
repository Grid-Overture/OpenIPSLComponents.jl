# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/OEL/OEL.mo, blocks as subsystems:
#   field_current   OpenIPSL.Electrical.Controls.PSAT.OEL.FieldCurrent (xd = Z_MBtoSB*xd, xq = Z_MBtoSB*xq)
#   currentLimit    Modelica.Blocks.Sources.Constant (k = if_lim)
#   add             Modelica.Blocks.Math.Feedback                       field_current.ifield - currentLimit.y
#   limIntegrator   Modelica.Blocks.Continuous.LimIntegrator (k = 1/T0, outMax = vOEL_max, outMin = 0, strict = true)
#   difference      Modelica.Blocks.Math.Feedback                       v_ref0 - limIntegrator.y -> v_ref
# `outer SysData` is the keyword argument S_b (batch-0 decision); the .mo's defaults `Sn = SysData.S_b` (sic: a power
# rating defaulting to the system base) and `Vn = V_b` are kept. `Z_MBtoSB` is Julia arithmetic and reaches
# `field_current` as a number (F-22, point 2). `I_MBtoSB` is declared and never used in the .mo: omitted.
# `strict = true` changes nothing in LimIntegrator.jl (the `ifelse` generates no event; header of batch 1).
# The RealInput/RealOutput ports v, p, q, v_ref0, v_ref are plain variables. Omitted: graphical annotations.

@component function OEL(; name, S_b = 100e6, T0 = 10, xd, xq, if_lim, vOEL_max, Sn = S_b, V_b = 400e3, Vn = V_b)
    S_b, T0, xd, xq, if_lim, vOEL_max, Sn, V_b, Vn =
        float.((S_b, T0, xd, xq, if_lim, vOEL_max, Sn, V_b, Vn))   # F-21
    Z_MBtoSB = (S_b * Vn^2) / (Sn * V_b^2)
    pars = @parameters begin
        S_b = S_b, [description = "System base power (VA)"]
        T0 = T0, [description = "Integrator time constant (s)"]
        xd = xd, [description = "d-axis estimated generator reactance (machine base, pu)"]
        xq = xq, [description = "q-axis estimated generator reactance (machine base, pu)"]
        if_lim = if_lim, [description = "Maximum field current (system base, pu)"]
        vOEL_max = vOEL_max, [description = "Maximum output signal (machine base, pu)"]
        Sn = Sn, [description = "Power rating (VA)"]
        Vn = Vn, [description = "Voltage rating (V)"]
        V_b = V_b, [description = "Base voltage of the bus (V)"]
        Z_MBtoSB = Z_MBtoSB, [description = "Z(machine base) -> Z(system base)"]
    end
    systems = @named begin
        field_current = FieldCurrent(; xd = Z_MBtoSB * xd, xq = Z_MBtoSB * xq)
        currentLimit = Constant(; k = if_lim)
        add = Feedback()
        limIntegrator = LimIntegrator(; k = 1 / T0, outMax = vOEL_max, outMin = 0.0, strict = true,
            initType = :InitialState, y_start = 0.0)
        difference = Feedback()
    end
    vars = @variables begin
        v(t), [description = "Generator terminal voltage (pu)"]
        p(t), [description = "Active power (pu)"]
        q(t), [description = "Reactive power (pu)"]
        v_ref0(t), [description = "Generator terminal voltage (pu)"]
        v_ref(t), [description = "Reference generator terminal voltage (pu)"]
    end
    eqs = Equation[
        add.u1 ~ field_current.ifield,     # connect(field_current.ifield, add.u1)
        add.u2 ~ currentLimit.y,           # connect(currentLimit.y, add.u2)
        v_ref ~ difference.y,              # connect(v_ref, difference.y)
        field_current.v ~ v,               # connect(field_current.v, v)
        difference.u2 ~ limIntegrator.y,   # connect(limIntegrator.y, difference.u2)
        difference.u1 ~ v_ref0,            # connect(difference.u1, v_ref0)
        field_current.p ~ p,               # connect(p, field_current.p)
        field_current.q ~ q,               # connect(q, field_current.q)
        limIntegrator.u ~ add.y,           # connect(add.y, limIntegrator.u)
    ]
    System(eqs, t, vars, pars; name, systems, guesses = Dict(v => 1.0, p => 0.0, q => 0.0, v_ref0 => 1.0, v_ref => 1.0))
end
