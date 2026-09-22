# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Logical.mo, block Not
# Ports are plain variables (u, y (partialBooleanSISO)). Omitted: graphical annotations.

# Boolean signals are Real 0/1 in this port (PLAN-01): y = not u is 1 - u.
@component function Not(; name)
    vars = @variables begin
        u(t), [description = "Connector of Boolean input signal (0/1)"]
        y(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    System(Equation[y ~ 1 - u], t, vars, []; name)
end
