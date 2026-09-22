# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Math.mo, block Cos
# Ports are plain variables (u (rad), y (SISO)). Omitted: graphical annotations.

@component function Cos(; name)
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    System(Equation[y ~ cos(u)], t, vars, []; name)
end
