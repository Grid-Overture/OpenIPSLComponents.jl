# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/SevenBus/Generators/G1.mo (extends Electrical/Essentials/pfComponent.mo)
# Generation unit of bus FSSV: GENROU + ST5B + PSS2B + IEESGO, with the pin `pwPin` and the machine rating `M_b`
# (the .mo adds both to pfComponent, as `Examples.TwoAreas.Support.Generator` does). VUEL and VOEL are the constants
# -100 and 100. G2.jl and G3.jl are this unit with other GENROU data and extend it through `mods`.
# Named `SevenBus_G1` (JULIA_NAMES).
# Omitted: graphical annotations, displayPF.

@component function SevenBus_G1(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b, mods = (;))
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    M_b = float(M_b)
    gENROU = redeclared(mods, :gENROU, GENROU)(; name = :gENROU, modified(mods, :gENROU, (; V_b, v_0, angle_0,
        P_0, Q_0, M_b, Tpd0 = 9.627, Tppd0 = 0.058, Tppq0 = 0.06, H = 6.3, D = 0.0, Xq = 2.47, Xpd = 0.3925,
        Xl = 0.211, Xpq = 0.437, Tpq0 = 1.006, S10 = 0.084, S12 = 0.2319, Xd = 2.47, Xppq = 0.289, Xppd = 0.289,
        R_a = 0.00344, S_b, fn))...)
    rest = @named begin
        pwPin = PwPin()
        sT5B = ST5B(; T_R = 0.0, T_C1 = 0.8, T_B1 = 6.0, T_C2 = 0.08, T_B2 = 0.01, K_R = 200.0, V_RMAX = 5.0,
            V_RMIN = -4.0, T_1 = 0.004, K_C = 0.004, T_UC1 = 2.0, T_UB1 = 10.0, T_UC2 = 0.1, T_UB2 = 0.05,
            T_OC1 = 0.1, T_OB1 = 2.0, T_OC2 = 0.08, T_OB2 = 0.08)
        pSS2B = PSS2B(; T_w1 = 2.0, T_w2 = 2.0, T_6 = 0.0, T_w3 = 2.0, T_w4 = 0.0, T_7 = 2.0, K_S2 = 0.1564,
            K_S3 = 1.0, T_8 = 0.0, T_9 = 0.0, K_S1 = 10.0, T_1 = 0.25, T_2 = 0.03, T_3 = 0.15, T_4 = 0.015,
            T_10 = 0.0, T_11 = 0.0, V_S1MAX = 999.0, V_S1MIN = -999.0, V_S2MAX = 999.0, V_S2MIN = -999.0,
            V_STMAX = 0.1, V_STMIN = -0.1, M = 0, N = 0)
        VUEL = Constant(; k = -100)
        VOEL = Constant(; k = 100)
        iEESGO = IEESGO(; T_1 = 0.3, T_2 = 1.0, T_3 = 0.5, T_4 = 0.1, T_5 = 0.25, T_6 = 0.3, K_1 = 15.0, K_2 = 0.3,
            K_3 = 0.5, P_MAX = 1.0, P_MIN = 0.0)
    end
    systems = [gENROU; rest]
    pars = @parameters begin
        M_b = M_b, [description = "Machine base power"]
    end
    eqs = Equation[
        connect(gENROU.p, pwPin),
        gENROU.ETERM ~ sT5B.ECOMP,       # connect(gENROU.ETERM, sT5B.ECOMP)
        sT5B.XADIFD ~ gENROU.XADIFD,     # connect(sT5B.XADIFD, gENROU.XADIFD)
        sT5B.EFD0 ~ gENROU.EFD0,         # connect(sT5B.EFD0, gENROU.EFD0)
        gENROU.SPEED ~ pSS2B.V_S1,       # connect(gENROU.SPEED, pSS2B.V_S1)
        gENROU.PELEC ~ pSS2B.V_S2,       # connect(gENROU.PELEC, pSS2B.V_S2)
        VUEL.y ~ sT5B.VUEL,              # connect(VUEL.y, sT5B.VUEL)
        VOEL.y ~ sT5B.VOEL,              # connect(VOEL.y, sT5B.VOEL)
        pSS2B.VOTHSG ~ sT5B.VOTHSG,      # connect(pSS2B.VOTHSG, sT5B.VOTHSG)
        gENROU.EFD ~ sT5B.EFD,           # connect(gENROU.EFD, sT5B.EFD)
        iEESGO.SPEED ~ gENROU.SPEED,     # connect(iEESGO.SPEED, gENROU.SPEED)
        iEESGO.PMECH0 ~ gENROU.PMECH0,   # connect(iEESGO.PMECH0, gENROU.PMECH0)
        iEESGO.PMECH ~ gENROU.PMECH,     # connect(iEESGO.PMECH, gENROU.PMECH)
    ]
    extend(System(eqs, t, [], pars; name, systems), base)
end
