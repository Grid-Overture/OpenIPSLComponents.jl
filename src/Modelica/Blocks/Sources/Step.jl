# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Sources.mo, block Step
# Ports are plain variables (y (SignalSource)). Omitted: graphical annotations.
# `time < startTime` is a time event in Modelica: the discrete variable `on` (0 before startTime, 1 from it) is
# switched by a discrete event at startTime with a DAE re-initialization, so that the integrator's last step before
# the jump evaluates the pre-step value at every stage (a plain `ifelse(t < startTime, ...)` evaluated post-step at the
# end stage polluted the step and left a permanent speed error in the undamped machine Tests, F-25). With
# startTime <= 0 the output is post-step from the start and there is no event.

@component function Step(; name, height = 1, offset = 0, startTime = 0)
    height, offset, startTime = float.((height, offset, startTime))
    on0 = startTime <= 0 ? 1 : 0
    pars = @parameters begin
        height = height, [description = "Height of step"]
        offset = offset, [description = "Offset of output signal y"]
        startTime = startTime, [description = "Output y = offset for time < startTime (s)"]
    end
    disc = @discretes begin
        on(t) = on0
    end
    vars = @variables begin
        y(t), [description = "Connector of Real output signal"]
    end
    kw = on0 == 1 ? (;) : (;
        discrete_events = [SymbolicDiscreteCallback(t == startTime,
            ImperativeAffect((m, o, ctx, integ) -> (; on = 1); modified = (; on));
            reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())],
        tstops = [[startTime]])
    System(Equation[y ~ offset + on * height], t, vars, [pars; disc]; name, kw...)
end
