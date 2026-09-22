# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Nonlinear.mo, block VariableLimiter
# Ports are plain variables (u, limit1, limit2, y). Omitted: graphical annotations.

# `strict`, `homotopyType` and `ySimplified` are accepted and have no effect (see Limiter.jl).
@component function VariableLimiter(; name, strict = false, homotopyType = :Linear, ySimplified = 0)
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
        limit1(t), [description = "Connector of Real input signal used as maximum of input u"]
        limit2(t), [description = "Connector of Real input signal used as minimum of input u"]
    end
    System(Equation[y ~ ifelse(u > limit1, limit1, ifelse(u < limit2, limit2, u))], t, vars, []; name)
end
