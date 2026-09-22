# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Controls/PSSE/PSS/STAB3.mo (a Test of this port, not OpenIPSL's: PLAN-12, family B),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The rig of the IEE2ST Test with the single-input, power-sensitive stabilizer: PELEC <- gENROE.PELEC,
# VOTHSG -> eSST1A.VOTHSG. Every parameter is a default of the .mo. `STAB3` is the model, so the Test function
# takes the suffix _Test (PLAN-02 rule).
@component function STAB3_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        eSST1A = ESST1A(; V_IMAX = 0.3, V_IMIN = -0.3, T_C = 2.0, T_B = 10.0, T_C1 = 0.08, T_B1 = 0.083, K_A = 300.0, V_AMAX = 7.0, V_AMIN = -7.0, V_RMAX = 5.2, V_RMIN = -5.2, K_C = 0.38, K_F = 1.0, T_F = 1.0, K_LR = 1.0, I_LR = 0.0, T_A = 0.1, T_R = 0.1)
        minusInf = Constant(; k = -Inf)
        plusInf = Constant(; k = Inf)
        sTAB3 = STAB3(; )
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
        sTAB3.PELEC ~ gENROE.PELEC,   # connect(sTAB3.PELEC, gENROE.PELEC)
        eSST1A.VOTHSG2 ~ zero.y,   # connect(eSST1A.VOTHSG2, zero.y)
        sTAB3.VOTHSG ~ eSST1A.VOTHSG,   # connect(sTAB3.VOTHSG, eSST1A.VOTHSG)
        connect(gENROE.p, GEN1.p),
        gENROE.XADIFD ~ eSST1A.XADIFD,   # connect(gENROE.XADIFD, eSST1A.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Controls.PSSE.PSS.STAB3" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.PSS.STAB3.jl"))
    validate_against_oracle(STAB3_Test, oracle)
end
