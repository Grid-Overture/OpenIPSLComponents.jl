# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/GE/Type_3/Turbine/Multi_Powers.mo (block; extends Modelica.Blocks.Icons.Block,
# nothing to port)
# Blocks: none. Ports are plain variables (u1; y[1:5]). `[y] = [1; u1; u2; u3; u4]` with the protected `u2`, `u3`,
# `u4` kept as algebraic variables with their names. Omitted: graphical annotations.

@component function Multi_Powers(; name)
    vars = @variables begin
        u1(t), [description = "Input"]
        (y(t))[1:5], [description = "Multiple powers of the input"]
        u2(t)
        u3(t)
        u4(t)
    end
    eqs = Equation[
        u2 ~ u1^2,
        u3 ~ u1^3,
        u4 ~ u1^4,
        y[1] ~ 1,
        y[2] ~ u1,
        y[3] ~ u2,
        y[4] ~ u3,
        y[5] ~ u4,
    ]
    System(eqs, t, [u1, y, u2, u3, u4], []; name)
end
