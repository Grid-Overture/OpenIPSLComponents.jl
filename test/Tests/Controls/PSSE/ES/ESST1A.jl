# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/ESST1A.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `ESST1A` is the exciter (suffix _Test). `Modelica.Constants.inf` is OpenModelica's 1e60 (the transcriber wrote Inf).
@component function ESST1A_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        eSST1A = ESST1A(; V_IMAX = 0.3, V_IMIN = -0.3, T_C = 2.0, T_B = 10.0, T_C1 = 0.08, T_B1 = 0.083, K_A = 300.0, V_AMAX = 7.0, V_AMIN = -7.0, V_RMAX = 5.2, V_RMIN = -5.2, K_C = 0.38, K_F = 1.0, T_F = 1.0, K_LR = 1.0, I_LR = 0.0, T_A = 0.1, T_R = 0.1)
        minusInf = Constant(; k = -OpenIPSLComponents.Modelica.Constants.inf)
        plusInf = Constant(; k = OpenIPSLComponents.Modelica.Constants.inf)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        minusInf.y ~ eSST1A.VUEL2,   # connect(minusInf.y, eSST1A.VUEL2)
        plusInf.y ~ eSST1A.VOEL,   # connect(plusInf.y, eSST1A.VOEL)
        eSST1A.EFD ~ gENROE.EFD,   # connect(eSST1A.EFD, gENROE.EFD)
        gENROE.ETERM ~ eSST1A.ECOMP,   # connect(gENROE.ETERM, eSST1A.ECOMP)
        eSST1A.VT ~ eSST1A.ECOMP,   # connect(eSST1A.VT, eSST1A.ECOMP)
        eSST1A.EFD0 ~ gENROE.EFD0,   # connect(eSST1A.EFD0, gENROE.EFD0)
        eSST1A.XADIFD ~ gENROE.XADIFD,   # connect(eSST1A.XADIFD, gENROE.XADIFD)
        connect(gENROE.p, GEN1.p),
        eSST1A.VOTHSG2 ~ zero.y,   # connect(eSST1A.VOTHSG2, zero.y)
        eSST1A.VOTHSG ~ zero.y,   # connect(eSST1A.VOTHSG, zero.y)
        eSST1A.VUEL ~ zero.y,   # connect(eSST1A.VUEL, zero.y)
        minusInf.y ~ eSST1A.VUEL3,   # connect(minusInf.y, eSST1A.VUEL3)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.ESST1A" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.ESST1A.jl"))
    validate_against_oracle(ESST1A_Test, oracle)
end
