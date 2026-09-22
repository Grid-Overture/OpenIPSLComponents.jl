# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Nonlinear.mo, block FixedDelay
# Ports are plain variables (u, y; SISO). `y = delay(u, delayTime)` is the transport delay: `u` is declared callable
# (`@variables u(..)`, F-20 d) and the equation is `y ~ u(t - delayTime)` with `delayTime` a symbolic parameter, so
# `mtkcompile` reports `is_dde = true` and the system is solved as a `DDEProblem` + `MethodOfSteps(Rodas5P())`.
# A system with a real delay has DelayDiffEq as a *test* dependency of the package only: `src/` declares nothing but
# `u(t - delayTime)` (F-20, rule 8 of the porting conventions).
# Numeric rule, decided before `@parameters` rebinds the name (F-22, point 1): `delayTime <= Modelica.Constants.eps`
# writes `y ~ u` instead, which is what `delay(u, 0)` means in MSL. It keeps the ODE character of the models whose
# delay is off - `GGOV1DU` (Teng = 0) and the `Teng = C.eps` default of `GGOV1`/`BaseClasses.GGOV1.Turbine`.
# Omitted: the `delay(u, delayTime, delayMax)` variable-delay form (OpenIPSL never uses it), graphical annotations.

# `pade` is a Julia-only keyword with no counterpart in the `.mo` (F-51): ModelingToolkit 11.43 generates the
# condition of every event with the DDE history argument in its signature, which SciMLBase's callback interface does
# not pass, so a system that has both a delay and an event aborts with a `BoundsError` at the first callback
# evaluation - and every OpenIPSL model with a real transport delay sits on a network with events (`PwFault`) or
# carries a limiter with one. `pade = n > 0` replaces the transport delay by `PadeDelay(delayTime, n, balance = true)`,
# an ODE with the same ports, so those Tests can run at all; the approximation error is measured against the
# OpenModelica oracle and recorded in the `F-##` of each user. `pade = 0` (the default) is the literal delay.
@component function FixedDelay(; name, delayTime = 1, pade = 0)
    delayTime = float(delayTime)
    pade > 0 && delayTime > Modelica.Constants.eps &&
        return PadeDelay(; name, delayTime, n = pade, balance = true)
    if delayTime <= Modelica.Constants.eps
        vars = @variables begin
            u(t), [description = "Connector of Real input signal"]
            y(t), [description = "Connector of Real output signal"]
        end
        return System(Equation[y ~ u], t, vars, []; name)
    end
    pars = @parameters begin
        delayTime = delayTime, [description = "Delay time of output with respect to input signal (s)"]
    end
    # `irreducible` is a Julia-only annotation with no counterpart in the `.mo`: without it on `u` the delayed call
    # refers to a variable `mtkcompile` has solved away, and without it on `y` the delay lands in an *observed*
    # equation; either way the problem raises `... is present in the system but ... is not an unknown` while the
    # initialization problem is built. With both, `y ~ u(t - delayTime)` stays an equation of the compiled system.
    @variables u(..) [irreducible = true, description = "Connector of Real input signal"]
    @variables y(t) [irreducible = true, guess = 0.0, description = "Connector of Real output signal"]
    # ModelingToolkit's generated history is the constant `u0`, i.e. MSL's `y = u(time.start)` for
    # `time <= time.start + delayTime`; the delayed equation cannot be evaluated by the initialization, which would
    # leave `y` undetermined, so the same relation at `t = t0` is its initialization equation.
    System(Equation[y ~ u(t - delayTime)], t, [u(t), y], pars; name, initialization_eqs = [y ~ u(t)])
end
