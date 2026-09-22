# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/N44/Base_Case/Generators/Gen1_bus_7000.mo
# (extends Electrical/Essentials/pfComponent.mo), drafted automatically
# (2026-09-21, --kind base); reviewed by hand.
# Generation unit of bus 7000 of the Nordic 44 base case: GENROU + IEESGO + IEEET2 + STAB2A, rated
# M_b = 1278 MVA on the system's S_b = 1000 MVA, with `cte(k = 0)` on VUEL and VOEL of the IEEET2.
# The pin is the subsystem the .mo declares, `pwPin` (OpenIPSL names it `p` in some of these
# eighteen classes and `pwPin` in the others; the system connects the name its own .mo uses).
# The .mo adds no power-flow parameter of its own: V_b, P_0, Q_0, v_0 and angle_0 come from
# `pfComponent` and the system sets them from `PF_results`.
# Omitted: graphical annotations, displayPF.

@component function Gen1_bus_7000(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0,
        v_0 = 1, angle_0 = 0, mods = (;))
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    gENROU = redeclared(mods, :gENROU, GENROU)(; name = :gENROU, modified(mods, :gENROU, (; Tppd0 = 0.05, Tpq0 = 1.0,
        Tppq0 = 0.05, D = 0.0, Xd = 2.22, Xq = 2.13, Xpd = 0.36, Xpq = 0.468, Xppd = 0.225, Xppq = 0.225,
        Xl = 0.1688, Tpd0 = 10.0, H = 5.5, V_b = V_b, M_b = 1278*1e6, S10 = 0.1089, S12 = 0.378, R_a = 0.0,
        v_0 = v_0, angle_0 = angle_0, P_0 = P_0, Q_0 = Q_0, S_b, fn))...)
    iEESGO = redeclared(mods, :iEESGO, IEESGO)(; name = :iEESGO, modified(mods, :iEESGO, (; T_1 = 0.01, T_2 = 0.0,
        T_3 = 0.15, T_4 = 0.3, T_5 = 8.0, T_6 = 0.4, K_1 = 0.0, K_2 = 0.7, K_3 = 0.43, P_MAX = 1.0, P_MIN = 0.0))...)
    iEEET2 = redeclared(mods, :iEEET2, IEEET2)(; name = :iEEET2, modified(mods, :iEEET2, (; T_R = 0.0, K_A = 800.0,
        T_A = 0.04, V_RMAX = 5.32, V_RMIN = -4.05, K_E = 1.0, T_E = 0.44, K_F = 0.0667, T_F1 = 2.0, T_F2 = 0.44,
        E_1 = 6.5, S_EE_1 = 0.054, E_2 = 8.0, S_EE_2 = 0.2020))...)
    sTAB2A = redeclared(mods, :sTAB2A, STAB2A)(; name = :sTAB2A, modified(mods, :sTAB2A, (; H_LIM = 0.03, K_2 = 1.0,
        T_2 = 1.0, K_3 = 0.0, T_3 = 2.0, K_4 = 0.55, K_5 = 1.0, T_5 = 0.01))...)
    cte = redeclared(mods, :cte, Constant)(; name = :cte, modified(mods, :cte, (; k = 0))...)
    pwPin = redeclared(mods, :pwPin, PwPin)(; name = :pwPin, modified(mods, :pwPin, (; ))...)
    systems = [gENROU, iEESGO, iEEET2, sTAB2A, cte, pwPin]
    eqs = Equation[
        connect(gENROU.p, pwPin),
        iEEET2.EFD ~ gENROU.EFD,   # connect(iEEET2.EFD, gENROU.EFD)
        cte.y ~ iEEET2.VOEL,   # connect(cte.y, iEEET2.VOEL)
        gENROU.EFD0 ~ iEEET2.EFD0,   # connect(gENROU.EFD0, iEEET2.EFD0)
        gENROU.PMECH0 ~ iEESGO.PMECH0,   # connect(gENROU.PMECH0, iEESGO.PMECH0)
        gENROU.PELEC ~ sTAB2A.PELEC,   # connect(gENROU.PELEC, sTAB2A.PELEC)
        sTAB2A.VOTHSG ~ iEEET2.VOTHSG,   # connect(sTAB2A.VOTHSG, iEEET2.VOTHSG)
        gENROU.SPEED ~ iEESGO.SPEED,   # connect(gENROU.SPEED, iEESGO.SPEED)
        gENROU.ETERM ~ iEEET2.ECOMP,   # connect(gENROU.ETERM, iEEET2.ECOMP)
        iEESGO.PMECH ~ gENROU.PMECH,   # connect(iEESGO.PMECH, gENROU.PMECH)
        iEEET2.VUEL ~ cte.y,   # connect(iEEET2.VUEL, cte.y)
        iEEET2.XADIFD ~ gENROU.XADIFD,   # connect(iEEET2.XADIFD, gENROU.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
