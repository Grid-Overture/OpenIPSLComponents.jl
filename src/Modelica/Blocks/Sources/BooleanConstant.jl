# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Sources.mo, block BooleanConstant
# Ports are plain variables (y (partialBooleanSource)). Omitted: graphical annotations.

# Boolean signals are Real 0/1 in this port (PLAN-01).
@component function BooleanConstant(; name, k = true)
    pars = @parameters begin
        k = (k ? 1 : 0), [description = "Constant output value (1 = true)"]
    end
    vars = @variables begin
        y(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    System(Equation[y ~ k], t, vars, pars; name)
end
