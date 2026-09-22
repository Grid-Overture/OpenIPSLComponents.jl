# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/EXAC2.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `EXAC2` is the exciter (suffix _Test).
@component function EXAC2_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        eXAC2 = EXAC2(; K_B = 2.0, K_H = 2.0, K_A = 400.0, T_A = 0.02, V_AMAX = 9.0, V_AMIN = -5.34, T_E = 0.8, K_F = 0.03, T_F = 1.0, K_C = 0.2, K_D = 0.48, K_E = 1.0, E_1 = 5.25, E_2 = 7.0, S_EE_1 = 0.03, S_EE_2 = 0.1, T_R = 0.005, T_B = 0.005, T_C = 0.005, V_RMAX = 4.0, V_RMIN = -4.0, K_L = 1.0, V_LR = 10.0)
        zero = Constant(; k = 0)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        gENROE.EFD0 ~ eXAC2.EFD0,   # connect(gENROE.EFD0, eXAC2.EFD0)
        gENROE.XADIFD ~ eXAC2.XADIFD,   # connect(gENROE.XADIFD, eXAC2.XADIFD)
        gENROE.ETERM ~ eXAC2.ECOMP,   # connect(gENROE.ETERM, eXAC2.ECOMP)
        eXAC2.EFD ~ gENROE.EFD,   # connect(eXAC2.EFD, gENROE.EFD)
        connect(gENROE.p, GEN1.p),
        eXAC2.VUEL ~ zero.y,   # connect(eXAC2.VUEL, zero.y)
        eXAC2.VOEL ~ zero.y,   # connect(eXAC2.VOEL, zero.y)
        zero.y ~ eXAC2.VOTHSG,   # connect(zero.y, eXAC2.VOTHSG)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.EXAC2" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.EXAC2.jl"))
    validate_against_oracle(EXAC2_Test, oracle)
end
