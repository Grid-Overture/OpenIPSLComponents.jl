# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Microgrids/UniversityCampus/CampusA/PfData/ (the records `PfBus00000`, `PfLoad00000`,
# `PfMachine00000`, `PfTrafo00000` over their templates, and the collection `Pf00000` inside `PowerFlow`).
# One NamedTuple, so that the text `CampusGridA.jl` transcribes -- `pf.powerflow.bus.V2`, `pf.powerflow.loads.PL1`,
# `pf.powerflow.machines.PG2`, `pf.powerflow.trafos.t1_trafo_1` -- is literal with `pf` a keyword argument of the
# system (the `PF1`/`PF2` precedent). Values exactly as the .mo writes them, products included.
# Named `CampusA_Pf00000` (JULIA_NAMES): `CampusB` has a record of the same name.

const CampusA_Pf00000 = (; powerflow = (;
    bus = (;
        V1 = 1, A1 = 0, V2 = 1.0000683870691, A2 = 0.000110262409124091,
        V3 = 0.999994767002915, A3 = -0.00763493105759082, V4 = 0.999995290017817, A4 = 0.0140136353089708,
        V5 = 0.999995141249226, A5 = 0.00643593252388546, V6 = 0.999988134052338, A6 = -0.0076571649969286,
        V7 = 1, A7 = -0.00763072557882589, V8 = 0.999993335581861, A8 = -0.00765146817597855,
        V9 = 1, A9 = 0.0140321250177743, V10 = 1, A10 = 0.00644844296295463,
        V11 = 0.999997626531425, A11 = -0.0330000223965059, V12 = 1, A12 = -0.0329890262670254,
        V13 = 0.990624532179813, A13 = -0.0795059298487369,
    ),
    loads = (;
        PL1 = 1e06*10.0000000, QL1 = 1e06*5.0000000, PL2 = 1e06*10.0000000, QL2 = 1e06*5.0000000,
        PL3 = 1e06*10.0000000, QL3 = 1e06*5.0000000, PL4 = 1e06*10.0000000, QL4 = 1e06*5.0000000,
        PL5 = 1e06*10.0000000, QL5 = 1e06*5.0000000, PL6 = 1e06*10.0000000, QL6 = 1e06*5.0000000,
        PL7 = 1e06*10.0000000, QL7 = 1e06*5.0000000, PL8 = 1e06*10.0000000, QL8 = 1e06*5.0000000,
        PL9 = 1e06*10.0000000, QL9 = 1e06*5.0000000, PL10 = 1e06*10.0000000, QL10 = 1e06*5.0000000,
        PL11 = 1e06*12.0000000, QL11 = 1e06*3.0000000,
    ),
    machines = (;
        PG1 = 1e06*-0.8932547, QG1 = 1e06*0.2094448, PG2 = 1e06*40.0000000, QG2 = 1e06*16.9621993,
        PG3 = 1e06*30.0000000, QG3 = 1e06*9.7158803, PG4 = 1e06*21.0000000, QG4 = 1e06*9.8645562,
        PG5 = 1e06*22.0000000, QG5 = 1e06*7.7486828,
    ),
    trafos = (;
        t1_trafo_1 = 1.0000000, t2_trafo_1 = 1.0000000, t1_trafo_2 = 1.0000000, t2_trafo_2 = 1.0000000,
        t1_trafo_3 = 1.0000000, t2_trafo_3 = 1.0000000, t1_trafo_4 = 1.0000000, t2_trafo_4 = 1.0000000,
        t1_trafo_5 = 1.0000000, t2_trafo_5 = 1.0000000, t1_trafo_6 = 1.0000000, t2_trafo_6 = 1.0000000,
    ),
))
