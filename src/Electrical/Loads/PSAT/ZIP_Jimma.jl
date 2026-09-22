# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSAT/ZIP_Jimma.mo (extends BaseClasses/baseLoad.mo)
# Blocks: none. Pp and Qp default to 1 - Pz - Pi and 1 - Qz - Qi as in the .mo. The protected state x has `start = 0`
# and `initial equation der(x) = 0` (initialization_eqs, x = 0 as its guess). Omitted: graphical annotations.

@component function ZIP_Jimma(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0, Sn = S_b,
        Tf = 0.01, Pz = 0.33, Pi = 0.33, Pp = 1 - Pz - Pi, Qz = 0.33, Qi = 0.33, Qp = 1 - Qz - Qi, Kv = 100)
    Tf, Pz, Pi, Pp, Qz, Qi, Qp, Kv = float.((Tf, Pz, Pi, Pp, Qz, Qi, Qp, Kv))
    @named base = baseLoad(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn)
    @unpack v, P, Q, S_b, P_0, Q_0, v_0 = base
    pars = @parameters begin
        Tf = Tf, [description = "Time constant of the high-pass filter (s)"]
        Pz = Pz, [description = "Conductance (pu)"]
        Pi = Pi, [description = "Active current (pu)"]
        Pp = Pp, [description = "Active power (pu)"]
        Qz = Qz, [description = "Susceptance (pu)"]
        Qi = Qi, [description = "Reactive current (pu)"]
        Qp = Qp, [description = "Reactive power (pu)"]
        Kv = Kv, [description = "Coefficient of the voltage time derivative (1/s)"]
    end
    vars = @variables begin
        a(t), [description = "Auxiliary variable, voltage division"]
        b(t), [description = "Auxiliary variable, derivation"]
        x(t)
    end
    eqs = Equation[
        a ~ v / v_0,
        der(x) ~ ((-v / Tf) - x) / Tf,
        b ~ x + v / Tf,
        P ~ P_0 / S_b * (Pz * a^2 + Pi * a + Pp),
        Q ~ Q_0 / S_b * (Qz * a^2 + Qi * a + Qp + Kv * b),
    ]
    extend(System(eqs, t, vars, pars; name, guesses = Dict(x => 0.0), initialization_eqs = [der(x) ~ 0]), base)
end
