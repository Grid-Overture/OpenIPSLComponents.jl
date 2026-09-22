# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/WindDriveTrain/BaseClasses/BaseWTDT.mo (partial)
# extends: Electrical/Essentials/pfComponent.mo with every `enable*` false: only `S_b` and `fn` are useful keyword
# arguments here (and `fn` only because `WTDTA1` reads `SysData.fn`).
# Ports and `W0` only; no equation. Omitted: displayPF, graphical annotations.

@component function BaseWTDT(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        W0 = 0)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, W0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, W0))
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    pars = @parameters begin
        W0 = W0
    end
    vars = @variables begin
        Pm(t), [description = "Mechanical Power"]
        Pe(t), [description = "Electrical Power"]
        wt(t), [description = "Rotational Speed Deviation Turbine Blade"]
        wg(t), [description = "Rotational Speed Deviation Generator"]
        W_0(t)
        P0(t)
    end
    extend(System(Equation[], t, vars, pars; name), base)
end
