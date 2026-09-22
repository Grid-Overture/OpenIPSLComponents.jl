# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Math.mo, block Gain
# Ports are plain variables (u, y). Omitted: graphical annotations.

@component function Gain(; name, k)
    pars = @parameters begin
        k = k, [description = "Gain value multiplied with input signal"]
    end
    vars = @variables begin
        u(t), [description = "Input signal connector"]
        y(t), [description = "Output signal connector"]
    end
    System(Equation[y ~ k * u], t, vars, pars; name)
end
