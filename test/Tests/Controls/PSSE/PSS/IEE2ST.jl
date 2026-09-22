# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Controls/PSSE/PSS/IEE2ST.mo (a Test of this port, not OpenIPSL's: PLAN-12, family B),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The rig of Tests.Controls.PSSE.PSS.IEEEST (GENROE + ESST1A, the same three constant sources) with `iEEEST`
# replaced by the dual-input stabilizer: V_S1 <- SPEED, V_S2 <- PELEC, VCT <- ETERM, VOTHSG -> eSST1A.VOTHSG.
# Every parameter is a default of the .mo; V_CU = V_CL = 0 selects the branch that passes VSS with no gating.
# `IEE2ST` is the model, so the Test function takes the suffix _Test (PLAN-02 rule).
@component function IEE2ST_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        eSST1A = ESST1A(; V_IMAX = 0.3, V_IMIN = -0.3, T_C = 2.0, T_B = 10.0, T_C1 = 0.08, T_B1 = 0.083, K_A = 300.0, V_AMAX = 7.0, V_AMIN = -7.0, V_RMAX = 5.2, V_RMIN = -5.2, K_C = 0.38, K_F = 1.0, T_F = 1.0, K_LR = 1.0, I_LR = 0.0, T_A = 0.1, T_R = 0.1)
        minusInf = Constant(; k = -Inf)
        plusInf = Constant(; k = Inf)
        iEE2ST = IEE2ST(; )
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        eSST1A.ECOMP ~ gENROE.ETERM,   # connect(eSST1A.ECOMP, gENROE.ETERM)
        minusInf.y ~ eSST1A.VUEL2,   # connect(minusInf.y, eSST1A.VUEL2)
        eSST1A.VUEL ~ zero.y,   # connect(eSST1A.VUEL, zero.y)
        eSST1A.VUEL3 ~ eSST1A.VUEL2,   # connect(eSST1A.VUEL3, eSST1A.VUEL2)
        plusInf.y ~ eSST1A.VOEL,   # connect(plusInf.y, eSST1A.VOEL)
        eSST1A.EFD ~ gENROE.EFD,   # connect(eSST1A.EFD, gENROE.EFD)
        eSST1A.VT ~ gENROE.ETERM,   # connect(eSST1A.VT, gENROE.ETERM)
        eSST1A.EFD0 ~ gENROE.EFD0,   # connect(eSST1A.EFD0, gENROE.EFD0)
        iEE2ST.V_S1 ~ gENROE.SPEED,   # connect(iEE2ST.V_S1, gENROE.SPEED)
        iEE2ST.V_S2 ~ gENROE.PELEC,   # connect(iEE2ST.V_S2, gENROE.PELEC)
        iEE2ST.VCT ~ gENROE.ETERM,   # connect(iEE2ST.VCT, gENROE.ETERM)
        eSST1A.VOTHSG2 ~ zero.y,   # connect(eSST1A.VOTHSG2, zero.y)
        iEE2ST.VOTHSG ~ eSST1A.VOTHSG,   # connect(iEE2ST.VOTHSG, eSST1A.VOTHSG)
        connect(gENROE.p, GEN1.p),
        gENROE.XADIFD ~ eSST1A.XADIFD,   # connect(gENROE.XADIFD, eSST1A.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Controls.PSSE.PSS.IEE2ST" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.PSS.IEE2ST.jl"))
    validate_against_oracle(IEE2ST_Test, oracle)
end
