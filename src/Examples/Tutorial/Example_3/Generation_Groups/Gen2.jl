# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_3/Generation_Groups/Gen2.mo (extends Gen1.mo)
# 100 MVA / 13.8 kV unit of bus 2: Gen1 with eight machine parameters redeclared. `extends Gen1(gen(...))` is the
# `mods` keyword of Gen1. Gen2 takes no `mods` of its own: nothing in the port redeclares a component of a Gen2, and
# a Test that does needs the two merged (PLAN-03). Omitted: displayPF, graphical annotations.

@component function Gen2(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        vf0 = 1.755517086537914, vref0 = 1.118023800520641, height, tstart, refdisturb)
    @named base = Gen1(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, vf0, vref0, height, tstart, refdisturb,
        mods = (; gen = (; Vn = 13800.0, xd = 1.3125, xq = 1.2578, x1d = 0.1813, x1q = 0.25, T1d0 = 5.89,
            T1q0 = 0.6, M = 6.02)))
    extend(System(Equation[], t, [], []; name), base)
end
