# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Math.mo, block RealToBoolean
# Ports are plain variables (u; y from partialBooleanSO). Omitted: graphical annotations.

# Boolean signals are Real 0/1 in this port (PLAN-01): y = (u >= threshold).
@component function RealToBoolean(; name, threshold = 0.5)
    pars = @parameters begin
        threshold = threshold, [description = "Output signal y is true, if input u >= threshold"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    System(Equation[y ~ ifelse(u >= threshold, 1, 0)], t, vars, pars; name)
end
