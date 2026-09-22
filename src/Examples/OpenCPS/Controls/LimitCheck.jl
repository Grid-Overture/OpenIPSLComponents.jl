# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/OpenCPS/Controls/LimitCheck.mo
# "Is `u` inside [lowerLim, upperLim] and has it been for `dt` seconds?": the two threshold comparisons feed an
# `And`, a `Pre` breaks the loop the `Timer` would otherwise close, and the timer's reading is compared with `dt`.
# `upperLim`, `lowerLim` and `dt` have no default in the .mo and are required keyword arguments.
# The last comparator reads the `Timer`'s output, which **jumps** from 0 when the band is entered, so its event is
# located on the right of the jump (`RightRootFind`, F-73 (4)); located on the left the affect would read the
# pre-jump value and the callback would re-fire forever.
# Ports are plain variables (u RealInput, START BooleanOutput as Real 0/1). Omitted: graphical annotations.
# No upstream Test instantiates it: hand test in test/test_OpenCPS.jl.

@component function LimitCheck(; name, upperLim, lowerLim, dt)
    pars = @parameters begin
        upperLim = upperLim, [description = "Upper limit"]
        lowerLim = lowerLim, [description = "Lower limit"]
        dt = dt, [description = "Comparison threshold (s)"]
    end
    systems = @named begin
        and1 = Logical_And()
        greaterEqualThreshold = GreaterEqualThreshold(; threshold = lowerLim)
        lessEqualThreshold = LessEqualThreshold(; threshold = upperLim)
        timer = Timer_()
        greaterEqualThreshold1 = GreaterEqualThreshold(; threshold = dt, rootfind = SciMLBase.RightRootFind)
        pre1 = Pre_()
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        START(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    eqs = Equation[
        and1.u1 ~ greaterEqualThreshold.y,        # connect(greaterEqualThreshold.y, and1.u1)
        greaterEqualThreshold.u ~ u,              # connect(u, greaterEqualThreshold.u)
        and1.u2 ~ lessEqualThreshold.y,           # connect(lessEqualThreshold.y, and1.u2)
        greaterEqualThreshold1.u ~ timer.y,       # connect(timer.y, greaterEqualThreshold1.u)
        pre1.u ~ and1.y,                          # connect(and1.y, pre1.u)
        timer.u ~ pre1.y,                         # connect(pre1.y, timer.u)
        lessEqualThreshold.u ~ greaterEqualThreshold.u,   # connect(lessEqualThreshold.u, greaterEqualThreshold.u)
        START ~ greaterEqualThreshold1.y,         # connect(greaterEqualThreshold1.y, START)
    ]
    System(eqs, t, vars, pars; name, systems)
end
