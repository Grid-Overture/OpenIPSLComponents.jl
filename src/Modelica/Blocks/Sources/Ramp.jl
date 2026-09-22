# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Sources.mo, block Ramp
# Ports are plain variables (y (SignalSource)). Omitted: graphical annotations.
# `time < startTime` and `time < startTime + duration` are time events in Modelica: the discrete variables on1
# (1 from startTime) and on2 (1 from startTime + duration) are switched by discrete events with a DAE
# re-initialization (Step, F-25); an instant that is <= 0 is on from the start and has no event.

@component function Ramp(; name, height = 1, duration, offset = 0, startTime = 0)
    height, duration, offset, startTime = float.((height, duration, offset, startTime))
    dur = max(duration, Modelica.Constants.eps)   # MSL: max(duration, eps), so duration = 0 is a step
    t1, t2 = startTime, startTime + dur
    on10, on20 = t1 <= 0 ? 1 : 0, t2 <= 0 ? 1 : 0
    pars = @parameters begin
        height = height, [description = "Height of ramps"]
        duration = duration, [description = "Duration of ramp (s; 0 gives a step)"]
        dur = dur, [description = "max(duration, eps)"]
        offset = offset, [description = "Offset of output signal y"]
        startTime = startTime, [description = "Output y = offset for time < startTime (s)"]
    end
    disc = @discretes begin
        on1(t) = on10
        on2(t) = on20
    end
    vars = @variables begin
        y(t), [description = "Connector of Real output signal"]
    end
    switch1 = SymbolicDiscreteCallback(t == startTime,
        ImperativeAffect((m, o, ctx, integ) -> (; on1 = 1); modified = (; on1));
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    switch2 = SymbolicDiscreteCallback(t == startTime + dur,
        ImperativeAffect((m, o, ctx, integ) -> (; on2 = 1); modified = (; on2));
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    events = [(on10 == 0 ? [switch1] : [])..., (on20 == 0 ? [switch2] : [])...]
    stops = [t for (t, o) in ((t1, on10), (t2, on20)) if o == 0]
    kw = isempty(events) ? (;) : (; discrete_events = events, tstops = [stops])
    System(Equation[y ~ offset + on1 * (1 - on2) * (t - startTime) * height / dur + on2 * height], t, vars,
        [pars; disc]; name, kw...)
end
