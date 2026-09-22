# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/IEEE9/Generation_Groups/Gen2.mo (extends Electrical/Essentials/pfComponent.mo)
# Named `IEEE9_Gen2` (JULIA_NAMES): `Gen2` is the group of Examples.Tutorial.Example_3 (batch 0).
# 13.8 kV / 100 MVA unit of bus 3: Gen1.jl with the Order4 data of this unit redeclared, through the `mods`
# keyword of IEEE9_Gen1, as Gen2.jl does over Gen1.jl (AUDIT-01 phase 3). The .mo is a full copy of Gen1 with other
# machine data and the suffix `_2` on the three disturbance keywords, which this wrapper maps to Gen1's `_1`.
# Omitted: displayPF, graphical annotations.

@component function IEEE9_Gen2(; name, S_b = 100e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        vf0 = 1.359665419632471, vref0 = 1.095179545801796, height_2, tstart_2, refdisturb_2)
    @named base = IEEE9_Gen1(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, vf0, vref0,
        height_1 = height_2, tstart_1 = tstart_2, refdisturb_1 = refdisturb_2,
        mods = (; gen = (; Vn = 13800.0, xd = 1.3125, xq = 1.2578, x1d = 0.1813, x1q = 0.25,
            T1d0 = 5.89, T1q0 = 0.6, M = 6.02)))
    extend(System(Equation[], t, [], []; name), base)
end
