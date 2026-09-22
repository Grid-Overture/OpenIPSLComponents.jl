# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Nonlinear.mo, block DeadZone
# Ports are plain variables (u, y (SISO)). Omitted: graphical annotations.

@component function DeadZone(; name, uMax, uMin = -uMax)
    pars = @parameters begin
        uMax = uMax, [description = "Upper limits of dead zones"]
        uMin = uMin, [description = "Lower limits of dead zones"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    # homotopy(actual = ..., simplified = u): the actual branch
    System(Equation[y ~ ifelse(u > uMax, u - uMax, ifelse(u < uMin, u - uMin, 0))], t, vars, pars; name)
end
