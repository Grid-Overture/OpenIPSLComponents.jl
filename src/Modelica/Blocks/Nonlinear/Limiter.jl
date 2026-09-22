# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Nonlinear.mo, block Limiter
# Ports are plain variables (u, y (SISO)). Omitted: graphical annotations.

# `strict` (noEvent) and `homotopyType` are accepted and have no effect: `ifelse` generates no event in MTK and the
# simulation uses the `actual` branch of `homotopy` (PLAN-01).
@component function Limiter(; name, uMax, uMin = -uMax, strict = false, homotopyType = :Linear)
    pars = @parameters begin
        uMax = uMax, [description = "Upper limits of input signals"]
        uMin = uMin, [description = "Lower limits of input signals"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    System(Equation[y ~ ifelse(u > uMax, uMax, ifelse(u < uMin, uMin, u))], t, vars, pars; name)
end
