# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/SimpleLag.mo (block)
# Blocks: const = Modelica.Blocks.Sources.RealExpression(y = T) (instance `const_`: `const` is a Julia keyword).
# Ports are plain variables (u, y; SISO). `initial equation state = y_start` is an initialization equation with the
# start as a guess (F-38: y_start may depend on a `missing` parameter of the parent).
# Omitted: graphical annotations.

# The `if` on the block's own time constant is a *parameter* expression: Modelica evaluates it at translation
# time and keeps one branch, so it is decided in Julia before `@parameters` (F-22, point 1). Written as an
# `ifelse` it survives into the compiled system, the output stops being an alias of the state, and a downstream
# block that differentiates its input (`SimpleLead` in `HYGOV`) drags ModelingToolkit's index reduction into a
# cascade of dummy derivatives that blows up (F-50). The `const`/`par1` sub-block stays: the OpenModelica CSVs
# carry its `y` column.
@component function SimpleLag(; name, K, T, y_start)
    K, T, y_start = float.((K, T, y_start))
    T_mod = T < Modelica.Constants.eps ? 1000.0 : T
    Tn = T   # numeric copy for the RealExpression: after @parameters `T` is the symbol (F-22)
    pars = @parameters begin
        K = K, [description = "Gain"]
        T = T, [description = "Lag time constant (s)"]
        y_start = y_start, [description = "Output start value"]
        T_mod = T_mod
    end
    systems = @named begin
        const_ = RealExpression(; expr = Tn)
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [guess = y_start, description = "Connector of Real output signal"]
        state(t)
    end
    eqs = Equation[
        T_mod * der(state) ~ K * u - state,
        y ~ (abs(Tn) <= Modelica.Constants.eps ? u * K : state),
    ]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = [state ~ y_start], guesses = Dict(state => y_start))
end
