# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/ESDC1A.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `ESDC1A` is the exciter (suffix _Test); V_RMAX = 0 and K_E = 0 select both automatic branches. `Modelica.Constants.inf` is 1e60.
@component function ESDC1A_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        minusInf = Constant(; k = -OpenIPSLComponents.Modelica.Constants.inf)
        eSDC1A = ESDC1A(; T_R = 0.04, T_F1 = 1.0, E_1 = 2.47, S_EE_1 = 0.035, E_2 = 4.5, S_EE_2 = 0.47, K_A = 75.0, T_A = 0.05, T_B = 1.0, T_C = 1.0, V_RMIN = -3.9, K_E = 0.0, T_E = 0.5, K_F = 0.07, V_RMAX = 0.0)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        eSDC1A.EFD ~ gENROE.EFD,   # connect(eSDC1A.EFD, gENROE.EFD)
        eSDC1A.EFD0 ~ gENROE.EFD0,   # connect(eSDC1A.EFD0, gENROE.EFD0)
        gENROE.ETERM ~ eSDC1A.ECOMP,   # connect(gENROE.ETERM, eSDC1A.ECOMP)
        eSDC1A.VOTHSG ~ zero.y,   # connect(eSDC1A.VOTHSG, zero.y)
        eSDC1A.VOEL ~ zero.y,   # connect(eSDC1A.VOEL, zero.y)
        connect(gENROE.p, GEN1.p),
        gENROE.XADIFD ~ eSDC1A.XADIFD,   # connect(gENROE.XADIFD, eSDC1A.XADIFD)
        eSDC1A.VUEL ~ minusInf.y,   # connect(eSDC1A.VUEL, minusInf.y)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.ESDC1A" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.ESDC1A.jl"))
    validate_against_oracle(ESDC1A_Test, oracle)
end
