# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Buses/InternalBus.mo: a change of base between two pins.
# Two PwPins, `p` (machine base) and `n` (system base), tied at the voltage and scaled at the current by
# CoB = M_b/S_b. `S_b` defaults to the outer SystemBase's, as in the .mo. Omitted: graphical annotations.

@component function InternalBus(; name, M_b = 120e6, S_b = 100e6, fn = 50)   # fn: unused here, accepted as SysData's
    M_b, S_b = float.((M_b, S_b))
    pars = @parameters begin
        M_b = M_b, [description = "Machine base power rating (VA)"]
        S_b = S_b, [description = "System base power rating (VA)"]
        CoB = M_b / S_b
    end
    systems = @named begin
        p = PwPin()
        n = PwPin()
    end
    eqs = Equation[
        0 ~ n.vr - p.vr,
        0 ~ n.vi - p.vi,
        0 ~ p.ir * CoB + n.ir,
        0 ~ p.ii * CoB + n.ii,
    ]
    System(eqs, t, [], pars; name, systems)
end
