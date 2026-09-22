# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Microgrids/UniversityCampus/CampusB/GeneratorGroups/DynParamRecords.mo
# The two unit records `GT` and `ST`, each a `machine` + `excSystem` + `tg` over their templates (CampusB keeps them
# all in one .mo, unlike CampusA). One NamedTuple per unit with the sub-records in line, so that the transcribed
# text `gUData.guDynamics.machine.Tpd0` is literal.
# `Xpp = Xppd` in both machines, as the .mo writes it.
# Named `CampusB_GT` / `CampusB_ST` (JULIA_NAMES): `GT` and `ST` are packages in the .mo.

const CampusB_GT = (;
    machine = (;
        M_b = 16667000, Tpd0 = 4.822, Tppd0 = 0.023, Tppq0 = 0.065, H = 8.75,
        D = 2, Xd = 1.897, Xq = 1.78, Xpd = 0.23, Xppd = 0.156,
        Xppq = 0.156, Xl = 0.123, S10 = 0.12, S12 = 0.4, R_a = 0.01,
        Xpq = 0.4610, Tpq0 = 0.391, Xpp = 0.156,   # `Xpp = Xppd` in the .mo
    ),
    excSystem = (;
        T_R = 0, T_B = 0, T_C = 0, K_A = 150, T_A = 0.02,
        V_RMAX = 20, V_RMIN = -20, T_E = 0.5, K_F = 0.0045, T_F = 0.1,
        K_C = 0.1, K_D = 1, K_E = 1, E_1 = 4.20, E_2 = 5.6,
        S_EE_1 = 0.1827, S_EE_2 = 0.2558,
    ),
    tg = (;
        R = 0.05, T_1 = 0.4, T_2 = 0.1, T_3 = 3.0, AT = 0.9,
        K_T = 2.0, V_MAX = 1.0, V_MIN = -0.05, D_turb = 0.0,
    ),
)

const CampusB_ST = (;
    machine = (;
        M_b = 4475000, Tpd0 = 7, Tppd0 = 0.03, Tppq0 = 0.05, H = 3,
        D = 0, Xd = 2.1, Xq = 2, Xpd = 0.2, Xppd = 0.18,
        Xppq = 0.18, Xl = 0.15, S10 = 0.05, S12 = 0.3, R_a = 0.01,
        Xpq = 0.5, Tpq0 = 0.75, Xpp = 0.18,   # `Xpp = Xppd` in the .mo
    ),
    excSystem = (;
        T_R = 0.02, V_IMAX = 1, V_IMIN = -1, T_C = 1, T_B = 10,
        K_A = 200, T_A = 0.05, V_RMAX = 5, V_RMIN = -4, K_C = 0.04,
        K_F = 0.02, T_F = 1,
    ),
    tg = (;
        R = 0.05, D_t = 0, T_1 = 0.49, T_2 = 2.1, T_3 = 7,
        V_MAX = 1, V_MIN = 0,
    ),
)
