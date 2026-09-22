# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Logical.mo, block Pre; the function is `Pre_` because ModelingToolkit
# exports `Pre` (rule 6.5: the `_` suffix of a colliding name; the instances keep their names, `pre`).
# Ports are plain variables (u, y (partialBooleanSISO)). `initial equation pre(u) = pre_u_start; y = pre(u)`: the
# block that breaks an algebraic loop of Boolean signals by an infinitesimal delay (the event iteration of Modelica
# continues until u = pre(u)). Omitted: graphical annotations.

# Boolean signals are Real 0/1 in this port (PLAN-01). `pre(u)` is the discrete variable `y_d`, which starts at
# `pre_u_start` and is copied from `u` at every jump of `u`: a continuous event on `u - 0.5` **located on the right
# of the jump** (`RightRootFind`, so that the affect reads the post-jump value; on the left it reads the old value
# and the callback re-fires forever, PLAN-08 probe 0.2, F-73) plus, for a jump produced inside another event
# that the continuous callback cannot see (F-41) or a tie between two callbacks at the same instant, a discrete
# callback on `u != y_d` evaluated at the end of every step. Both affects are imperative with `BrownFullBasicInit`
# (F-15), so the algebraic Boolean chain downstream (an RS flip-flop) is re-solved at the event, which is the
# event iteration of Modelica.
@component function Pre_(; name, pre_u_start = false)
    disc = @discretes begin
        y_d(t) = (pre_u_start ? 1.0 : 0.0)
    end
    vars = @variables begin
        u(t), [description = "Connector of Boolean input signal (0/1)"]
        y(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    copy_u = ImperativeAffect((m, o, ctx, integ) -> (; y_d = o.u); modified = (; y_d), observed = (; u))
    ev = SymbolicContinuousCallback([u - 0.5 ~ 0], copy_u; affect_neg = copy_u, rootfind = SciMLBase.RightRootFind,
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    after_event = SymbolicDiscreteCallback(abs(u - y_d) > 0.5, copy_u; reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    System(Equation[y ~ y_d], t, vars, disc; name, continuous_events = [ev], discrete_events = [after_event])
end
