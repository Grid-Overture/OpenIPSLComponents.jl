# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/SevenBus/Generators/G2.mo (extends Electrical/Essentials/pfComponent.mo)
# Generation unit of bus FVALDI: G1.jl with the GENROU data of this unit redeclared. `extends`-like reuse through the
# `mods` keyword of SevenBus_G1, as Gen2.jl does over Gen1.jl (AUDIT-01 phase 3): the .mo is a full copy of G1 with
# other machine data and nothing else. Named `SevenBus_G2` (JULIA_NAMES).
# Omitted: graphical annotations, displayPF.

@component function SevenBus_G2(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0, M_b)
    @named base = SevenBus_G1(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b,
        mods = (; gENROU = (; Tpd0 = 10.041, Tppd0 = 0.065, Tppq0 = 0.094, H = 5.112, Xq = 2.72,
            Xpd = 0.527, Xl = 0.265, S10 = 0.05, S12 = 0.27175, Xpq = 0.623, Tpq0 = 1.22, Xd = 2.91,
            Xppq = 0.367, Xppd = 0.367, R_a = 0.003275)))
    extend(System(Equation[], t, [], []; name), base)
end
