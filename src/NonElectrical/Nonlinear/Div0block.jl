# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Nonlinear/Div0block.mo (block)
# Ports are plain variables (u1, u2, y; SI2SO). Omitted: graphical annotations.

@component function Div0block(; name)
    vars = @variables begin
        u1(t), [description = "Connector of Real input signal 1"]
        u2(t), [description = "Connector of Real input signal 2"]
        y(t), [description = "Connector of Real output signal"]
    end
    System(Equation[y ~ div0protect(u1, u2)], t, vars, []; name)
end
