# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Continuous.mo, block LimIntegrator
# Ports are plain variables (u, y; SISO). `initType` as in Integrator.jl. `limitsAtInit = true` always (OpenIPSL never
# sets it) and `strict` has no effect (`ifelse` generates no event); the `initial()` branch is not reproduced.
# Omitted: the optional reset/set ports, the assert, graphical annotations.
# A fixed start value is the initial equation `state = y_start` plus a guess, not an `initial_conditions` entry: an
# entry whose value depends on a `missing` parameter (an exciter's Efd0, F-33) is dropped by ModelingToolkit at
# problem construction, whereas the equation is solved with it (F-38).

@component function LimIntegrator(; name, k = 1, outMax, outMin = -outMax, initType = :InitialState, limitsAtInit = true,
        y_start = 0, strict = false)
    pars = @parameters begin
        k = k, [description = "Integrator gain"]
        outMax = outMax, [description = "Upper limit of output"]
        outMin = outMin, [description = "Lower limit of output"]
        y_start = y_start, [description = "Initial or guess value of output (must be in the limits outMin .. outMax)"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    # der(y) = if y < outMin and k*u < 0 or y > outMax and k*u > 0 then 0 else k*u
    eqs = Equation[der(y) ~ ifelse(((y < outMin) & (k * u < 0)) | ((y > outMax) & (k * u > 0)), 0, k * u)]
    fixed = initType in (:InitialState, :InitialOutput)
    System(eqs, t, vars, pars; name, guesses = Dict(y => y_start),
        initialization_eqs = initType == :SteadyState ? [der(y) ~ 0] : fixed ? [y ~ y_start] : Equation[])
end
