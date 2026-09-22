# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/SevenBus/Data.mo (the package of records `SevenBus_voltages`, `SevenBus_loads`,
# `SevenBus_machines`, `SevenBus_trafos` and the collection `PF_results`).
# The four sub-records and their collection are one NamedTuple: `Network.jl` reads `PF_results.voltages.V21`,
# `PF_results.machines.P21_1`, `PF_results.loads.PL3_1` and `PF_results.trafos.t2_2_21` exactly as the .mo does.
# Values as in the .mo (pu, rad, W, var, tap ratios). Named `SevenBus_PF_results` (JULIA_NAMES).

const SevenBus_PF_results = (;
    voltages = (;
        V1 = 1.06959, A1 = 0.00030194196,
        V2 = 1.0696, A2 = 0.00163188285,
        V3 = 1.06958, A3 = -0.00006108652,
        V4 = 1.06959, A4 = -0.00030368728,
        V5 = 1.06957, A5 = 0.00005934119,
        V6 = 1.0696, A6 = 0.00054279739,
        V7 = 1.0696, A7 = 0.0,
        V71 = 0.9803, A71 = -0.00001745329,
        V21 = 0.98988, A21 = 0.1275678429,
        V61 = 1.00595, A61 = 0.04456523712),
    loads = (;
        PL3_1 = 240000015.0, QL3_1 = 2400000.0,
        PL5_1 = 480000031.0, QL5_1 = 4800000.0,
        PL4_1 = 480000031.0, QL4_1 = 4800000.0,
        PL1_1 = 240000015.0, QL1_1 = 2400000.0),
    machines = (;
        P21_1 = 962199951.0, Q21_1 = 124763000.0,
        P71_1 = 0.0, Q71_1 = 7038000.0,
        P61_1 = 480428040.0, Q61_1 = 27608999.0),
    trafos = (;
        t1_1_4 = 1.0, t2_1_4 = 1.0,
        t1_7_71 = 1.0, t2_7_71 = 1.09211,
        t1_6_61 = 1.0, t2_6_61 = 1.06579,
        t1_2_21 = 1.0, t2_2_21 = 1.09211),
)
