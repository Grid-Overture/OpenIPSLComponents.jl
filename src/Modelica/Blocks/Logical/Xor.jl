# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Logical.mo, block Xor
# Ports are plain variables (u1, u2, y (partialBooleanSI2SO)). Omitted: graphical annotations.

# Boolean signals are Real 0/1 in this port (PLAN-01): `y = not (u1 == u2)` is `|u1 - u2|`, the twin of `Or`'s
# `max(u1, u2)` and `And`'s `min(u1, u2)`.
@component function Xor(; name)
    vars = @variables begin
        u1(t), [description = "Connector of first Boolean input signal (0/1)"]
        u2(t), [description = "Connector of second Boolean input signal (0/1)"]
        y(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    System(Equation[y ~ abs(u1 - u2)], t, vars, []; name)
end
