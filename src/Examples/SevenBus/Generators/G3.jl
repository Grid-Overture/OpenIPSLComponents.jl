# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/SevenBus/Generators/G3.mo (extends Electrical/Essentials/pfComponent.mo)
# Generation unit of bus FTDPRA: G1.jl with the GENROU data of this unit redeclared. `extends`-like reuse through the
# `mods` keyword of SevenBus_G1, as Gen2.jl does over Gen1.jl (AUDIT-01 phase 3): the .mo is a full copy of G1 with
# other machine data and nothing else. Named `SevenBus_G3` (JULIA_NAMES).
# Omitted: graphical annotations, displayPF.

@component function SevenBus_G3(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0, M_b)
    @named base = SevenBus_G1(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b,
        mods = (; gENROU = (; Tpd0 = 8.094, Tppd0 = 0.08, Tppq0 = 0.084, H = 5.4, Xq = 2.22,
            Xpd = 0.384, Xl = 0.202, S10 = 0.215, S12 = 0.76968, Xpq = 0.393, Tpq0 = 1.572, Xd = 2.22,
            Xppq = 0.264, Xppd = 0.264, R_a = 0.002796)))
    extend(System(Equation[], t, [], []; name), base)
end
