# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Sources.mo, block Sine
# Ports are plain variables (y (SignalSource)). Omitted: graphical annotations.
# `time < startTime` is a time event in Modelica: the discrete variable `on` (0 before startTime, 1 from it) is
# switched by a discrete event at startTime with a DAE re-initialization (Step, F-25); with startTime <= 0 the sine
# runs from the start and there is no event.

@component function Sine(; name, amplitude = 1, f, phase = 0, offset = 0, startTime = 0)
    amplitude, f, phase, offset, startTime = float.((amplitude, f, phase, offset, startTime))
    on0 = startTime <= 0 ? 1 : 0
    pars = @parameters begin
        amplitude = amplitude, [description = "Amplitude of sine wave"]
        f = f, [description = "Frequency of sine wave (Hz)"]
        phase = phase, [description = "Phase of sine wave (rad)"]
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
    System(Equation[y ~ offset + on * amplitude * sin(2 * pi * f * (t - startTime) + phase)], t, vars, [pars; disc];
        name, kw...)
end
