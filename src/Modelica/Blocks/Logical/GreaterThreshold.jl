# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Logical.mo, block GreaterThreshold
# Ports are plain variables (u, y (partialBooleanThresholdComparison)). Omitted: graphical annotations.

# Boolean output as Real 0/1 (PLAN-01). The comparison is a state event in Modelica: the crossing u = threshold is
# registered as a continuous event without affect, so that the integrator steps exactly onto it. `rootfind` chooses
# the side of the root the integrator lands on: `RightRootFind` for an input that **jumps** across the threshold (a
# `Timer` output; located on the left the callback re-fires, PLAN-08 probe 0.2, F-73), the default otherwise.
@component function GreaterThreshold(; name, threshold = 0, rootfind = SciMLBase.LeftRootFind)
    pars = @parameters begin
        threshold = threshold, [description = "Comparison with respect to threshold"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    System(Equation[y ~ ifelse(u > threshold, 1, 0)], t, vars, pars; name,
        continuous_events = [SymbolicContinuousCallback([u - threshold ~ 0], nothing; rootfind)])
end
