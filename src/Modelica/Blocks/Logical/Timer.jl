# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Logical.mo, block Timer; the function is `Timer_` because `Timer` is a Base
# type (rule 6.5: a name that collides with Base takes the `_` suffix; the instances keep their names, `timer`).
# Ports are plain variables (u (BooleanInput), y). `discrete entryTime; initial equation pre(entryTime) = 0;
# when u then entryTime = time; end when; y = if u then time - entryTime else 0.0`. Omitted: graphical annotations.

# Boolean signals are Real 0/1 in this port (PLAN-01). `when u` is the rising edge of the 0/1 input: a continuous
# event on `u - 0.5` **located on the right of the jump** (`RightRootFind`; located on the left, the affect reads
# the pre-jump value and the callback re-fires forever, PLAN-08 probe 0.2, F-73) whose affect sets `entryTime`
# to the event time; plus, for an edge produced inside another event (F-41) or a tie with another callback at the
# same instant, a discrete callback at the end of every step on `u != u_d`, where the discrete `u_d` remembers the
# last value of `u` the events saw. `u_d` starts at 1: an input that is true from t = 0 raises no edge, as
# `pre(u) = u` at initialization in Modelica (`entryTime` stays 0 and `y = time`), and one that is false is
# synchronized at the end of the first step. Affects imperative with `BrownFullBasicInit` (F-15).
# `y = if u then time - entryTime else 0` reads `u_d` as well as `u`: between the jump of `u` and its own event the
# block would otherwise report `time - entryTime` with the **stale** `entryTime` (the value of a previous edge),
# which in a Picdro made the drop-off threshold fire at the very instant the pick-up released (F-73). In Modelica
# the `when` and the equation are solved in the same event iteration, so `y` never shows that value.
@component function Timer_(; name)
    disc = @discretes begin
        entryTime(t) = 0.0
        u_d(t) = 1.0
    end
    vars = @variables begin
        u(t), [description = "Connector of Boolean input signal (0/1)"]
        y(t), [description = "Connector of Real output signal"]
    end
    rise = ImperativeAffect((m, o, ctx, integ) -> (; entryTime = integ.t, u_d = 1.0); modified = (; entryTime, u_d))
    fall = ImperativeAffect((m, o, ctx, integ) -> (; u_d = 0.0); modified = (; u_d))
    ev = SymbolicContinuousCallback([u - 0.5 ~ 0], rise; affect_neg = fall, rootfind = SciMLBase.RightRootFind,
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    after_event = SymbolicDiscreteCallback(abs(u - u_d) > 0.5,
        ImperativeAffect((m, o, ctx, integ) -> (; entryTime = o.u > 0.5 ? integ.t : m.entryTime, u_d = o.u);
            modified = (; entryTime, u_d), observed = (; u)); reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    System(Equation[y ~ ifelse((u > 0.5) & (u_d > 0.5), t - entryTime, 0.0)], t, vars, disc; name,
        continuous_events = [ev], discrete_events = [after_event])
end
