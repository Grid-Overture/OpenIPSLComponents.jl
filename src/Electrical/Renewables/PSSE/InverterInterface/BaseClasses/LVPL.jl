# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/InverterInterface/BaseClasses/LVPL.mo (extends nothing)
# Low Voltage Power Logic: a three-segment characteristic on the filtered terminal voltage.
#   y = noEvent(if V < Zerox then 0 else if V > Brkpt then Lvpl1 else (V - Zerox)*(Lvpl1/(Brkpt - Zerox)))
# `noEvent` is exactly `ifelse` in ModelingToolkit (no state event), so the two branches are written literally.
# Ports are plain variables (V input, y output). Omitted: graphical annotations.

@component function LVPL(; name, Brkpt, Lvpl1, Zerox)
    Brkpt, Lvpl1, Zerox = float.((Brkpt, Lvpl1, Zerox))
    pars = @parameters begin
        Brkpt = Brkpt, [description = "LVPL characteristic voltage 2"]
        Lvpl1 = Lvpl1, [description = "LVPL gain"]
        Zerox = Zerox, [description = "LVPL characteristic voltage 1"]
    end
    vars = @variables begin
        V(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    eqs = Equation[y ~ ifelse(V < Zerox, 0.0, ifelse(V > Brkpt, Lvpl1, (V - Zerox) * (Lvpl1 / (Brkpt - Zerox))))]
    System(eqs, t, vars, pars; name)
end
