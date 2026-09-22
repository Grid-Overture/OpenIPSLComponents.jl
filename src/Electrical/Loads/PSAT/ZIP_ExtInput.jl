# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSAT/ZIP_ExtInput.mo (extends BaseClasses/baseLoad.mo)
# Blocks: none. The twin of ZIP.jl with one RealInput `u` added to the active power. Note that `u` is summed into
# `P` after the division by `S_b`, so it is in per unit of the **system** base and not of the load's own `Sn` (sic).
# Pp and Qp default to 1 - Pz - Pi and 1 - Qz - Qi as in the .mo. Omitted: graphical annotations.

@component function ZIP_ExtInput(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0, Sn = S_b, Pz = 0.33, Pi = 0.33, Pp = 1 - Pz - Pi, Qz = 0.33, Qi = 0.33, Qp = 1 - Qz - Qi)
    Pz, Pi, Pp, Qz, Qi, Qp = float.((Pz, Pi, Pp, Qz, Qi, Qp))
    @named base = baseLoad(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn)
    @unpack v, P, Q, S_b, P_0, Q_0, v_0 = base
    pars = @parameters begin
        Pz = Pz, [description = "Conductance (pu)"]
        Pi = Pi, [description = "Active current (pu)"]
        Pp = Pp, [description = "Active power (pu)"]
        Qz = Qz, [description = "Susceptance (pu)"]
        Qi = Qi, [description = "Reactive current (pu)"]
        Qp = Qp, [description = "Reactive power (pu)"]
    end
    vars = @variables begin
        a(t), [description = "Auxiliary variable, voltage division"]
        u(t)
    end
    eqs = Equation[
        a ~ v / v_0,
        P ~ P_0 / S_b * (Pz * a^2 + Pi * a + Pp) + u,
        Q ~ Q_0 / S_b * (Qz * a^2 + Qi * a + Qp),
    ]
    extend(System(eqs, t, vars, pars; name), base)
end
