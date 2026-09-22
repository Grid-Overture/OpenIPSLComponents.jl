# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/PSS/IEEEST.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# GENROE + ESST1A, the same rig as the PSS2B Test but with the stabilizer on `VOTHSG` (and `VOTHSG2` to `zero`).
# `V_S <- PELEC`, `V_CT <- ETERM`; `V_CU = V_CL = 0` selects the branch that passes `Vs` with no gating, and
# A_3 = A_4 = 0 puts the second filter in bypass (n2 = 4).
@component function IEEEST_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        eSST1A = ESST1A(; V_IMAX = 0.3, V_IMIN = -0.3, T_C = 2.0, T_B = 10.0, T_C1 = 0.08, T_B1 = 0.083, K_A = 300.0, V_AMAX = 7.0, V_AMIN = -7.0, V_RMAX = 5.2, V_RMIN = -5.2, K_C = 0.38, K_F = 1.0, T_F = 1.0, K_LR = 1.0, I_LR = 0.0, T_A = 0.1, T_R = 0.1)
        minusInf = Constant(; k = -OpenIPSLComponents.Modelica.Constants.inf)
        plusInf = Constant(; k = OpenIPSLComponents.Modelica.Constants.inf)
        iEEEST = IEEEST(; A_1 = 48.7435, A_2 = 4.7488, A_3 = 0.0, A_4 = 0.0, A_5 = -85.7761, A_6 = 0.0459, T_1 = 0.7361, T_2 = 1.5868, T_3 = 0.0, T_4 = 0.02, T_5 = 13.8921, T_6 = 0.1057, K_S = 0.0099, L_SMAX = 0.1, L_SMIN = -0.1, V_CU = 0.0, V_CL = 0.0)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,     # connect(gENROE.PMECH, gENROE.PMECH0)
        eSST1A.ECOMP ~ gENROE.ETERM,      # connect(eSST1A.ECOMP, gENROE.ETERM)
        minusInf.y ~ eSST1A.VUEL2,        # connect(minusInf.y, eSST1A.VUEL2)
        eSST1A.VUEL ~ zero.y,             # connect(eSST1A.VUEL, zero.y)
        eSST1A.VUEL3 ~ eSST1A.VUEL2,      # connect(eSST1A.VUEL3, eSST1A.VUEL2)
        plusInf.y ~ eSST1A.VOEL,          # connect(plusInf.y, eSST1A.VOEL)
        eSST1A.EFD ~ gENROE.EFD,          # connect(eSST1A.EFD, gENROE.EFD)
        eSST1A.VT ~ gENROE.ETERM,         # connect(eSST1A.VT, gENROE.ETERM)
        eSST1A.EFD0 ~ gENROE.EFD0,        # connect(eSST1A.EFD0, gENROE.EFD0)
        iEEEST.V_CT ~ gENROE.ETERM,       # connect(iEEEST.V_CT, gENROE.ETERM)
        iEEEST.V_S ~ gENROE.PELEC,        # connect(iEEEST.V_S, gENROE.PELEC)
        eSST1A.VOTHSG2 ~ zero.y,          # connect(eSST1A.VOTHSG2, zero.y)
        iEEEST.VOTHSG ~ eSST1A.VOTHSG,    # connect(iEEEST.VOTHSG, eSST1A.VOTHSG)
        connect(gENROE.p, GEN1.p),
        gENROE.XADIFD ~ eSST1A.XADIFD,    # connect(gENROE.XADIFD, eSST1A.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.PSS.IEEEST" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.PSS.IEEEST.jl"))
    validate_against_oracle(IEEEST_Test, oracle)
end
