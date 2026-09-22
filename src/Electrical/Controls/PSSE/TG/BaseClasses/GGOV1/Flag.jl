# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/Flag.mo (block)
# Ports are plain variables (speed input, y output). `y = if Flag == 1 then speed + 1 else 1` is an `if` on an
# Integer parameter: decided in Julia before `@parameters` (F-22, point 1). Omitted: graphical annotations.

@component function Flag(; name, Flag)
    branch = Flag == 1
    pars = @parameters begin
        Flag = Flag, [description = "Switch for fuel source characteristic"]
    end
    vars = @variables begin
        speed(t)
        y(t)
    end
    System(Equation[y ~ (branch ? speed + 1 : 1)], t, vars, pars; name)
end

# Julia-only alias: `Turbine.mo` has both a class `Flag` and a parameter `Flag`, and inside the Julia constructor the
# keyword argument shadows the block's name, so the instance is built through this alias. It changes no hierarchical
# name (the instance is still `flag10`).
const GGOV1_Flag = Flag
