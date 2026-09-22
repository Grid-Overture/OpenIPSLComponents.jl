# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/SimpleLagLimVar.mo (block)
# Blocks: const = RealExpression(y = T) (instance `const_`). Ports are plain variables (u, y, outMax, outMin).
# The .mo's `when abs(y - outMax) <= eps and K*u - y < 0 or abs(y - outMin) <= eps and K*u - y > 0 then
# reinit(state, y)` is NOT reproduced: OpenModelica 1.25 never executes it (its condition compares a difference that
# is exactly zero against eps = 1e-15, below OM's relation hysteresis), so the state winds up beyond the limits
# while the output stays clamped - verified on the ESDC2A, URST5T, ST5B and DC4B oracles, F-40. The block is a lag
# `T der(state) = K*u - y` with a clamped output and no anti-windup reset, as OM simulates it.
# `initial equation state = y_start` as in SimpleLag.jl (F-38). Omitted: graphical annotations.

# The `if` on the block's own time constant is a *parameter* expression: Modelica evaluates it at translation
# time and keeps one branch, so it is decided in Julia before `@parameters` (F-22, point 1). Written as an
# `ifelse` it survives into the compiled system, the output stops being an alias of the state, and a downstream
# block that differentiates its input (`SimpleLead` in `HYGOV`) drags ModelingToolkit's index reduction into a
# cascade of dummy derivatives that blows up (F-50). The `const`/`par1` sub-block stays: the OpenModelica CSVs
# carry its `y` column.
@component function SimpleLagLimVar(; name, K, T, y_start)
    K, T, y_start = float.((K, T, y_start))
    T_mod = T < Modelica.Constants.eps ? 1000.0 : T
    Tn = T   # numeric copy for the RealExpression (F-22)
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
        outMax(t)
        outMin(t)
        state(t)
    end
    eqs = Equation[
        T_mod * der(state) ~ K * u - y,
        y ~ (abs(Tn) <= Modelica.Constants.eps ? max(min(u * K, outMax), outMin) : max(min(state, outMax), outMin)),
    ]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = [state ~ y_start], guesses = Dict(state => y_start))
end
