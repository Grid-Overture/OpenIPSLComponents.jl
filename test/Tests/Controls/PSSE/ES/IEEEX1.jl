# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/IEEEX1.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `IEEEX1` is the exciter (suffix _Test); K_E = 0 selects the automatic K_E0 branch of calculate_dc_exciter_params.
@component function IEEEX1_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        iEEEX1 = IEEEX1(; T_R = 0.04, K_A = 75.0, T_A = 0.05, T_B = 1.0, T_C = 1.0, V_RMAX = 3.9, V_RMIN = -3.9, T_E = 0.5, K_F = 0.07, T_F = 1.0, E_1 = 2.47, S_EE_1 = 0.035, E_2 = 4.5, S_EE_2 = 0.47, K_E = 0.0)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        iEEEX1.EFD ~ gENROE.EFD,   # connect(iEEEX1.EFD, gENROE.EFD)
        iEEEX1.VOTHSG ~ zero.y,   # connect(iEEEX1.VOTHSG, zero.y)
        iEEEX1.EFD0 ~ gENROE.EFD0,   # connect(iEEEX1.EFD0, gENROE.EFD0)
        iEEEX1.ECOMP ~ gENROE.ETERM,   # connect(iEEEX1.ECOMP, gENROE.ETERM)
        iEEEX1.VOEL ~ zero.y,   # connect(iEEEX1.VOEL, zero.y)
        iEEEX1.VUEL ~ zero.y,   # connect(iEEEX1.VUEL, zero.y)
        connect(gENROE.p, GEN1.p),
        gENROE.XADIFD ~ iEEEX1.XADIFD,   # connect(gENROE.XADIFD, iEEEX1.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.IEEEX1" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.IEEEX1.jl"))
    validate_against_oracle(IEEEX1_Test, oracle)
end
