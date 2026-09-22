# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/SimpleLagLim.mo (block)
# Blocks: const = RealExpression(y = T) (instance `const_`). Ports are plain variables (u, y; SISO).
# `when state > outMax and K*u - state < 0 then reinit(state, outMax); elsewhen state < outMin and K*u - state > 0
# then reinit(state, outMin)` is one continuous event on K*u - state with imperative, self-limiting affects
# (F-14, F-15), **guarded by the `when`'s own conjunction**: the root function is `K*u - state` only while the state
# is outside [outMin, outMax], and the constant 1 while it is inside, where the `when` cannot fire and the affect is
# a no-op anyway. Without the guard the root function is identically zero at any equilibrium (`K*u = state` is the
# steady state of the block), and a step of the input at a tstop makes the callback re-fire at that instant without
# advancing time (F-55; foreseen in F-22, point 4). A jump of K*u - state at a discrete event elsewhere (a fault switching at a tstop) is invisible to
# that callback, which only sees sign changes inside a step, while OpenModelica re-evaluates the `when` in the same
# event iteration and resets the state: a discrete callback on the literal `when` conditions, evaluated at the end
# of every step, applies that reset one step later (F-41). `initial equation state = y_start` as in SimpleLag.jl
# (F-38). Omitted: graphical annotations.

# The `if` on the block's own time constant is a *parameter* expression: Modelica evaluates it at translation
# time and keeps one branch, so it is decided in Julia before `@parameters` (F-22, point 1). Written as an
# `ifelse` it survives into the compiled system, the output stops being an alias of the state, and a downstream
# block that differentiates its input (`SimpleLead` in `HYGOV`) drags ModelingToolkit's index reduction into a
# cascade of dummy derivatives that blows up (F-50). The `const`/`par1` sub-block stays: the OpenModelica CSVs
# carry its `y` column.
@component function SimpleLagLim(; name, K, T, y_start, outMax, outMin)
    K, T, y_start, outMax, outMin = float.((K, T, y_start, outMax, outMin))
    T_mod = T < Modelica.Constants.eps ? 1000.0 : T
    Tn = T   # numeric copy for the RealExpression (F-22)
    pars = @parameters begin
        K = K, [description = "Gain"]
        T = T, [description = "Lag time constant (s)"]
        y_start = y_start, [description = "Output start value"]
        outMax = outMax, [description = "Maximum output value"]
        outMin = outMin, [description = "Minimum output value"]
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
        y ~ (abs(Tn) <= Modelica.Constants.eps ? max(min(u * K, outMax), outMin) : max(min(state, outMax), outMin)),
    ]
    reinit_min = ImperativeAffect((m, o, ctx, integ) -> (; state = max(m.state, o.outMin)); modified = (; state), observed = (; outMin))
    reinit_max = ImperativeAffect((m, o, ctx, integ) -> (; state = min(m.state, o.outMax)); modified = (; state), observed = (; outMax))
    ev = SymbolicContinuousCallback([ifelse((state > outMax) | (state < outMin), K * u - state, 1.0) ~ 0],
        reinit_min; affect_neg = reinit_max, reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    after_event = SymbolicDiscreteCallback(((state > outMax) & (K * u - state < 0)) | ((state < outMin) & (K * u - state > 0)),
        ImperativeAffect((m, o, ctx, integ) -> (; state = max(min(m.state, o.outMax), o.outMin)); modified = (; state),
            observed = (; outMax, outMin)); reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    System(eqs, t, vars, pars; name, systems, initialization_eqs = [state ~ y_start], guesses = Dict(state => y_start),
        continuous_events = [ev], discrete_events = [after_event])
end
