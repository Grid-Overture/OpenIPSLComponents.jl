# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/IntegratorLimVar.mo (block)
# Ports are plain variables (u, y, outMax, outMin). The `algorithm` flags are algebraic 0/1 signals: Rising = u > eps,
# Falling = u < -eps, ReachUpper = w > outMax, ReachLower = w < outMin; the `when Reinit then reinit(w, initVar)` is
# two continuous events, on u (its sign) and on w - outMax / w - outMin, whose affect sets w := outMax when the state
# is above the upper limit while the input falls (w := outMin below the lower limit while it rises), i.e. the edge of
# `ReachUpper and Falling` / `ReachLower and Rising`. OpenIPSL's Boolean `Reinit` never returns to false in the
# algorithm; whether OpenModelica reinitializes at later edges is settled by the Test of the first model that uses
# this block (F-##). `initial equation` clamps w to [outMin, outMax] at y_start. Omitted: the assert, annotations.
# Batch 8 (F-76): a sign change of `u` produced *inside another component's event* (the clearing of a fault that
# lifts the terminal voltage of WT4E1's plant) is invisible to the continuous event, and the state stayed above
# `outMax` with the output pinned at the limit for the rest of the run, while OpenModelica re-evaluates the `when`
# in the same event iteration (F-41). As `SimpleLagLim`, the block also carries a discrete callback on the literal
# `ReachUpper and Falling` / `ReachLower and Rising`, evaluated at the end of every step, that applies the reset one
# step later when the continuous callback could not see the edge.

@component function IntegratorLimVar(; name, K, y_start)
    K, y_start = float.((K, y_start))
    pars = @parameters begin
        K = K, [description = "Gain"]
        y_start = y_start, [description = "Output start value"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [guess = y_start, description = "Connector of Real output signal"]
        outMax(t)
        outMin(t)
        x(t), [description = "Dummy variable for input"]
        w(t), [description = "Dummy variable for output"]
        ReachUpper(t)
        ReachLower(t)
        Rising(t)
        Falling(t)
    end
    eps = Modelica.Constants.eps
    eqs = Equation[
        Rising ~ ifelse(u > eps, 1, 0),
        Falling ~ ifelse(u < -eps, 1, 0),
        ReachUpper ~ ifelse(w > outMax, 1, 0),
        ReachLower ~ ifelse((w <= outMax) & (w < outMin), 1, 0),
        x ~ ifelse(ReachUpper > 0.5, 0, ifelse(ReachLower > 0.5, 0, u)),
        y ~ ifelse(ReachUpper > 0.5, outMax, ifelse(ReachLower > 0.5, outMin, w)),
        der(w) ~ K * x,
    ]
    # `ReachUpper and Falling` can only become true when u turns negative while w is above outMax (w cannot cross
    # outMax upwards with u < 0), and `ReachLower and Rising` when u turns positive while w is below outMin: one
    # continuous event on u with direction-aware affects; an event on w - outMax/outMin would chatter at the limit.
    to_upper = ImperativeAffect((m, o, ctx, integ) -> (; w = m.w > o.outMax ? o.outMax : m.w); modified = (; w), observed = (; outMax))
    to_lower = ImperativeAffect((m, o, ctx, integ) -> (; w = m.w < o.outMin ? o.outMin : m.w); modified = (; w), observed = (; outMin))
    evs = [SymbolicContinuousCallback([u ~ 0], to_lower; affect_neg = to_upper, reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())]
    after_event = SymbolicDiscreteCallback(((w > outMax) & (u < -eps)) | ((w < outMin) & (u > eps)),
        ImperativeAffect((m, o, ctx, integ) -> (; w = max(min(m.w, o.outMax), o.outMin)); modified = (; w), observed = (; outMax, outMin));
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    # initial equation: w = outMax if y_start >= outMax, outMin if y_start <= outMin, else y_start
    System(eqs, t, vars, pars; name, continuous_events = evs, discrete_events = [after_event],
        initialization_eqs = [w ~ ifelse(y_start >= outMax, outMax, ifelse(y_start <= outMin, outMin, y_start))])
end
