# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Continuous.mo, block Integrator
# Ports are plain variables (u, y; SISO). `initType` is a Symbol (:NoInit, :SteadyState, :InitialState, :InitialOutput)
# with MSL's initial equations. Omitted: the optional reset/set ports (use_reset = false everywhere in OpenIPSL),
# graphical annotations.
# A fixed start value is the initial equation `state = y_start` plus a guess, not an `initial_conditions` entry: an
# entry whose value depends on a `missing` parameter (an exciter's Efd0, F-33) is dropped by ModelingToolkit at
# problem construction, whereas the equation is solved with it (F-38).

@component function Integrator(; name, k = 1, initType = :InitialState, y_start = 0)
    pars = @parameters begin
        k = k, [description = "Integrator gain"]
        y_start = y_start, [description = "Initial or guess value of output (= state)"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    fixed = initType in (:InitialState, :InitialOutput)
    System(Equation[der(y) ~ k * u], t, vars, pars; name, guesses = Dict(y => y_start),
        initialization_eqs = initType == :SteadyState ? [der(y) ~ 0] : fixed ? [y ~ y_start] : Equation[])
end
