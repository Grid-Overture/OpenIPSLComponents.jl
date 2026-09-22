# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/ElectricalController/BaseClasses/BaseREECA.mo (partial)
# extends: nothing. Ports and the five control flags only; no equation. Same shape as `BaseREECB.jl` plus the
# generator-speed input `Wg` and the fifth flag `pflag` (both the wind drive train's).
# Omitted: graphical annotations.

@component function BaseREECA(; name)
    vars = @variables begin
        Vt(t), [description = "Terminal Voltage Magnitude"]
        Pe(t), [description = "Active Power Generated"]
        Qext(t), [description = "Reactive Power Reference"]
        Qgen(t), [description = "Reactive Power Generated"]
        Pref(t), [description = "Active Power Reference"]
        ip0(t), [description = "Initial Real Current"]
        iq0(t), [description = "Initial Imaginary Current"]
        Iqcmd(t), [description = "Reactive Command Current"]
        Ipcmd(t), [description = "Real Command Current"]
        Wg(t), [description = "Rotational Speed Generator"]
        v0(t), [description = "Initial Terminal Voltage Magnitude"]
        p0(t), [description = "Initial Active Power"]
        q0(t), [description = "Initial Reactive Power"]
    end
    System(Equation[], t, vars, []; name)
end
