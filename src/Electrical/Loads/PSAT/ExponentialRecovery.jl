# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSAT/ExponentialRecovery.mo (extends BaseClasses/baseLoad.mo)
# Blocks: none. The protected states xp, xq have `start = 0` and no initial equation: guesses (F-20). OpenIPSL's
# LoadTestExpRecovery is then under-determined and OpenModelica fixes e1q and xp at their start values, leaving xq
# free (F-28): the Test adds those initial conditions. Omitted: graphical annotations.

@component function ExponentialRecovery(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        Sn = S_b, Tp = 1, Tq = 1, alpha_s = 2, alpha_t = 1.5, beta_s = 2, beta_t = 1.5)
    Tp, Tq, alpha_s, alpha_t, beta_s, beta_t = float.((Tp, Tq, alpha_s, alpha_t, beta_s, beta_t))
    @named base = baseLoad(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn)
    @unpack v, P, Q, S_b, P_0, Q_0, v_0 = base
    pars = @parameters begin
        Tp = Tp, [description = "Active power time constant (s)"]
        Tq = Tq, [description = "Reactive power time constant (s)"]
        alpha_s = alpha_s, [description = "Static active power exponent"]
        alpha_t = alpha_t, [description = "Dynamic active power exponent"]
        beta_s = beta_s, [description = "Static reactive power exponent"]
        beta_t = beta_t, [description = "Dynamic reactive power exponent"]
    end
    vars = @variables begin
        ps(t), [description = "Static real power absorption (pu)"]
        pt(t), [description = "Transient real power absorption (pu)"]
        qs(t), [description = "Static imaginary power absorption (pu)"]
        qt(t), [description = "Transient imaginary power absorption (pu)"]
        xp(t)
        xq(t)
    end
    eqs = Equation[
        der(xp) ~ (-xp / Tp) + ps - pt,
        P ~ xp / Tp + pt,
        ps ~ P_0 / S_b * (v / v_0)^alpha_s,
        pt ~ P_0 / S_b * (v / v_0)^alpha_t,
        der(xq) ~ (-xq / Tq) + qs - qt,
        Q ~ xq / Tq + qt,
        qs ~ Q_0 / S_b * (v / v_0)^beta_s,
        qt ~ Q_0 / S_b * (v / v_0)^beta_t,
    ]
    extend(System(eqs, t, vars, pars; name, guesses = Dict(xp => 0.0, xq => 0.0)), base)
end
