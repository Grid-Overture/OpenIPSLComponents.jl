# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Sources.mo, block RealExpression
# Ports are plain variables (y). Omitted: graphical annotations.

# The Modelica modifier `y = <expression>` is the keyword argument `expr` (a number), because `y` is the output
# variable; the transcriber renames the modifier. An expression of the parent's variables cannot live in the block's
# equation (F-22): `expr = nothing` leaves `y` without an equation and the parent writes `realExpression.y ~ v^2`
# (PLAN-02; ThermostaticallyControlled, the VSourceIO Tests).
@component function RealExpression(; name, expr = 0.0)
    vars = @variables begin
        y(t), [description = "Value of Real output"]
    end
    System(expr === nothing ? Equation[] : Equation[y ~ expr], t, vars, []; name)
end
