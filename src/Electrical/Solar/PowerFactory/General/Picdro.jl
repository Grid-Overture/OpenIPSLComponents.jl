# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/General/Picdro.mo (extends nothing)
# Blocks, with the names of the .mo: timer, timer1 = Timer, greaterThreshold(threshold = Tpick + 1e-8),
# greaterThreshold1(threshold = Tdrop + 1e-8), rSFlipFlop = RSFlipFlop, not1 = Not. Ports are plain variables
# (condition; trip), Boolean as 0/1 (PLAN-01). Pick-up/drop-off: `trip` is set when `condition` has been true for
# more than Tpick and reset when "not more than Tpick" has lasted more than Tdrop; with Tpick = 0 the effective
# delay is 1e-8 s (the "small constant ... to avoid numerical issues" of the .mo). `Tpick`, `Tdrop` have no
# default. The logic lives in the blocks (rule 6.3); the two thresholds see **jumping** inputs (`timer.y` falls
# to 0 with `condition`, `timer1.y` with `not1.y`), so their affect-less crossing events are located on the right
# of the jump (`rootfind = RightRootFind`, PLAN-08 probe 0.2, F-73), never on the left. Omitted: graphical
# annotations.

@component function Picdro(; name, Tpick, Tdrop)
    Tpick, Tdrop = float.((Tpick, Tdrop))
    pars = @parameters begin
        Tpick = Tpick, [description = "Pick-up time delay (s)"]
        Tdrop = Tdrop, [description = "Drop-off time delay (s)"]
    end
    systems = @named begin
        timer = Timer_()
        greaterThreshold = GreaterThreshold(; threshold = Tpick + 1e-8, rootfind = SciMLBase.RightRootFind)
        rSFlipFlop = RSFlipFlop()
        timer1 = Timer_()
        greaterThreshold1 = GreaterThreshold(; threshold = Tdrop + 1e-8, rootfind = SciMLBase.RightRootFind)
        not1 = Not()
    end
    vars = @variables begin
        condition(t), [description = "Connector of Boolean input signal (0/1)"]
        trip(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    eqs = Equation[
        condition ~ timer.u,                         # connect(condition, timer.u)
        greaterThreshold.u ~ timer.y,                # connect(greaterThreshold.u, timer.y)
        rSFlipFlop.Q ~ trip,                         # connect(rSFlipFlop.Q, trip)
        greaterThreshold.y ~ rSFlipFlop.S,           # connect(greaterThreshold.y, rSFlipFlop.S)
        timer1.y ~ greaterThreshold1.u,              # connect(timer1.y, greaterThreshold1.u)
        not1.y ~ timer1.u,                           # connect(not1.y, timer1.u)
        greaterThreshold1.y ~ rSFlipFlop.R,          # connect(greaterThreshold1.y, rSFlipFlop.R)
        not1.u ~ greaterThreshold.y,                 # connect(not1.u, greaterThreshold.y)
    ]
    System(eqs, t, vars, pars; name, systems)
end
