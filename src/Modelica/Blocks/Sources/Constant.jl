# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Sources.mo, block Constant
# Ports are plain variables (y (SO)). Omitted: graphical annotations.

@component function Constant(; name, k)
    pars = @parameters begin
        k = k, [description = "Constant output value"]
    end
    vars = @variables begin
        y(t), [description = "Connector of Real output signal"]
    end
    System(Equation[y ~ k], t, vars, pars; name)
end
