# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSAT/Mixed.mo (extends BaseClasses/baseLoad.mo)
# Blocks: none. The protected states x (`start = -v_0/Tfv`) and y (`start = 0`) have no initial equation: guesses
# (F-20). OpenIPSL's LoadTestMixed is then under-determined and OpenModelica fixes e1q and x at their start values,
# leaving y free (F-28): the Test adds those initial conditions. Omitted: graphical annotations.

@component function Mixed(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0, Sn = S_b,
        Kpf = 0, alpha = 0, Tpv = 0.12, Kqf = 0, beta = 0, Tqv = 0.075, Tfv = 0.005, Tft = 0.007)
    Kpf, alpha, Tpv, Kqf, beta, Tqv, Tfv, Tft, v_0n = float.((Kpf, alpha, Tpv, Kqf, beta, Tqv, Tfv, Tft, v_0))
    x0 = -v_0n / Tfv
    @named base = baseLoad(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn)
    @unpack v, anglev, P, Q, S_b, fn, P_0, Q_0, v_0, angle_0 = base
    pars = @parameters begin
        Kpf = Kpf, [description = "Frequency coefficient for the active power (pu)"]
        alpha = alpha, [description = "Voltage exponent for the active power"]
        Tpv = Tpv, [description = "Time constant of dV/dt for the active power (s)"]
        Kqf = Kqf, [description = "Frequency coefficient for the reactive power (pu)"]
        beta = beta, [description = "Voltage exponent for the reactive power"]
        Tqv = Tqv, [description = "Time constant of dV/dt for the reactive power (s)"]
        Tfv = Tfv, [description = "Time constant of voltage magnitude filter (s)"]
        Tft = Tft, [description = "Time constant of voltage angle filter (s)"]
    end
    vars = @variables begin
        deltaw(t), [description = "Frequency deviation (pu)"]
        a(t), [description = "Auxiliary variable, voltage division"]
        b(t), [description = "Auxiliary variable, derivation"]
        x(t)
        y(t)
    end
    eqs = Equation[
        a ~ v / v_0,
        der(x) ~ ((-v / Tfv) - x) / Tfv,
        b ~ x + v / Tfv,
        der(y) ~ -1 / Tft * (1 / (2 * pi * fn * Tft) * (anglev - angle_0) + y),
        deltaw ~ y + 1 / (2 * pi * fn * Tft) * (anglev - angle_0),
        P ~ Kpf * deltaw + P_0 / S_b * (a^alpha + Tpv * b),
        Q ~ Kqf * deltaw + Q_0 / S_b * (a^beta + Tqv * b),
    ]
    extend(System(eqs, t, vars, pars; name, guesses = Dict(x => x0, y => 0.0)), base)
end
