# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/N44/Base_Case/Generators/Gen3_bus_6100.mo
# (extends Electrical/Essentials/pfComponent.mo), drafted automatically
# (2026-09-21, --kind base); reviewed by hand.
# Generation unit of bus 6100 of the Nordic 44 base case: GENSAL + HYGOV + SCRX + STAB2A, rated
# M_b = 1240 MVA on the system's S_b = 1000 MVA, with `cte(k = 0)` on VUEL and VOEL of the SCRX.
# The pin is the subsystem the .mo declares, `p` (OpenIPSL names it `p` in some of these
# eighteen classes and `pwPin` in the others; the system connects the name its own .mo uses).
# The .mo adds no power-flow parameter of its own: V_b, P_0, Q_0, v_0 and angle_0 come from
# `pfComponent` and the system sets them from `PF_results`.
# Omitted: graphical annotations, displayPF.

@component function Gen3_bus_6100(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0,
        v_0 = 1, angle_0 = 0, mods = (;))
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    gENSAL = redeclared(mods, :gENSAL, GENSAL)(; name = :gENSAL, modified(mods, :gENSAL, (; Tppd0 = 0.05,
        Tppq0 = 0.15, D = 0.0, Tpd0 = 9.9, H = 3.0, Xd = 1.2, Xq = 0.73, Xpd = 0.37, Xppd = 0.18, Xppq = 0.18,
        Xl = 0.15, M_b = 1240*1e6, S10 = 0.1, S12 = 0.3, R_a = 0.0, V_b = V_b, v_0 = v_0, angle_0 = angle_0,
        P_0 = P_0, Q_0 = Q_0, S_b, fn))...)
    hYGOV = redeclared(mods, :hYGOV, HYGOV)(; name = :hYGOV, modified(mods, :hYGOV, (; R = 0.06, r = 0.4, VELM = 0.2,
        T_r = 5.0, T_f = 0.05, T_g = 0.2, G_MAX = 1.0, G_MIN = 0.0, T_w = 1.0, A_t = 1.1, D_turb = 0.5,
        q_NL = 0.1))...)
    sCRX = redeclared(mods, :sCRX, SCRX)(; name = :sCRX, modified(mods, :sCRX, (; K = 61.0, T_AT_B = 0.25385,
        T_B = 13.0, T_E = 0.05, E_MIN = 0.0, E_MAX = 4.0, r_cr_fd = 0.0, C_SWITCH = true))...)
    cte = redeclared(mods, :cte, Constant)(; name = :cte, modified(mods, :cte, (; k = 0))...)
    sTAB2A = redeclared(mods, :sTAB2A, STAB2A)(; name = :sTAB2A, modified(mods, :sTAB2A, (; H_LIM = 0.03, K_2 = 1.0,
        T_2 = 4.5, K_3 = 0.0, T_3 = 2.0, K_4 = 0.55, K_5 = 1.0, T_5 = 0.01))...)
    p = redeclared(mods, :p, PwPin)(; name = :p, modified(mods, :p, (; ))...)
    systems = [gENSAL, hYGOV, sCRX, cte, sTAB2A, p]
    eqs = Equation[
        connect(gENSAL.p, p),
        sCRX.EFD ~ gENSAL.EFD,   # connect(sCRX.EFD, gENSAL.EFD)
        sTAB2A.VOTHSG ~ sCRX.VOTHSG,   # connect(sTAB2A.VOTHSG, sCRX.VOTHSG)
        cte.y ~ sCRX.VOEL,   # connect(cte.y, sCRX.VOEL)
        gENSAL.PELEC ~ sTAB2A.PELEC,   # connect(gENSAL.PELEC, sTAB2A.PELEC)
        hYGOV.PMECH ~ gENSAL.PMECH,   # connect(hYGOV.PMECH, gENSAL.PMECH)
        gENSAL.SPEED ~ hYGOV.SPEED,   # connect(gENSAL.SPEED, hYGOV.SPEED)
        gENSAL.PMECH0 ~ hYGOV.PMECH0,   # connect(gENSAL.PMECH0, hYGOV.PMECH0)
        gENSAL.XADIFD ~ sCRX.XADIFD,   # connect(gENSAL.XADIFD, sCRX.XADIFD)
        gENSAL.EFD0 ~ sCRX.EFD0,   # connect(gENSAL.EFD0, sCRX.EFD0)
        gENSAL.ETERM ~ sCRX.ECOMP,   # connect(gENSAL.ETERM, sCRX.ECOMP)
        sCRX.VUEL ~ cte.y,   # connect(sCRX.VUEL, cte.y)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
