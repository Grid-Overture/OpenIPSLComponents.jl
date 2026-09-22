# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/PSS/PSS2B.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# GENROE + ESST1A (the stabilizer is only visible through the exciter, so the oracle carries `eSST1A.*` too).
# `M = N = 0` puts the ramp-tracking filter in bypass (batch 1) and `T_w4 = T_6 = T_8 = T_9 = T_10 = T_11 = 0`.
@component function PSS2B_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        eSST1A = ESST1A(; V_IMAX = 0.3, V_IMIN = -0.3, T_C = 2.0, T_B = 10.0, T_C1 = 0.08, T_B1 = 0.083, K_A = 300.0, V_AMAX = 7.0, V_AMIN = -7.0, V_RMAX = 5.2, V_RMIN = -5.2, K_C = 0.38, K_F = 1.0, T_F = 1.0, K_LR = 1.0, I_LR = 0.0, T_A = 0.1, T_R = 0.1)
        minusInf = Constant(; k = -OpenIPSLComponents.Modelica.Constants.inf)
        plusInf = Constant(; k = OpenIPSLComponents.Modelica.Constants.inf)
        pSS2B = PSS2B(; K_S1 = 10.0, K_S2 = 0.1564, K_S3 = 1.0, M = 0, N = 0, T_1 = 0.25, T_10 = 0.0, T_11 = 0.0, T_2 = 0.03, T_3 = 0.15, T_4 = 0.015, T_6 = 0.0, T_7 = 2.0, T_8 = 0.0, T_9 = 0.0, T_w1 = 2.0, T_w2 = 2.0, T_w3 = 2.0, T_w4 = 0.0, V_S1MAX = 999.0, V_S1MIN = -999.0, V_S2MAX = 999.0, V_S2MIN = -999.0, V_STMAX = 0.1, V_STMIN = -0.1)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,     # connect(gENROE.PMECH, gENROE.PMECH0)
        eSST1A.ECOMP ~ gENROE.ETERM,      # connect(eSST1A.ECOMP, gENROE.ETERM)
        minusInf.y ~ eSST1A.VUEL2,        # connect(minusInf.y, eSST1A.VUEL2)
        eSST1A.VUEL ~ zero.y,             # connect(eSST1A.VUEL, zero.y)
        eSST1A.VUEL3 ~ eSST1A.VUEL2,      # connect(eSST1A.VUEL3, eSST1A.VUEL2)
        plusInf.y ~ eSST1A.VOEL,          # connect(plusInf.y, eSST1A.VOEL)
        eSST1A.EFD ~ gENROE.EFD,          # connect(eSST1A.EFD, gENROE.EFD)
        eSST1A.EFD0 ~ gENROE.EFD0,        # connect(eSST1A.EFD0, gENROE.EFD0)
        eSST1A.VOTHSG ~ zero.y,           # connect(eSST1A.VOTHSG, zero.y)
        connect(gENROE.p, GEN1.p),
        gENROE.SPEED ~ pSS2B.V_S1,        # connect(gENROE.SPEED, pSS2B.V_S1)
        gENROE.PELEC ~ pSS2B.V_S2,        # connect(gENROE.PELEC, pSS2B.V_S2)
        pSS2B.VOTHSG ~ eSST1A.VOTHSG2,    # connect(pSS2B.VOTHSG, eSST1A.VOTHSG2)
        gENROE.XADIFD ~ eSST1A.XADIFD,    # connect(gENROE.XADIFD, eSST1A.XADIFD)
        eSST1A.VT ~ gENROE.ETERM,         # connect(eSST1A.VT, gENROE.ETERM)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.PSS.PSS2B" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.PSS.PSS2B.jl"))
    validate_against_oracle(PSS2B_Test, oracle)
end
