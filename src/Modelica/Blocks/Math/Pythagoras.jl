# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Math.mo, block Pythagoras
# Ports are plain variables (u1, u2, y (SI2SO); valid as Real 0/1). `u1IsHypotenuse` is a Boolean parameter: the
# branch is chosen in Julia (F-50). With `u1IsHypotenuse = true`, `y = if noEvent(y2 >= 0) then sqrt(y2) else 0` is
# an `ifelse` whose dead branch takes `sqrt(max(y2, 0))`, so that a negative `y2` does not produce a NaN in the
# branch that is not selected. Omitted: graphical annotations.

@component function Pythagoras(; name, u1IsHypotenuse = false)
    vars = @variables begin
        u1(t), [description = "Connector of Real input signal 1"]
        u2(t), [description = "Connector of Real input signal 2"]
        y(t), [description = "Connector of Real output signal"]
        valid(t), [description = "= true (1), if y is a valid result"]
        y2(t), [description = "Square of y"]
    end
    eqs = u1IsHypotenuse ? Equation[
        y2 ~ u1^2 - u2^2,
        valid ~ ifelse(y2 >= 0, 1, 0),
        y ~ ifelse(y2 >= 0, sqrt(max(y2, 0)), 0),
    ] : Equation[
        y2 ~ u1^2 + u2^2,
        y ~ sqrt(y2),
        valid ~ 1,
    ]
    System(eqs, t, vars, []; name)
end
