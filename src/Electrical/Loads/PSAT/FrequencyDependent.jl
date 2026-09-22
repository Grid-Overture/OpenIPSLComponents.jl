# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSAT/FrequencyDependent.mo (extends BaseClasses/baseLoad.mo)
# Blocks: none. The protected state x has `start = 0` and `initial equation der(x) = 0` (initialization_eqs, x = 0 as
# its guess). Omitted: graphical annotations.

@component function FrequencyDependent(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        Sn = S_b, alpha_p = 0, alpha_q = 0, beta_p = 1.3, beta_q = 1.3, Tf = 0.1)
    alpha_p, alpha_q, beta_p, beta_q, Tf = float.((alpha_p, alpha_q, beta_p, beta_q, Tf))
    @named base = baseLoad(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn)
    @unpack v, anglev, P, Q, S_b, fn, P_0, Q_0, v_0, angle_0 = base
    pars = @parameters begin
        alpha_p = alpha_p, [description = "Active power voltage coefficient"]
        alpha_q = alpha_q, [description = "Reactive power voltage coefficient"]
        beta_p = beta_p, [description = "Active power frequency coefficient"]
        beta_q = beta_q, [description = "Reactive power frequency coefficient"]
        Tf = Tf, [description = "Filter time constant (s)"]
    end
    vars = @variables begin
        deltaw(t), [description = "Frequency deviation (pu)"]
        a(t), [description = "Auxiliary variable, voltage division"]
        x(t), [description = "Auxiliary variable"]
    end
    eqs = Equation[
        a ~ v / v_0,
        der(x) ~ -deltaw / Tf,
        0 ~ x + 1 / (2 * pi * fn) * 1 / Tf * (anglev - angle_0) - deltaw,
        P ~ P_0 / S_b * a^alpha_p * (1 + deltaw)^beta_p,
        Q ~ Q_0 / S_b * a^alpha_q * (1 + deltaw)^beta_q,
    ]
    extend(System(eqs, t, vars, pars; name, guesses = Dict(x => 0.0), initialization_eqs = [der(x) ~ 0]), base)
end
