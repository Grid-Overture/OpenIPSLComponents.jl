# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/N44/Base_Case/Generators/Gen4_bus_3359.mo
# (extends Electrical/Essentials/pfComponent.mo), drafted automatically
# (2026-09-21, --kind base); reviewed by hand.
# Generation unit of bus 3359 of the Nordic 44 base case: GENROU + IEESGO + SCRX + STAB2A, rated
# M_b = 1350 MVA on the system's S_b = 1000 MVA, with `cte(k = 0)` on VUEL and VOEL of the SCRX.
# The pin is the subsystem the .mo declares, `pwPin` (OpenIPSL names it `p` in some of these
# eighteen classes and `pwPin` in the others; the system connects the name its own .mo uses).
# The .mo adds no power-flow parameter of its own: V_b, P_0, Q_0, v_0 and angle_0 come from
# `pfComponent` and the system sets them from `PF_results`.
# Omitted: graphical annotations, displayPF.

@component function Gen4_bus_3359(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0,
        v_0 = 1, angle_0 = 0, mods = (;))
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    gENROU = redeclared(mods, :gENROU, GENROU)(; name = :gENROU, modified(mods, :gENROU, (; Tppd0 = 0.05, Tpq0 = 1.0,
        Tppq0 = 0.05, D = 0.0, Tpd0 = 4.75, H = 4.82, Xd = 2.13, Xq = 2.03, Xpd = 0.31, Xpq = 0.403, Xppd = 0.1937,
        Xppq = 0.1937, Xl = 0.14531, M_b = 1350*1e6, S10 = 0.1089, S12 = 0.37795, R_a = 0.0, v_0 = v_0,
        angle_0 = angle_0, P_0 = P_0, Q_0 = Q_0, V_b = V_b, S_b, fn))...)
    iEESGO = redeclared(mods, :iEESGO, IEESGO)(; name = :iEESGO, modified(mods, :iEESGO, (; T_1 = 0.01, T_2 = 0.0,
        T_3 = 0.15, T_4 = 0.3, T_5 = 8.0, T_6 = 0.4, K_1 = 0.0, K_2 = 0.7, K_3 = 0.43, P_MAX = 1.0, P_MIN = 0.0))...)
    sCRX = redeclared(mods, :sCRX, SCRX)(; name = :sCRX, modified(mods, :sCRX, (; K = 165.0, T_AT_B = 0.2,
        T_B = 10.0, T_E = 0.04, E_MIN = 0.0, E_MAX = 5.0, r_cr_fd = 0.0, C_SWITCH = true))...)
    sTAB2A = redeclared(mods, :sTAB2A, STAB2A)(; name = :sTAB2A, modified(mods, :sTAB2A, (; H_LIM = 0.03, K_2 = 1.0,
        T_2 = 4.5, K_3 = 0.0, T_3 = 2.0, K_4 = 0.68, K_5 = 1.0, T_5 = 0.01))...)
    cte = redeclared(mods, :cte, Constant)(; name = :cte, modified(mods, :cte, (; k = 0))...)
    pwPin = redeclared(mods, :pwPin, PwPin)(; name = :pwPin, modified(mods, :pwPin, (; ))...)
    systems = [gENROU, iEESGO, sCRX, sTAB2A, cte, pwPin]
    eqs = Equation[
        connect(gENROU.p, pwPin),
        iEESGO.PMECH ~ gENROU.PMECH,   # connect(iEESGO.PMECH, gENROU.PMECH)
        gENROU.SPEED ~ iEESGO.SPEED,   # connect(gENROU.SPEED, iEESGO.SPEED)
        gENROU.PMECH0 ~ iEESGO.PMECH0,   # connect(gENROU.PMECH0, iEESGO.PMECH0)
        sTAB2A.VOTHSG ~ sCRX.VOTHSG,   # connect(sTAB2A.VOTHSG, sCRX.VOTHSG)
        gENROU.PELEC ~ sTAB2A.PELEC,   # connect(gENROU.PELEC, sTAB2A.PELEC)
        sCRX.EFD ~ gENROU.EFD,   # connect(sCRX.EFD, gENROU.EFD)
        cte.y ~ sCRX.VUEL,   # connect(cte.y, sCRX.VUEL)
        gENROU.XADIFD ~ sCRX.XADIFD,   # connect(gENROU.XADIFD, sCRX.XADIFD)
        gENROU.ETERM ~ sCRX.ECOMP,   # connect(gENROU.ETERM, sCRX.ECOMP)
        gENROU.EFD0 ~ sCRX.EFD0,   # connect(gENROU.EFD0, sCRX.EFD0)
        sCRX.VOEL ~ cte.y,   # connect(sCRX.VOEL, cte.y)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
