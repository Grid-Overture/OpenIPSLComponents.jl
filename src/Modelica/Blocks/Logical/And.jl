# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Logical.mo, block And; the function is `Logical_And` because
# `Modelica.Blocks.MathBoolean.And` is already `And` in the package (rule 6.5: a name that repeats across packages
# is prefixed; the instances keep their names, `and1`). This is the two-input block; `MathBoolean.And` takes `nu`.
# Ports are plain variables (u1, u2, y (partialBooleanSI2SO)). Omitted: graphical annotations.

# Boolean signals are Real 0/1 in this port (PLAN-01): y = u1 and u2 is min(u1, u2), the twin of `Or`.
@component function Logical_And(; name)
    vars = @variables begin
        u1(t), [description = "Connector of first Boolean input signal (0/1)"]
        u2(t), [description = "Connector of second Boolean input signal (0/1)"]
        y(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    System(Equation[y ~ min(u1, u2)], t, vars, []; name)
end
