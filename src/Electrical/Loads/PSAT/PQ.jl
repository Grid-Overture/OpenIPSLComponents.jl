# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSAT/PQ.mo (extends BaseClasses/baseLoad.mo)
# Blocks: none. Omitted: graphical annotations.
# `if forcePQ or initial() then` : forcePQ is a structural Boolean parameter, chosen at construction. With forcePQ =
# false the `initial()` branch (constant P, Q during initialization only) is not reproduced: P and Q follow the
# voltage branches from t = 0, which is the same unless v(0) lies outside [Vmin, Vmax].

@component function PQ(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0, Sn = S_b,
        Vmax = 1.2, Vmin = 0.8, forcePQ = true)
    @named base = baseLoad(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn)
    @unpack v, P, Q = base
    pars = @parameters begin
        Vmax = Vmax, [description = "Maximum voltage (pu)"]
        Vmin = Vmin, [description = "Minimum voltage (pu)"]
    end
    eqs = forcePQ ? Equation[
        P ~ P_0 / S_b,
        Q ~ Q_0 / S_b,
    ] : Equation[
        P ~ ifelse(v > Vmax, P_0 * v^2 / (Vmax^2) / S_b, ifelse(v < Vmin, P_0 * v^2 / Vmin^2 / S_b, P_0 / S_b)),
        Q ~ ifelse(v > Vmax, Q_0 * v^2 / (Vmax^2) / S_b, ifelse(v < Vmin, Q_0 * v^2 / (Vmin^2) / S_b, Q_0 / S_b)),
    ]
    extend(System(eqs, t, [], pars; name), base)
end
