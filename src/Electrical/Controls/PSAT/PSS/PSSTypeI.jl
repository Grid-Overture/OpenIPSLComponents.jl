# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/PSS/PSSTypeI.mo, blocks as subsystems:
#   derivativeLag     OpenIPSL.NonElectrical.Continuous.DerivativeLag (T = Tw, y_start = 0, x_start = 0, K = Tw)
#   gainStabilizer    Modelica.Blocks.Math.Gain (k = Kw)
#   gainActivePower   Modelica.Blocks.Math.Gain (k = Kp)
#   gainVoltage       Modelica.Blocks.Math.Gain (k = Kv)
#   add3              Modelica.Blocks.Math.Add3
#   add               Modelica.Blocks.Math.Add
#   simpleLagLim      OpenIPSL.NonElectrical.Continuous.SimpleLagLim (K = 1, T = Tc, y_start = 0, outMax = vsmax,
#                                                                     outMin = vsmin)
# The RealInput/RealOutput ports w, Pg, Vg, vref0 and Vref are plain variables. None of the seven parameters has a
# default in the .mo, so all seven are required keyword arguments. Note that the output is `vref0 + vs`: unlike
# PSSTypeIII, this model sums the exciter's own reference in (its `add`).
# Omitted: graphical annotations.

@component function PSSTypeI(; name, Kw, Kp, Kv, vsmax, vsmin, Tw, Tc)
    Kw, Kp, Kv, vsmax, vsmin, Tw, Tc = float.((Kw, Kp, Kv, vsmax, vsmin, Tw, Tc))
    # the sub-blocks decide their degenerate branches in Julia from their numeric constants (F-50, F-22)
    n = (; Kw, Kp, Kv, vsmax, vsmin, Tw, Tc)
    pars = @parameters begin
        Kw = Kw, [description = "Stabilizer gain (pu/pu)"]
        Kp = Kp, [description = "Gain for active power"]
        Kv = Kv, [description = "Gain for bus voltage magnitude"]
        vsmax = vsmax, [description = "Max stabilizer output signal (pu)"]
        vsmin = vsmin, [description = "Min stabilizer output signal (pu)"]
        Tw = Tw, [description = "Wash-out time constant (s)"]
        Tc = Tc, [description = "Lag time constant (s)"]
    end
    systems = @named begin
        derivativeLag = DerivativeLag(; T = n.Tw, y_start = 0, x_start = 0, K = n.Tw)
        gainStabilizer = Gain(; k = n.Kw)
        gainActivePower = Gain(; k = n.Kp)
        gainVoltage = Gain(; k = n.Kv)
        add3 = Add3()
        add = Add()
        simpleLagLim = SimpleLagLim(; K = 1, T = n.Tc, y_start = 0, outMax = n.vsmax, outMin = n.vsmin)
    end
    vars = @variables begin
        w(t), [description = "Rotor speed"]
        Pg(t), [description = "Active power"]
        Vg(t), [description = "Voltage magnitude of the generator to which the PSS is connected through the AVR"]
        vref0(t)
        Vref(t), [description = "Indexes of the algebraic variable"]
    end
    eqs = Equation[
        gainVoltage.u ~ Vg,                 # connect(Vg, gainVoltage.u)
        gainActivePower.u ~ Pg,             # connect(Pg, gainActivePower.u)
        add3.u1 ~ gainStabilizer.y,         # connect(gainStabilizer.y, add3.u1)
        add3.u2 ~ gainActivePower.y,        # connect(gainActivePower.y, add3.u2)
        add3.u3 ~ gainVoltage.y,            # connect(gainVoltage.y, add3.u3)
        derivativeLag.u ~ add3.y,           # connect(add3.y, derivativeLag.u)
        simpleLagLim.u ~ derivativeLag.y,   # connect(derivativeLag.y, simpleLagLim.u)
        add.u2 ~ simpleLagLim.y,            # connect(simpleLagLim.y, add.u2)
        Vref ~ add.y,                       # connect(add.y, Vref)
        add.u1 ~ vref0,                     # connect(vref0, add.u1)
        gainStabilizer.u ~ w,               # connect(w, gainStabilizer.u)
    ]
    System(eqs, t, vars, pars; name, systems, guesses = Dict(w => 1.0, Vref => 1.0))
end
