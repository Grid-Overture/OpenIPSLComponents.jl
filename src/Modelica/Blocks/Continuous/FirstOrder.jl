# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Continuous.mo, block FirstOrder
# Ports are plain variables (u, y; SISO). `initType` as in Integrator.jl (a fixed start value is an initialization
# equation plus a guess, F-38). Omitted: graphical annotations.

@component function FirstOrder(; name, k = 1, T, initType = :NoInit, y_start = 0)
    pars = @parameters begin
        k = k, [description = "Gain"]
        T = T, [description = "Time constant (s)"]
        y_start = y_start, [description = "Initial or guess value of output (= state)"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    fixed = initType in (:InitialState, :InitialOutput)
    System(Equation[der(y) ~ (k * u - y) / T], t, vars, pars; name, guesses = Dict(y => y_start),
        initialization_eqs = initType == :SteadyState ? [der(y) ~ 0] : fixed ? [y ~ y_start] : Equation[])
end
