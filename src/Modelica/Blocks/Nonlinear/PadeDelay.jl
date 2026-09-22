# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Nonlinear.mo, block PadeDelay
# Rational (Pade) approximation of `delay(u, delayTime)`: a state-space block, hence an ODE. Ports are plain
# variables (u, y; SISO) plus the `output Real x[n]` of the .mo.
# `padeCoefficients2` is transcribed literally (the recursion for a[i], b[i], the reversals, `bb`, `d`) and evaluated
# in Julia before `@parameters`, because in the .mo it is an `initial equation` over `fixed = false` parameters that
# depends only on parameters (F-33: such a parameter is plain Julia arithmetic).
# Deviation, declared here: `Modelica.Math.Matrices.balanceABC` is NOT ported, so the state-space is always the
# textbook controller canonical form (`s = ones(n-1)`) and `balance` selects only the initialization branch of the
# .mo - `true`: `der(x) = 0`, i.e. the steady state for the input *value* at t0, so `y(t0) = u(t0)` and a signal that
# is not constant at t0 starts with a short transient (a ramp is reproduced to 3e-7 after 0.7 s and exactly after
# 2 s, `test_Modelica_Blocks_Nonlinear.jl`); `false`: `x[n] = u` (MSL's backwards-compatible branch). Against a
# balanced realization the input/output behaviour is the same in exact arithmetic and the states differ by a
# diagonal transform; no OpenModelica oracle of this port contains them.
# Why it exists at all: `Turbine.mo` instantiates it conditionally and nothing selects it, but ModelingToolkit 11.43
# cannot integrate a delay-differential system that also has events (F-51), and every OpenIPSL model with a real
# transport delay sits on a network that has them. `FixedDelay(; pade = n)` builds this block instead of the
# transport delay for exactly that case.
# Omitted: the `m` numerator order other than the default (`m = n`) is supported, graphical annotations.

@component function PadeDelay(; name, delayTime = 1, n = 1, m = n, balance = false)
    delayTime = float(delayTime)
    n >= 1 || error("PadeDelay: n must be >= 1")
    1 <= m <= n || error("PadeDelay: m must be in 1:n")
    # padeCoefficients2(T, n, m, balance = false), literal
    a = ones(n + 1)
    b = ones(m + 1)
    nm = n + m
    for i in 1:n
        a[i + 1] = a[i] * (delayTime * ((n - i + 1) / (nm - i + 1)) / i)
        if i <= m
            b[i + 1] = -b[i] * (delayTime * ((m - i + 1) / (nm - i + 1)) / i)
        end
    end
    b = reverse(b)
    a = reverse(a)
    bb = [zeros(n - m); b]
    d = bb[1] / a[1]
    s = ones(n - 1)
    a1 = -a[2:(n + 1)] / a[1]
    b11 = 1 / a[1]
    c = bb[2:(n + 1)] - d * a[2:(n + 1)]
    pars = @parameters begin
        delayTime = delayTime, [description = "Delay time of output with respect to input signal (s)"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
        (x(t))[1:n], [description = "State of transfer function from controller canonical form"]
    end
    eqs = Equation[
        der(x[1]) ~ sum(a1[i] * x[i] for i in 1:n) + b11 * u,
        [der(x[i + 1]) ~ s[i] * x[i] for i in 1:(n - 1)]...,
        y ~ sum(c[i] * x[i] for i in 1:n) + d * u,
    ]
    ieqs = balance ? [der(x[i]) ~ 0 for i in 1:n] : Equation[x[n] ~ u]
    System(eqs, t, [u, y, x], pars; name, initialization_eqs = ieqs, guesses = Dict(x => zeros(n)))
end
