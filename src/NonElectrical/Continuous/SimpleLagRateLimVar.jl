# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/SimpleLagRateLimVar.mo (block)
# extends Modelica.Blocks.Interfaces.SISO; ports are plain variables (u, y) plus the two limit inputs
# (outMin, outMax). No sub-blocks. Omitted: graphical annotations.

# The twin of `SimpleLagRateLimBlock` with the two output limits as signals and no `Block` input: same three
# `ifelse`s, no gain `K` (the .mo does not declare one). The `.mo` writes **two** initial equations,
# `x = y_start` and `y = y_start`, for one state; they are consistent whenever `y_start` is inside the limits,
# which is the only case OpenModelica accepts, and the second is redundant there because `y` is the saturation
# of `x`. Only `x = y_start` is kept as the initialization equation, with `y_start` as the guess for both
# (F-38); writing both would over-determine the initialization problem in ModelingToolkit as it does in Modelica.
# The `assert` on T is a parameter check, done on the numeric kwarg at construction.
@component function SimpleLagRateLimVar(; name, T, y_start, rmin, rmax)
    T, y_start, rmin, rmax = float.((T, y_start, rmin, rmax))
    T >= 1e-10 || error("Time constant must be greater than 0")
    pars = @parameters begin
        T = T, [description = "Lag time constant (s)"]
        y_start = y_start, [description = "Output start value"]
        rmin = rmin, [description = "Minimum rate limit"]
        rmax = rmax, [description = "Maximum rate limit"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [guess = y_start, description = "Connector of Real output signal"]
        outMin(t)
        outMax(t)
        x(t), [guess = y_start]
        rate(t), [description = "Rate"]
    end
    eqs = Equation[
        rate ~ ifelse(u > outMax, (outMax - x) / T, ifelse(u < outMin, (outMin - x) / T, (u - x) / T)),
        der(x) ~ ifelse(rate > rmax, rmax, ifelse(rate < rmin, rmin, rate)),
        y ~ ifelse(x > outMax, outMax, ifelse(x < outMin, outMin, x)),
    ]
    System(eqs, t, vars, pars; name, initialization_eqs = [x ~ y_start], guesses = Dict(x => y_start, y => y_start))
end
