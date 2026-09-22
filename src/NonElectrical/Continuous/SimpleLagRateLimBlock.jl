# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/SimpleLagRateLimBlock.mo (block)
# extends Modelica.Blocks.Interfaces.SISO(y(start = y_start)); ports are plain variables (u, y) plus the input
# `Block`. No sub-blocks. Omitted: graphical annotations.

# Three `if`s over *variables* and no `when`/`reinit` anywhere, so all three are `ifelse` (F-14, F-15 apply to a
# block that re-initializes its state; this one does not). `rate` selects which target the state chases, the
# derivative is the rate clamped to [rmin, rmax], and `Block > 0` freezes it. The output limiter is a plain
# saturation of the state; note that with `rate` already aiming at `outMax`/`outMin` the state approaches them
# asymptotically from inside and the clamp is only reachable from a `y_start` outside the limits (the branch is
# reproduced, not removed: rule 5). The two `assert`s of the .mo are parameter checks, done here on the numeric
# kwargs at construction. `initial equation y = y_start` is an initialization equation plus a guess (F-38); since
# `y` is the saturation of `x`, the guess goes on `x` as well.
@component function SimpleLagRateLimBlock(; name, K, T, y_start, outMax, outMin, rmin, rmax)
    K, T, y_start, outMax, outMin, rmin, rmax = float.((K, T, y_start, outMax, outMin, rmin, rmax))
    T >= 1e-10 || error("Time constant must be greater than 0")
    outMax > outMin || error("Upper limit must be greater than lower limit")
    pars = @parameters begin
        K = K, [description = "Gain"]
        T = T, [description = "Lag time constant (s)"]
        y_start = y_start, [description = "Output start value"]
        outMax = outMax, [description = "Maximum output value"]
        outMin = outMin, [description = "Minimum output value"]
        rmin = rmin, [description = "Minimum rate limit"]
        rmax = rmax, [description = "Maximum rate limit"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [guess = y_start, description = "Connector of Real output signal"]
        Block(t)
        x(t), [guess = y_start]
        rate(t)
    end
    eqs = Equation[
        rate ~ ifelse(u > outMax, (outMax - x) / T, ifelse(u < outMin, (outMin - x) / T, (u - x) / T)),
        der(x) ~ ifelse(Block > 0, 0, ifelse(rate > rmax, rmax, ifelse(rate < rmin, rmin, rate))),
        y ~ ifelse(x > outMax, outMax, ifelse(x < outMin, outMin, x)),
    ]
    System(eqs, t, vars, pars; name, initialization_eqs = [y ~ y_start], guesses = Dict(x => y_start, y => y_start))
end
