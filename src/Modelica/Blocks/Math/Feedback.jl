# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Math.mo, block Feedback
# Ports are plain variables (u1, u2, y). Omitted: graphical annotations.

@component function Feedback(; name)
    vars = @variables begin
        u1(t), [description = "Commanded input"]
        u2(t), [description = "Feedback input"]
        y(t), [description = "Connector of Real output signal"]
    end
    System(Equation[y ~ u1 - u2], t, vars, []; name)
end
