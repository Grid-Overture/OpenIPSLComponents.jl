# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Functions/ImSE.mo (block)
# Ports are plain variables (VE_IN, VE_OUT). Omitted: graphical annotations.

@component function ImSE(; name, SE1, SE2, E1, E2)
    SE1, SE2, E1, E2 = float.((SE1, SE2, E1, E2))
    coeffs = (SE1, SE2, E1, E2)   # numeric copies: SE's branches on the coefficients are plain Julia
    pars = @parameters begin
        SE1 = SE1, [description = "Saturation at E1"]
        SE2 = SE2, [description = "Saturation at E2"]
        E1 = E1
        E2 = E2
    end
    vars = @variables begin
        VE_IN(t), [description = "Unsaturated Input"]
        VE_OUT(t), [description = "Saturated Output"]
    end
    # the saturation coefficients are numbers here (the function receives the numeric parameters)
    System(Equation[VE_OUT ~ SE(VE_IN, coeffs...)], t, vars, pars; name)
end
