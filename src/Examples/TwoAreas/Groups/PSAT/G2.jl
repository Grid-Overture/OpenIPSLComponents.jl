# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/TwoAreas/Groups/PSAT/G2.mo (extends Support/Generator.mo)
# Named `TwoAreas_PSAT_G2` (JULIA_NAMES): the leaf name collides with the PSSE groups of batch 4.
# G1.jl verbatim: the .mo is an exact copy of G1.mo, through its `mods` keyword (AUDIT-01 phase 3).
# Omitted: graphical annotations, displayPF.

@component function TwoAreas_PSAT_G2(; name, S_b = 100e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0)
    @named base = TwoAreas_PSAT_G1(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    extend(System(Equation[], t, [], []; name), base)
end
