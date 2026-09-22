# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/IEEE9/Generation_Groups/Gen3.mo (extends Electrical/Essentials/pfComponent.mo)
# Named `IEEE9_Gen3` (JULIA_NAMES): `Gen3` is the group of Examples.Tutorial.Example_3 (batch 0).
# 16.5 kV / 100 MVA unit of bus 1: Gen1.jl with the Order4 data of this unit redeclared, through the `mods`
# keyword of IEEE9_Gen1, as Gen2.jl does over Gen1.jl (AUDIT-01 phase 3). The .mo is a full copy of Gen1 with other
# machine data and the suffix `_3` on the three disturbance keywords, which this wrapper maps to Gen1's `_1`.
# Omitted: displayPF, graphical annotations.

@component function IEEE9_Gen3(; name, S_b = 100e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        vf0 = 1.079018784709528, vref0 = 1.095077501312303, height_3, tstart_3, refdisturb_3)
    @named base = IEEE9_Gen1(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, vf0, vref0,
        height_1 = height_3, tstart_1 = tstart_3, refdisturb_1 = refdisturb_3,
        mods = (; gen = (; Vn = 16500.0, xd = 0.1460, xq = 0.0969, x1d = 0.0608, x1q = 0.0969,
            T1d0 = 8.96, T1q0 = 0.310, M = 47.28)))
    extend(System(Equation[], t, [], []; name), base)
end
