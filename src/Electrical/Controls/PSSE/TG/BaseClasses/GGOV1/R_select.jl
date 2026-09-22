# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/R_select.mo (block)
# Ports are plain variables (Pelect, ValveStroke, GovernorOutput inputs; y output). The four-branch `if` is on an
# Integer parameter: decided in Julia before `@parameters` (F-22, point 1), and the three inputs exist in every
# branch because the .mo declares them unconditionally. Omitted: graphical annotations.

@component function R_select(; name, Rselect = 0)
    branch = Rselect   # the Integer value: `@parameters` below rebinds `Rselect` to the symbol (F-22)
    pars = @parameters begin
        Rselect = Rselect, [description = "Feedback signal for governor droop"]
    end
    vars = @variables begin
        Pelect(t)
        ValveStroke(t)
        GovernorOutput(t)
        y(t)
    end
    sel = branch == 1 ? Pelect : branch == -1 ? ValveStroke : branch == -2 ? GovernorOutput : 0
    System(Equation[y ~ sel], t, vars, pars; name)
end
