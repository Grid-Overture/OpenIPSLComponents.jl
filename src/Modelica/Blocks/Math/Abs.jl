# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Math.mo, block Abs
# Ports are plain variables (u, y (SISO)). Omitted: graphical annotations; generateEvent has no effect.

@component function Abs(; name, generateEvent = false)
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    # y = if u >= 0 then u else -u, with or without an event: `ifelse` never generates one in MTK (generateEvent ignored)
    System(Equation[y ~ ifelse(u >= 0, u, -u)], t, vars, []; name)
end
