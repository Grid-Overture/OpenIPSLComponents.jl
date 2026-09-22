# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_3/Generation_Groups/Gen3.mo (extends Gen1.mo)
# 100 MVA / 16.5 kV unit of bus 3: Gen1 with eight machine parameters redeclared, as Gen2.jl.
# Omitted: displayPF, graphical annotations.

@component function Gen3(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        vf0 = 1.755517086537914, vref0 = 1.118023800520641, height, tstart, refdisturb)
    @named base = Gen1(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, vf0, vref0, height, tstart, refdisturb,
        mods = (; gen = (; Vn = 16500.0, xd = 0.1460, xq = 0.0969, x1d = 0.0608, x1q = 0.0969, T1d0 = 8.96,
            T1q0 = 0.310, M = 47.28)))
    extend(System(Equation[], t, [], []; name), base)
end
