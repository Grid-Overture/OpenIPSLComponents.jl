# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/InverterInterface/BaseClasses/LVACM.mo (extends nothing)
# Low Voltage Active Current Management: a three-segment ramp on the terminal voltage.
#   y = smooth(1, noEvent(if Vt <= lvpnt0 then 0 elseif Vt >= lvpnt1 then 1 else (Vt - lvpnt0)/(lvpnt1 - lvpnt0)))
# `noEvent` is `ifelse` (no state event); `smooth(1, ...)` is a smoothness *annotation* for the tool, not an
# equation, and is dropped -- the expression is C0 anyway, and ModelingToolkit has no counterpart.
# Ports are plain variables (Vt input, y output). Omitted: graphical annotations.

@component function LVACM(; name, lvpnt0, lvpnt1)
    lvpnt0, lvpnt1 = float.((lvpnt0, lvpnt1))
    pars = @parameters begin
        lvpnt0 = lvpnt0, [description = "Low voltage point for low voltage active current management"]
        lvpnt1 = lvpnt1, [description = "High voltage point for low voltage active current management"]
    end
    vars = @variables begin
        Vt(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    eqs = Equation[y ~ ifelse(Vt <= lvpnt0, 0.0, ifelse(Vt >= lvpnt1, 1.0, (1 / (lvpnt1 - lvpnt0)) * (Vt - lvpnt0)))]
    System(eqs, t, vars, pars; name)
end
