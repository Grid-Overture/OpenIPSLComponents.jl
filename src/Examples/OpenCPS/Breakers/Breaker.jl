# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/OpenCPS/Breakers/Breaker.mo
# Controllable line breaker of the OpenCPS resynchronization bench: `TRIGGER` false leaves it open, true closes it
# -- the opposite polarity of `Electrical/Events/Breaker.mo`, whose `Open` is true when open. Named
# `OpenCPS_Breaker` (JULIA_NAMES): `Breaker` is the one of `Electrical.Events` (rule 6.5).
# The `.mo` writes the closed mode as `ir = is; vs = vr`, that is `n.i = p.i` and not `is = -ir` as
# `Events/Breaker.mo` does: with the breaker closed the two pin currents enter the branch with the *same* sign, so
# the branch does not conserve current (F-84). It is ported literally, quirk included, and is not reused from
# `Breaker(enableTrigger = true)`, whose sign and polarity are the other ones.
# Form: the mixture of F-24 with the mode as an unknown. `Closed` is an algebraic 0/1 variable equal to `TRIGGER`,
# never the discrete itself: with a discrete coefficient the tearing solves the voltage equation symbolically and
# divides by `1 - Closed`, and the re-initialization at the switching fails with Inf (F-24).
#   closed (Closed = 1): p.i = n.i, p.v = n.v        open (Closed = 0): p.i = 0, n.i = 0
# The Complex aliases vs, vr, is, ir of the .mo are the pin variables themselves. Omitted: graphical annotations.
# No upstream Test instantiates it: hand test in test/test_OpenCPS.jl.

@component function OpenCPS_Breaker(; name)
    systems = @named begin
        p = PwPin()
        n = PwPin()
    end
    vars = @variables begin
        TRIGGER(t), [description = "Breaker gating signal: true closes the breaker (0/1)"]
        Closed(t), [description = "Help variable to indicate a closed breaker (0/1)"]
    end
    eqs = Equation[
        Closed ~ TRIGGER,
        p.ir ~ Closed * n.ir,
        p.ii ~ Closed * n.ii,
        Closed * (p.vr - n.vr) + (1 - Closed) * n.ir ~ 0,
        Closed * (p.vi - n.vi) + (1 - Closed) * n.ii ~ 0,
    ]
    System(eqs, t, vars, []; name, systems)
end
