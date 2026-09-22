# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSSE/Submodels/LVPL.mo (extends nothing); the function is `Wind_LVPL` because
# `Renewables/PSSE/InverterInterface/BaseClasses/LVPL` is `LVPL` (rule 6.5, PLAN-08). It is **not** the same block:
# this one returns **1e6** above VLVPL2 (the other saturates at Lvpl1) and has no `noEvent`.
# Blocks: none. Ports are plain variables (Vt; LVPL, an output named like the class). `K = GLVPL/(VLVPL2 - VLVPL1)`
# is the derived parameter. The three-branch `if` on `Vt` is an `ifelse` (no event in ModelingToolkit; F-27 if
# OpenModelica's event rows at the crossings matter). Omitted: graphical annotations.

@component function Wind_LVPL(; name, VLVPL1, VLVPL2, GLVPL)
    VLVPL1, VLVPL2, GLVPL = float.((VLVPL1, VLVPL2, GLVPL))
    K = GLVPL / (VLVPL2 - VLVPL1)
    pars = @parameters begin
        VLVPL1 = VLVPL1, [description = "LVPL voltage 1 (Low voltage power logic) (pu)"]
        VLVPL2 = VLVPL2, [description = "LVPL voltage 2 (pu)"]
        GLVPL = GLVPL, [description = "LVPL gain"]
        K = K
    end
    vars = @variables begin
        Vt(t), [description = "Terminal voltage (pu)"]
        LVPL(t), [description = "Low voltage power logic output"]
    end
    System(Equation[LVPL ~ ifelse(Vt < VLVPL1, 0, ifelse(Vt > VLVPL2, 1e+6, K * (Vt - VLVPL1)))], t, vars, pars; name)
end
