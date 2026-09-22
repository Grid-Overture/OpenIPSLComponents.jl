# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/General/ElmPhi_pll.mo: a phase-locked loop.
# One PwPin `p` and two RealOutputs (sinphi, cosphi) as plain variables. Omitted: graphical annotations.
# `PLLEnable` defaults to false and the .mo says the loop is not implemented yet, so the three initial-value
# parameters `angle_0rad`, `omega_0` and `v_0` are declared and reach nothing (sic, rule 5). What the model
# computes is the unit phasor of the bus voltage, and it draws no current.

@component function ElmPhi_pll(; name, angle_0rad, omega_0, v_0, PLLEnable = false)
    angle_0rad, omega_0, v_0 = float.((angle_0rad, omega_0, v_0))
    pars = @parameters begin
        angle_0rad = angle_0rad
        omega_0 = omega_0
        v_0 = v_0
        PLLEnable = PLLEnable, [description = "Enable/disable PLL (PLL not implemented yet)"]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        v(t), [guess = v_0]
        sinphi(t)
        cosphi(t)
    end
    eqs = Equation[
        v ~ sqrt(p.vr^2 + p.vi^2),
        sinphi ~ p.vi / v,
        cosphi ~ p.vr / v,
        p.ii ~ 0,
        p.ir ~ 0,
    ]
    System(eqs, t, vars, pars; name, systems)
end
