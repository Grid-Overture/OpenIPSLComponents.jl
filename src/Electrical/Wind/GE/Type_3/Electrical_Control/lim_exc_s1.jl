# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/GE/Type_3/Electrical_Control/lim_exc_s1.mo (extends Modelica.Blocks.Icons.Block,
# nothing to port)
# Blocks: none. Ports are plain variables (Efd, Vt, Vref; y). `typpe` is an Integer parameter chosen in Julia
# (F-50): 1 = anti-windup gate (`y = 0` when Efd is beyond a limit and Vref pushes further out, else Vref; strict
# inequalities, F-77), 2 =
# variable limiter of Vref between Vt + xiqmin and Vt + xiqmax, anything else `y = 0`; inside a branch the `if`s
# are on variables -> `ifelse`. Omitted: graphical annotations.

@component function lim_exc_s1(; name, xiqmin = 1, xiqmax = 1, typpe = 1)
    xiqmin, xiqmax = float.((xiqmin, xiqmax))
    pars = @parameters begin
        xiqmin = xiqmin
        xiqmax = xiqmax
    end
    vars = @variables begin
        Efd(t), [description = "Input: Excitation voltage"]
        Vt(t), [description = "Terminal Voltage"]
        y(t), [description = "Output: saturated excitation voltage"]
        Vref(t), [description = "Reference Voltage"]
    end
    # typpe = 1: the .mo compares Efd with `Vt + xiqmax`/`Vt + xiqmin` with `>=`/`<=`. In OpenModelica a relation in an
    # equation is evaluated with a zero-crossing hysteresis (model_help.c, GreaterEqZC/LessEqZC): false -> true needs
    # `a - b > eps`, so at exact equality -- Efd is lim_exc_s12's output, which sits exactly on Vt + xiqmax when it
    # saturates -- the gate never opens and the block passes Vref through (F-77). The strict inequalities reproduce
    # that: they differ from the .mo's only at equality, where OpenModelica's answer is "false".
    eq = typpe == 1 ? (y ~ ifelse(((Efd > Vt + xiqmax) & (Vref >= 0)) | ((Efd < Vt + xiqmin) & (Vref <= 0)), 0, Vref)) :
         typpe == 2 ? (y ~ ifelse(Vref >= Vt + xiqmax, Vt + xiqmax, ifelse(Vref <= Vt + xiqmin, Vt + xiqmin, Vref))) :
         (y ~ 0)
    System(Equation[eq], t, vars, pars; name)
end
