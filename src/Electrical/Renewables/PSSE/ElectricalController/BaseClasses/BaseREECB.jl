# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/ElectricalController/BaseClasses/BaseREECB.mo (partial)
# extends: nothing. Ports and the four control flags only; no equation.
# The flags `pfflag`, `vflag`, `qflag`, `pqflag` are Boolean parameters and stay numeric keyword arguments: the
# child instantiates their `BooleanConstant` blocks with them (F-50).
# Omitted: graphical annotations.

@component function BaseREECB(; name)
    vars = @variables begin
        Vt(t), [description = "Terminal Voltage Magnitude"]
        Pe(t), [description = "Electrical Power Generation"]
        Qext(t), [description = "Reactive Power Reference"]
        Qgen(t), [description = "Reactive Power Generation"]
        Pref(t), [description = "Active Power Reference"]
        ip0(t), [description = "Initial Real Current"]
        iq0(t), [description = "Initial Reactive Current"]
        Iqcmd(t), [description = "Command Reactive Current"]
        Ipcmd(t), [description = "Command Active Current"]
        v0(t), [description = "Initial Terminal Voltage Magnitude"]
        p0(t), [description = "Initial Active Power"]
        q0(t), [description = "Initial Reactive Power"]
    end
    System(Equation[], t, vars, []; name)
end
