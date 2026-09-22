# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Continuous.mo, block Derivative
# Ports are plain variables (u, y; SISO). `initType` as in Integrator.jl; `zeroGain = abs(k) < eps` is decided at
# construction (a parameter in the .mo). A fixed start value is an initialization equation plus a guess (F-38).
# Omitted: graphical annotations.

@component function Derivative(; name, k = 1, T = 0.01, initType = :NoInit, x_start = 0, y_start = 0)
    zeroGain = abs(k) < Modelica.Constants.eps   # on the numeric kwarg, before @parameters rebinds `k`
    pars = @parameters begin
        k = k, [description = "Gains"]
        T = T, [description = "Time constants (s; T > 0 required)"]
        x_start = x_start, [description = "Initial or guess value of state"]
        y_start = y_start, [description = "Initial value of output (= state)"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
        x(t), [description = "State of block"]
    end
    eqs = Equation[
        der(x) ~ (zeroGain ? 0 : (u - x) / T),
        y ~ (zeroGain ? 0 : (k / T) * (u - x)),
    ]
    ieqs = initType == :SteadyState ? [der(x) ~ 0] :
           initType == :InitialOutput ? (zeroGain ? [x ~ u] : [y ~ y_start]) :
           initType == :InitialState ? [x ~ x_start] : Equation[]
    System(eqs, t, vars, pars; name, guesses = Dict(x => x_start), initialization_eqs = ieqs)
end
