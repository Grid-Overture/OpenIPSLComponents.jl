# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Continuous.mo, block TransferFunction
# Ports are plain variables (u, y; SISO). `b`, `a` are numeric Julia vectors (the .mo's parameter arrays); nx = na - 1
# states `x_scaled[1:nx]` and outputs `x[1:nx]` are MTK array variables; the controller canonical form is written with
# Julia loops over the indices. `initType` as in Integrator.jl (`x_start` fixed or guessed as a vector).
# A fixed start value is an initialization equation plus a guess (F-38). Omitted: the assert, graphical annotations.

@component function TransferFunction(; name, b = [1.0], a = [1.0], initType = :NoInit, x_start = zeros(length(a) - 1),
        y_start = 0)
    b, a = float.(b), float.(a)
    na, nb, nx = length(a), length(b), length(a) - 1
    bb = [zeros(max(0, na - nb)); b]
    d = bb[1] / a[1]
    a_end = a[end] > 100 * Modelica.Constants.eps * sqrt(sum(a .^ 2)) ? a[end] : 1.0
    pars = @parameters begin
        y_start = y_start, [description = "Initial value of output"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    if nx == 0
        return System(Equation[y ~ d * u], t, vars, pars; name)
    end
    @variables (x_scaled(t))[1:nx] [description = "Scaled vector x"]
    @variables (x(t))[1:nx] [description = "State of transfer function from controller canonical form"]
    eqs = Equation[
        der(x_scaled[1]) ~ (-sum(a[i] * x_scaled[i - 1] for i in 2:na) + a_end * u) / a[1],
        [der(x_scaled[i]) ~ x_scaled[i - 1] for i in 2:nx]...,
        y ~ sum((bb[i] - d * a[i]) * x_scaled[i - 1] for i in 2:na) / a_end + d * u,
        [x[i] ~ x_scaled[i] / a_end for i in 1:nx]...,
    ]
    ieqs = initType == :SteadyState ? [der(x_scaled[i]) ~ 0 for i in 1:nx] :
           initType == :InitialOutput ? [y ~ y_start; [der(x_scaled[i]) ~ 0 for i in 2:nx]] :
           initType == :InitialState ? [x_scaled[i] ~ x_start[i] * a_end for i in 1:nx] : Equation[]
    # the guess is keyed by the whole array (MTK's AtomicArrayDict rejects indexed elements), value x_start*a_end
    System(eqs, t, [vars; x_scaled; x], pars; name, guesses = Dict(x_scaled => x_start .* a_end), initialization_eqs = ieqs)
end
