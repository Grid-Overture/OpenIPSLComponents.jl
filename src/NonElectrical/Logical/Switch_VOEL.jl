# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Logical/Switch_VOEL.mo (model)
# Ports are plain variables (u, y1, y2). `n` is an Integer parameter, decided at construction. Omitted: graphical
# annotations.

@component function Switch_VOEL(; name, n)
    vars = @variables begin
        u(t)
        y1(t)
        y2(t)
    end
    eqs = Equation[
        y1 ~ (n == 1 ? u : 0),
        y2 ~ (n == 2 ? u : Modelica.Constants.inf),
    ]
    System(eqs, t, vars, []; name)
end
