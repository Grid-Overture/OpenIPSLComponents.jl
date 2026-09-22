# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Math.mo, block PolarToRectangular
# Ports are plain variables (u_abs, u_arg, y_re, y_im). Omitted: graphical annotations.

@component function PolarToRectangular(; name)
    vars = @variables begin
        u_abs(t), [description = "Length of polar representation"]
        u_arg(t), [description = "Angle of polar representation (rad)"]
        y_re(t), [description = "Real part of rectangular representation"]
        y_im(t), [description = "Imaginary part of rectangular representation"]
    end
    System(Equation[y_re ~ u_abs * cos(u_arg), y_im ~ u_abs * sin(u_arg)], t, vars, []; name)
end
