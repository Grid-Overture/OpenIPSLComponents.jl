# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/ThreePhaseComponent.mo (partial)
# The three-phase base: the system base S_b (the `outer SystemBase`, a keyword argument as everywhere in the port)
# and the per-phase base S_p = S_b/3, which is what the three-phase source, loads and banks divide their W/var by.
# Children extend this system and take the two with `@unpack S_b, S_p = base`.

@component function ThreePhaseComponent(; name, S_b = 100e6, fn = 50)   # fn: accepted and unused
    S_b = float(S_b)   # F-21
    S_p = S_b / 3
    pars = @parameters begin
        S_b = S_b, [description = "System base (VA)"]
        S_p = S_p, [description = "Phase base (VA)"]
    end
    System(Equation[], t, [], pars; name)
end
