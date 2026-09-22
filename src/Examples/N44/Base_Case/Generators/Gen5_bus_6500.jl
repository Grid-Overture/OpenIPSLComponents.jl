# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/N44/Base_Case/Generators/Gen5_bus_6500.mo
# (extends Electrical/Essentials/pfComponent.mo), drafted automatically
# (2026-09-21, --kind base); reviewed by hand.
# Generation unit of bus 6500 of the Nordic 44 base case: GENSAL + HYGOV + SEXS, rated
# M_b = 1100 MVA on the system's S_b = 1000 MVA, with `cte(k = 0)` on VOTHSG, VUEL and VOEL of the SEXS.
# The pin is the subsystem the .mo declares, `p` (OpenIPSL names it `p` in some of these
# eighteen classes and `pwPin` in the others; the system connects the name its own .mo uses).
# The .mo adds no power-flow parameter of its own: V_b, P_0, Q_0, v_0 and angle_0 come from
# `pfComponent` and the system sets them from `PF_results`.
# Omitted: graphical annotations, displayPF.

@component function Gen5_bus_6500(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0,
        v_0 = 1, angle_0 = 0, mods = (;))
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    gENSAL = redeclared(mods, :gENSAL, GENSAL)(; name = :gENSAL, modified(mods, :gENSAL, (; Tppd0 = 0.05,
        Tppq0 = 0.15, D = 0.0, Tpd0 = 5.4855, H = 3.558, Xd = 1.0679, Xq = 0.642, Xpd = 0.23865, Xppd = 0.15802,
        Xppq = 0.15802, Xl = 0.13514, M_b = 1100*1e6, S10 = 0.1, S12 = 0.3, R_a = 0.0, V_b = V_b, v_0 = v_0,
        angle_0 = angle_0, P_0 = P_0, Q_0 = Q_0, S_b, fn))...)
    hYGOV = redeclared(mods, :hYGOV, HYGOV)(; name = :hYGOV, modified(mods, :hYGOV, (; R = 0.06, r = 0.4, VELM = 0.2,
        T_r = 5.0, T_f = 0.05, T_g = 0.2, G_MAX = 1.0, G_MIN = 0.0, T_w = 1.0, A_t = 1.1, D_turb = 0.5,
        q_NL = 0.1))...)
    sEXS = redeclared(mods, :sEXS, SEXS)(; name = :sEXS, modified(mods, :sEXS, (; K = 200.0, T_AT_B = 0.05,
        T_B = 100.0, T_E = 0.5, E_MIN = 0.0, E_MAX = 4.0))...)
    cte = redeclared(mods, :cte, Constant)(; name = :cte, modified(mods, :cte, (; k = 0))...)
    p = redeclared(mods, :p, PwPin)(; name = :p, modified(mods, :p, (; ))...)
    systems = [gENSAL, hYGOV, sEXS, cte, p]
    eqs = Equation[
        hYGOV.PMECH ~ gENSAL.PMECH,   # connect(hYGOV.PMECH, gENSAL.PMECH)
        connect(gENSAL.p, p),
        cte.y ~ sEXS.VOEL,   # connect(cte.y, sEXS.VOEL)
        gENSAL.EFD0 ~ sEXS.EFD0,   # connect(gENSAL.EFD0, sEXS.EFD0)
        gENSAL.SPEED ~ hYGOV.SPEED,   # connect(gENSAL.SPEED, hYGOV.SPEED)
        gENSAL.PMECH0 ~ hYGOV.PMECH0,   # connect(gENSAL.PMECH0, hYGOV.PMECH0)
        sEXS.EFD ~ gENSAL.EFD,   # connect(sEXS.EFD, gENSAL.EFD)
        gENSAL.ETERM ~ sEXS.ECOMP,   # connect(gENSAL.ETERM, sEXS.ECOMP)
        sEXS.VOTHSG ~ cte.y,   # connect(sEXS.VOTHSG, cte.y)
        sEXS.VUEL ~ cte.y,   # connect(sEXS.VUEL, cte.y)
        gENSAL.XADIFD ~ sEXS.XADIFD,   # connect(gENSAL.XADIFD, sEXS.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
