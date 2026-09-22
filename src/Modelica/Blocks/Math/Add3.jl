# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Math.mo, block Add3
# Ports are plain variables (u1, u2, u3, y). Omitted: graphical annotations.

@component function Add3(; name, k1 = +1, k2 = +1, k3 = +1)
    pars = @parameters begin
        k1 = k1, [description = "Gain of input signal 1"]
        k2 = k2, [description = "Gain of input signal 2"]
        k3 = k3, [description = "Gain of input signal 3"]
    end
    vars = @variables begin
        u1(t), [description = "Connector of Real input signal 1"]
        u2(t), [description = "Connector of Real input signal 2"]
        u3(t), [description = "Connector of Real input signal 3"]
        y(t), [description = "Connector of Real output signal"]
    end
    System(Equation[y ~ k1 * u1 + k2 * u2 + k3 * u3], t, vars, pars; name)
end
