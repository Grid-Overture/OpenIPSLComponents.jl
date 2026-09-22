# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Logical.mo, block Switch
# Ports are plain variables (u1, u2, u3, y). Omitted: graphical annotations.

# Boolean signals are Real 0/1 in this port (PLAN-01): u2 > 0.5 is `true`.
@component function Switch(; name)
    vars = @variables begin
        u1(t), [description = "Connector of first Real input signal"]
        u2(t), [description = "Connector of Boolean input signal (0/1)"]
        u3(t), [description = "Connector of second Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    System(Equation[y ~ ifelse(u2 > 0.5, u1, u3)], t, vars, []; name)
end
