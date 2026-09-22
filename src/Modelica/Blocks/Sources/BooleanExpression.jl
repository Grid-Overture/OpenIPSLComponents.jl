# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Sources.mo, block BooleanExpression
# Ports are plain variables (y). Omitted: graphical annotations.

# Boolean signals are Real 0/1 in this port (PLAN-01); `expr` is the Modelica modifier `y = <Boolean expression>`,
# given as a symbolic condition of the parent (`ifelse(cond, 1, 0)` is applied here) or as a Bool.
# `expr = nothing` leaves `y` without an equation and the parent writes it, as `RealExpression` does: a modifier
# that reads a 0/1 variable already computed by the parent (`VLogic(y = Voltage_dip)` of REPCA1) cannot live in
# the block's own equation (F-22).
@component function BooleanExpression(; name, expr = false)
    vars = @variables begin
        y(t), [description = "Value of Boolean output (0/1)"]
    end
    expr === nothing && return System(Equation[], t, vars, []; name)
    rhs = expr isa Bool ? (expr ? 1 : 0) : ifelse(expr, 1, 0)
    System(Equation[y ~ rhs], t, vars, []; name)
end
