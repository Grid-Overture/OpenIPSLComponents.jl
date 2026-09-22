# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/ElectricalController/BaseClasses/BaseREECC.mo (partial)
# extends: nothing. Ports and the four control flags only; no equation. Same shape as `BaseREECB.jl` plus the
# auxiliary active-power input `Paux` (the battery's, held at 0 by the `BESS` template).
# Omitted: graphical annotations.

@component function BaseREECC(; name)
    vars = @variables begin
        ip0(t), [description = "Initial Active Current"]
        iq0(t), [description = "Initial Reactive Current"]
        Iqcmd(t), [description = "Reactive Command Current"]
        Ipcmd(t), [description = "Active Command Current"]
        v0(t), [description = "Initial Terminal Voltage Magnitude"]
        p0(t), [description = "Initial Active Power"]
        q0(t), [description = "Initial Reactive Power"]
        Vt(t), [description = "Terminal Voltage Magnitude"]
        Pe(t), [description = "Electrical Power"]
        Qext(t), [description = "Reactive Power Reference"]
        Qgen(t), [description = "Reactive Power Generated"]
        Pref(t), [description = "Active Power Reference"]
        Paux(t), [description = "Auxiliary Signal for Active Power"]
    end
    System(Equation[], t, vars, []; name)
end
