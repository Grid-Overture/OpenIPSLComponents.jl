# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Microgrids/UniversityCampus/CampusA/GenerationGroups/DynParamRecords/
# The four unit records `CTG1`, `CTG2`, `STG1`, `STG2`, each a `machine` + `excSystem` + `pss` + `tg` over their
# templates. One NamedTuple per unit with the sub-records **in line** as fields, because nothing else reads them,
# so that the unit's transcribed text `guData.guDynamics.machine.Tpd0` is literal.
# The `pss` field of every unit is `PSSData.PSS2BND`: **dead data**, because all four units instantiate
# `DisabledPSS`. It is not ported (`PLAN-07`, decision "CampusGridA / CampusGridB").
# Named `CampusA_CTG1` ... `CampusA_STG2` (JULIA_NAMES): `GUnitTest.CTG1` and friends are systems with the same
# short names.

const CampusA_CTG1 = (;
    machine = (;
        M_b = 53900000, Tpd0 = 6.01, Tppd0 = 0.06, Tppq0 = 0.098, H = 1.5,
        D = 0, Xd = 2.328, Xq = 2.26, Xpd = 0.267, Xppd = 0.185,
        Xppq = 0.185, Xl = 0.16, S10 = 0.1210, S12 = 0.4210, R_a = 0,
        Xpq = 0.58, Tpq0 = 0.67,
        Xpp = 0.185,   # `Xpp = Xppd` in the .mo
    ),
    excSystem = (;
        T_R = 0, K_PR = 40, K_IR = 9.2, V_RMAX = 4.5, V_RMIN = -4.03,
        T_A = 0.02, K_PM = 1, K_IM = 0, V_MMAX = 4.5, V_MMIN = -4.03,
        K_G = 0, K_P = 1, K_I = 0, V_BMAX = 1.25, K_C = 0.094,
        X_L = 0, THETAP = 0,
    ),
    tg = (;
        R = 25, T_1 = 0.5, T_2 = 0.7, T_3 = 0.0001, AT = 10,
        K_T = 0, V_MAX = 1.3, V_MIN = 0.2, D_turb = 0,
    ),
)

const CampusA_CTG2 = (;
    machine = (;
        M_b = 40470000, Tpd0 = 8.3, Tppd0 = 0.05, Tppq0 = 0.05, H = 1.486,
        D = 0, Xd = 2.34, Xq = 2.14, Xpd = 0.293, Xppd = 0.206,
        Xppq = 0.206, Xl = 0.133, S10 = 1.08, S12 = 1.770, R_a = 0,
        Xpq = 0.35, Tpq0 = 2.5,
        Xpp = 0.206,   # `Xpp = Xppd` in the .mo
    ),
    excSystem = (;
        T_R = 0, K_PR = 21.6006, K_IR = 21.6006, K_DR = 0, T_DR = 0,
        K_PA = 1.29588, K_IA = 1.29588, V_AMIN = -1, V_AMAX = 1, K_P = 38.7527,
        T_E = 1.2, V_FEMAX = 20, K_L = 1, K_F1 = 0, K_F2 = 0.60784,
        K_F3 = 0, T_F3 = 1, K_C = 0.83, K_D = 2.290, K_E = 1,
        E_1 = 8.7, E_2 = 11.6, S_EE_1 = 0.41, S_EE_2 = 4.01, V_RMAX = 9.712,
        V_RMIN = 0, V_EMIN = 0,
    ),
    tg = (;
        R = 20.00, T_1 = 0.2, T_2 = 0.3, T_3 = 0.0001, AT = 10,
        K_T = 0, V_MAX = 1.05, V_MIN = 0.2, D_turb = 0,
    ),
)

const CampusA_STG1 = (;
    machine = (;
        M_b = 32e6, Tpd0 = 3.42, Tppd0 = 0.034, Tppq0 = 0.086, H = 2.43,
        D = 0, Xd = 1.819, Xq = 1.747, Xpd = 0.3, Xppd = 0.205,
        Xppq = 0.205, Xl = 0.165, S10 = 0.107, S12 = 0.451, R_a = 0,
        Xpq = 0.574, Tpq0 = 0.32,
        Xpp = 0.205,   # `Xpp = Xppd` in the .mo
    ),
    excSystem = (;
        T_R = 0.01, V_IMAX = 99, V_IMIN = -99, T_C = 1, T_B = 1,
        T_C1 = 0, T_B1 = 0, K_A = 240, T_A = 0.01, V_AMAX = 99,
        V_AMIN = -99, V_RMAX = 4.5, V_RMIN = -4.5, K_C = 0.03, K_F = 0.05,
        T_F = 0.7, K_LR = 0, I_LR = 0, K_P = 0.7, K_I = 1,
        K_E = 1, T_E = 0.5, EFD_MAX = 5,
    ),
    tg = (;
        R = 0.05, D_t = 0, T_1 = 0.2, T_2 = 0.001, T_3 = 0.3,
        V_MAX = 1, V_MIN = 0.3,
    ),
)

const CampusA_STG2 = (;
    machine = (;
        M_b = 32000000, Tpd0 = 6.124, Tppd0 = 0.047, Tppq0 = 0.086, H = 2.43,
        D = 0, Xd = 2.1, Xq = 1.9, Xpd = 0.217, Xppd = 0.155,
        Xppq = 0.155, Xl = 0.099, S10 = 0.153, S12 = 0.899, R_a = 0,
        Xpq = 0.574, Tpq0 = 0.32,
        Xpp = 0.155,   # `Xpp = Xppd` in the .mo
    ),
    excSystem = (;
        T_R = 0, K_PR = 7.39, K_IR = 14.785, K_DR = 0, T_DR = 0,
        K_PA = 4.00, K_IA = 20.00, V_AMIN = -8.15, V_AMAX = 8.15, K_P = 1.0,
        T_E = 1.1, V_FEMAX = 999, K_L = 999, K_F1 = 0, K_F2 = 1.0,
        K_F3 = 0, T_F3 = 1, K_C = 0, K_D = 0, K_E = 0.5,
        E_1 = 3.5100, E_2 = 4.680, S_EE_1 = 0.10000E-01, S_EE_2 = 0.50000E-01, V_RMAX = 1.4,
        V_RMIN = 0, V_EMIN = -999,
    ),
    tg = (;
        R = 0.05, D_t = 0, T_1 = 0.2, T_2 = 0.001, T_3 = 0.3,
        V_MAX = 1, V_MIN = 0.3,
    ),
)
