# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/TG/IEEEG1.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# GENROU + IEEET1, the same machine and exciter as the GAST Test. `IEEEG1` has no PMECH0 input (its parameter `P0`
# is the initial power) and the Test leaves `PMECH_LP` unconnected. `T_7 = 9999` is the Test's own value (sic).
@component function IEEEG1_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROU = GENROU(; Xppd = 0.2, Xppq = 0.2, Xpp = 0.2, Xl = 0.12, Tpd0 = 5.0, Tppd0 = 0.05, Tppq0 = 0.1, H = 4.0, D = 0.0, Xd = 1.41, Xq = 1.35, Xpd = 0.3, S10 = 0.1, S12 = 0.5, Xpq = 0.6, Tpq0 = 0.7, angle_0 = 0.07068583470577, M_b = 100000000.0, P_0 = 39999950.0, Q_0 = 5416571.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        iEEET1 = IEEET1(; T_R = 0.06, K_A = 200.0, T_A = 0.001, T_E = 0.55, K_F = 0.06, E_1 = 2.85, S_EE_1 = 0.3, E_2 = 3.8, S_EE_2 = 0.6, V_RMAX = 2.0, V_RMIN = -2.0, K_E = 0.1)
        iEEEG1 = IEEEG1(; P0 = 0.4, K = 20.0, T_1 = 0.15, T_3 = 0.2, T_4 = 0.25, K_1 = 0.25, T_5 = 7.5, K_3 = 0.25, T_6 = 0.4, K_5 = 0.5, T_7 = 9999.0)
    end
    eqs = Equation[
        iEEET1.EFD ~ gENROU.EFD,          # connect(iEEET1.EFD, gENROU.EFD)
        iEEET1.ECOMP ~ gENROU.ETERM,      # connect(iEEET1.ECOMP, gENROU.ETERM)
        iEEET1.EFD0 ~ gENROU.EFD0,        # connect(iEEET1.EFD0, gENROU.EFD0)
        iEEET1.VOTHSG ~ zero.y,           # connect(iEEET1.VOTHSG, zero.y)
        iEEET1.VOEL ~ zero.y,             # connect(iEEET1.VOEL, zero.y)
        iEEET1.VUEL ~ zero.y,             # connect(iEEET1.VUEL, zero.y)
        connect(gENROU.p, GEN1.p),
        gENROU.XADIFD ~ iEEET1.XADIFD,    # connect(gENROU.XADIFD, iEEET1.XADIFD)
        iEEEG1.PMECH_HP ~ gENROU.PMECH,   # connect(iEEEG1.PMECH_HP, gENROU.PMECH)
        gENROU.SPEED ~ iEEEG1.SPEED_HP,   # connect(gENROU.SPEED, iEEEG1.SPEED_HP)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.TG.IEEEG1" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.TG.IEEEG1.jl"))
    validate_against_oracle(IEEEG1_Test, oracle)
end
