# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/Dm_select.mo (block)
# Ports are plain variables (speed input, y output). `y = if Dm >= 0 then speed + 1 else (speed + 1)^Dm` is an `if`
# on a Real parameter: decided in Julia before `@parameters` (F-22, point 1). Omitted: graphical annotations.

@component function Dm_select(; name, Dm)
    Dm = float(Dm)
    nonneg, Dmn = Dm >= 0, Dm
    pars = @parameters begin
        Dm = Dm, [description = "Mechanical damping coefficient"]
    end
    vars = @variables begin
        speed(t)
        y(t)
    end
    System(Equation[y ~ (nonneg ? speed + 1 : (speed + 1)^Dmn)], t, vars, pars; name)
end
