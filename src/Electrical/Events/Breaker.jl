# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Events/Breaker.mo
# Circuit breaker with time or signal control. `enableTrigger` is decided in Julia (Modelica `Evaluate = true`):
#   false: the discrete variable `opened` (0/1) is switched by a discrete event at t_o (and back at t_rc when
#          `rc_enabled`), imperative affects + DAE re-initialization (F-15); with the default t_o =
#          Modelica.Constants.inf there are no events and the breaker stays closed;
#   true:  the conditional BooleanInput `Trigger` is a plain variable (0/1) and `Open ~ Trigger`.
# The protected Boolean `Open` is an algebraic variable (0/1) in both cases. The two operating modes
# (`if Open then is = ir = 0 else vs = vr, is = -ir`) are written with Open as the blend
#   s.ir ~ (1 - Open)*(-r.ir),  (1 - Open)*(s.vr - r.vr) + Open*r.ir ~ 0  (and the imaginary parts),
# which is the closed pair for Open = 0 and the open pair for Open = 1 (PLAN-02). Open must be a variable, not the
# discrete itself: with a discrete coefficient the tearing solves the voltage equation symbolically for a voltage,
# dividing by 1 - Open, and the re-initialization at the opening fails with Inf (F-24); with an unknown in the
# coefficient the equation stays in the numerically solved algebraic loop. The Complex aliases vs, vr, is, ir of the
# .mo are the pin variables themselves. Omitted: graphical annotations.
# OpenIPSL's own Tests.Events.TestBreaker cannot be simulated by OpenModelica 1.25 (F-23): hand test only.

@component function Breaker(; name, enableTrigger = false, t_o = Modelica.Constants.inf, rc_enabled = false,
        t_rc = Modelica.Constants.inf)
    t_o, t_rc = float.((t_o, t_rc))
    opens = t_o < Modelica.Constants.inf
    recloses = rc_enabled && t_rc < Modelica.Constants.inf
    pars = @parameters begin
        t_o = t_o, [description = "Opening time (s)"]
        t_rc = t_rc, [description = "Reclosing time (s)"]
    end
    systems = @named begin
        s = PwPin()
        r = PwPin()
    end
    vars = @variables begin
        Open(t), [description = "Help variable to indicate open circuit breaker (0/1)"]
    end
    if enableTrigger
        trig = @variables begin
            Trigger(t), [description = "External trigger signal (0/1)"]
        end
        append!(vars, trig)
        disc = []
        control = Equation[Open ~ Trigger]
        kw = (;)
    else
        disc = @discretes begin
            opened(t) = 0
        end
        control = Equation[Open ~ opened]
        switch(tev, value) = SymbolicDiscreteCallback(t == tev,
            ImperativeAffect((m, o, ctx, integ) -> (; opened = value); modified = (; opened));
            reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
        events = opens ? (recloses ? [switch(t_o, 1), switch(t_rc, 0)] : [switch(t_o, 1)]) : []
        stops = opens ? (recloses ? [[t_o, t_rc]] : [[t_o]]) : []
        kw = isempty(events) ? (;) : (; discrete_events = events, tstops = stops)
    end
    eqs = Equation[
        control...,
        s.ir ~ (1 - Open) * (-r.ir),
        s.ii ~ (1 - Open) * (-r.ii),
        (1 - Open) * (s.vr - r.vr) + Open * r.ir ~ 0,
        (1 - Open) * (s.vi - r.vi) + Open * r.ii ~ 0,
    ]
    System(eqs, t, vars, [pars; disc]; name, systems, kw...)
end
