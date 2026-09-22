# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Sources.mo, block BooleanStep
# Ports are plain variables (y (partialBooleanSource)). `y = if time >= startTime then not startValue else
# startValue`. Omitted: graphical annotations.

# Boolean signals are Real 0/1 in this port (PLAN-01), and `time >= startTime` is a time event in Modelica: the
# form is `Step`'s (F-25) -- the discrete `on` is switched by a discrete event at `startTime` with a DAE
# re-initialization, never by a bare `ifelse` on `t`. A `startTime` outside the horizon (`ANGLE_CTRL`'s 45 s over a
# 10 s run) leaves the `tstop` beyond `tspan` and no event fires; a `startTime <= 0` is post-step from the start.
@component function BooleanStep(; name, startTime = 0, startValue = false)
    startTime = float(startTime)
    v0 = startValue ? 1.0 : 0.0
    on0 = startTime <= 0 ? 1 : 0
    pars = @parameters begin
        startTime = startTime, [description = "Time instant of step start (s)"]
        startValue = v0, [description = "Output before startTime (0/1)"]
    end
    disc = @discretes begin
        on(t) = on0
    end
    vars = @variables begin
        y(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    kw = on0 == 1 ? (;) : (;
        discrete_events = [SymbolicDiscreteCallback(t == startTime,
            ImperativeAffect((m, o, ctx, integ) -> (; on = 1); modified = (; on));
            reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())],
        tstops = [[startTime]])
    System(Equation[y ~ ifelse(on > 0.5, 1 - startValue, startValue)], t, vars, [pars; disc]; name, kw...)
end
