# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Nonlinear/FEX.mo (model)
# Ports are plain variables (u, y). The five-branch `if` is a nested `ifelse`; because `ifelse` evaluates every branch,
# the square root is guarded with max(., 0) (no effect on the selected branch). Omitted: graphical annotations.

@component function FEX(; name)
    vars = @variables begin
        u(t)
        y(t)
    end
    eqs = Equation[y ~ ifelse(u <= 0, 1,
        ifelse(u <= 0.433, 1 - 0.577 * u,
            ifelse(u < 0.75, sqrt(max(0.75 - u^2, 0)),
                ifelse(u <= 1, 1.732 * (1 - u), 0))))]
    System(eqs, t, vars, []; name)
end
