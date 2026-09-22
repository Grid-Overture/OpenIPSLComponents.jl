# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/ESDC2A.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `ESDC2A` is the exciter (suffix _Test); VT is fed with ECOMP. `Modelica.Constants.inf` is 1e60.
@component function ESDC2A_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        minusInf = Constant(; k = -OpenIPSLComponents.Modelica.Constants.inf)
        eSDC2A = ESDC2A(; T_R = 0.04, T_F1 = 1.0, E_1 = 2.47, S_EE_1 = 0.035, E_2 = 4.5, S_EE_2 = 0.47, K_A = 75.0, T_A = 0.05, T_B = 1.0, T_C = 1.0, V_RMIN = -3.9, T_E = 0.5, K_F = 0.07, V_RMAX = 0.0, K_E = 0.0)
        zero = Constant(; k = 0)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        eSDC2A.EFD ~ gENROE.EFD,   # connect(eSDC2A.EFD, gENROE.EFD)
        gENROE.ETERM ~ eSDC2A.ECOMP,   # connect(gENROE.ETERM, eSDC2A.ECOMP)
        eSDC2A.VT ~ eSDC2A.ECOMP,   # connect(eSDC2A.VT, eSDC2A.ECOMP)
        eSDC2A.EFD0 ~ gENROE.EFD0,   # connect(eSDC2A.EFD0, gENROE.EFD0)
        minusInf.y ~ eSDC2A.VUEL,   # connect(minusInf.y, eSDC2A.VUEL)
        connect(gENROE.p, GEN1.p),
        gENROE.XADIFD ~ eSDC2A.XADIFD,   # connect(gENROE.XADIFD, eSDC2A.XADIFD)
        zero.y ~ eSDC2A.VOTHSG,   # connect(zero.y, eSDC2A.VOTHSG)
        zero.y ~ eSDC2A.VOEL,   # connect(zero.y, eSDC2A.VOEL)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.ESDC2A" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.ESDC2A.jl"))
    validate_against_oracle(ESDC2A_Test, oracle)
end
