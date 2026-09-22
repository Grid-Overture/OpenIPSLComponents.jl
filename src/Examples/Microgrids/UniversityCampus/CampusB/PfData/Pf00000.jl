# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Microgrids/UniversityCampus/CampusB/PfData/ (the records `PfBus00000`, `PfLoad00000`,
# `PfMachine00000`, `PfTrafo00000` over their templates, and the collection `Pf00000`).
# One NamedTuple, so that `CampusGridB.jl`'s transcribed `pf.powerflow.bus.V1` is literal (the `PF1`/`PF2`
# precedent). Named `CampusB_Pf00000` (JULIA_NAMES): `CampusA` has a record of the same name.

const CampusB_Pf00000 = (; powerflow = (;
    bus = (;
        VB1L1 = 0.9960279, AB1L1 = 0.425989, VB2L1 = 0.9960279, AB2L1 = 0.425989,
        VB1L2 = 1.00093, AB1L2 = 1.82279, VB2L2 = 0.9999925, AB2L2 = 0.247211,
        VB3L2 = 0.9960279, AB3L2 = 0.425989, VB1L3 = 1.0000, AB1L3 = 0.0000,
        VB1L4 = 0.992577, AB1L4 = 0.0444074, VB2L4 = 0.992577, AB2L4 = 0.0444074,
        VB3L4 = 0.992577, AB3L4 = 0.0444074, VB1L5 = 0.9912935, AB1L5 = 0.070656,
        VB2L5 = 0.9920305, AB2L5 = 0.0546208, VB3L5 = 0.9921045, AB3L5 = 0.0482479,
        VB4L5 = 0.989964, AB4L5 = 0.113864, VB5L5 = 0.9893169, AB5L5 = 0.13374,
        VB6L5 = 0.9688569, AB6L5 = 0.441645, VB1L6 = 0.9912949, AB1L6 = 0.0520638,
        VB1L7 = 0.9895068, AB1L7 = 0.090479, VB2L7 = 0.9912695, AB2L7 = 0.069,
        VB1L8 = 0.9897282, AB1L8 = 0.101351, VB2L8 = 0.9908705, AB2L8 = 0.0642161,
        VB1L9 = 0.9892222, AB1L9 = 0.114896, VB2L9 = 0.9896949, AB2L9 = 0.0986142,
        VPV1B1 = 0.9895245, APV1B1 = 0.8042775, VPV1B2 = 0.9894509, APV1B2 = 0.7939371,
        VPV2B1 = 0.9896978, APV2B1 = 0.7665736, VPV2B2 = 0.9896949, APV2B2 = 0.7662135,
        VPV3B1 = 0.9688582, APV3B1 = 1.474061, VPV3B2 = 0.9688582, APV3B2 = 1.474061,
        VPV4B1 = 0.9913135, APV4B1 = 0.7200715, VPV4B2 = 0.9913135, APV4B2 = 0.7200715,
        VPV5B1 = 0.9894778, APV5B1 = 0.8212546, VPV5B2 = 0.9894778, APV5B2 = 0.8212546,
    ),
    loads = (;
        PL1 = 0.8180e6, QL1 = 0.3880e6, PL2 = 0.2660e6, QL2 = 0.1010e6,
        PL3 = 1.2900e6, QL3 = 0.6020e6, PL4 = 2.1700e6, QL4 = 1.1200e6,
        PL5 = 1.6770e6, QL5 = 0.9670e6, PL6 = 0.3050e6, QL6 = 0.1670e6,
        PL7 = 0.3400e6, QL7 = 0.1000e6, PL8 = 0.3810e6, QL8 = 0.1440e6,
        PL9 = 0.6100e6, QL9 = 0.3380e6, PL10 = 0.5090e6, QL10 = 0.2850e6,
    ),
    machines = (;
        PG1 = 35111.4, QG1 = 11.756e6, PG2 = 2e6, QG2 = -8e6,
        PG3 = 2e6, QG3 = 1.4050e6, PG4 = 0.5e6, QG4 = -0.9430001e6,
        PVP1 = 0.31e6, PVQ1 = 0.1279e6, PVP2 = 0.0108e6, PVQ2 = 0.0051e6,
        PVP3 = 0.007e6, PVQ3 = 0.0024e6, PVP4 = 0.009e6, PVQ4 = 0.0323e6,
        PVP5 = 0.6e6, PVQ5 = 0.2793e6,
    ),
    trafos = (;
        t1_trafo_1 = 1.0000000, t2_trafo_1 = 1.0000000, t1_trafo_2 = 1.0000000, t2_trafo_2 = 1.0000000,
        t1_trafo_3 = 1.0000000, t2_trafo_3 = 1.0000000, t1_trafo_4 = 1.0000000, t2_trafo_4 = 1.0000000,
        t1_trafo_5 = 1.0000000, t2_trafo_5 = 1.0000000, t1_trafo_6 = 1.0000000, t2_trafo_6 = 1.0000000,
    ),
))
