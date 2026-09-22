# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/ElectricalController/BaseClasses/StateOfChargeLogic.mo
# extends: nothing. Two flags on the battery's state of charge:
#   ipmax_SOC = if SOC <= SOCmin then 0 else 1;   ipmin_SOC = if SOC >= SOCmax then 0 else 1
# `SOC` is a variable (the integral of the power), so both are `ifelse` on a variable, no event (precedent
# `TGTypeI`). Ports are plain variables (SOC input; ipmax_SOC, ipmin_SOC outputs).
# Omitted: graphical annotations.

@component function StateOfChargeLogic(; name, SOCmin, SOCmax)
    SOCmin, SOCmax = float.((SOCmin, SOCmax))
    pars = @parameters begin
        SOCmin = SOCmin, [description = "Minimum allowable state of charge"]
        SOCmax = SOCmax, [description = "Maximum allowable state of charge"]
    end
    vars = @variables begin
        SOC(t), [description = "State of Charge of the Battery"]
        ipmax_SOC(t), [description = "Maximum Battery Charge"]
        ipmin_SOC(t), [description = "Minimum Battery Charge"]
    end
    eqs = Equation[
        ipmax_SOC ~ ifelse(SOC <= SOCmin, 0.0, 1.0),
        ipmin_SOC ~ ifelse(SOC >= SOCmax, 0.0, 1.0),
    ]
    System(eqs, t, vars, pars; name)
end
