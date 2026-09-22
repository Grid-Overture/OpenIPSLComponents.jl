# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Controls/PSSE/OEL/OEL.mo (a Test of this port, not OpenIPSL's: PLAN-12, family C),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The rig of Tests.Controls.PSSE.PSS.IEEEST with the stabilizer removed (eSST1A.VOTHSG tied to zero as VOTHSG2
# already is) and the constant +inf that Test feeds to eSST1A.VOEL replaced by the limiter, which reads
# gENROE.XADIFD. Every parameter is a default of the .mo except `IFDdes`, raised from 1 to 2 pu so that the
# comparator actually switches branch inside the horizon: with the default the field current of this machine sits
# above 1 pu throughout and only one of the four branches is ever taken (F-90). The two branches this Test does
# not reach are covered by test_PSSE_OEL.jl. `OEL` is the model, so the Test function takes the suffix _Test
# (PLAN-02 rule); the Julia name of the model itself is `PSSE_OEL` (rule 6.5).
@component function OEL_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        eSST1A = ESST1A(; V_IMAX = 0.3, V_IMIN = -0.3, T_C = 2.0, T_B = 10.0, T_C1 = 0.08, T_B1 = 0.083, K_A = 300.0, V_AMAX = 7.0, V_AMIN = -7.0, V_RMAX = 5.2, V_RMIN = -5.2, K_C = 0.38, K_F = 1.0, T_F = 1.0, K_LR = 1.0, I_LR = 0.0, T_A = 0.1, T_R = 0.1)
        minusInf = Constant(; k = -Inf)
        oEL = PSSE_OEL(; IFDdes = 2.0)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        eSST1A.ECOMP ~ gENROE.ETERM,   # connect(eSST1A.ECOMP, gENROE.ETERM)
        minusInf.y ~ eSST1A.VUEL2,   # connect(minusInf.y, eSST1A.VUEL2)
        eSST1A.VUEL ~ zero.y,   # connect(eSST1A.VUEL, zero.y)
        eSST1A.VUEL3 ~ eSST1A.VUEL2,   # connect(eSST1A.VUEL3, eSST1A.VUEL2)
        oEL.VOEL ~ eSST1A.VOEL,   # connect(oEL.VOEL, eSST1A.VOEL)
        oEL.IFD ~ gENROE.XADIFD,   # connect(oEL.IFD, gENROE.XADIFD)
        eSST1A.EFD ~ gENROE.EFD,   # connect(eSST1A.EFD, gENROE.EFD)
        eSST1A.VT ~ gENROE.ETERM,   # connect(eSST1A.VT, gENROE.ETERM)
        eSST1A.EFD0 ~ gENROE.EFD0,   # connect(eSST1A.EFD0, gENROE.EFD0)
        eSST1A.VOTHSG ~ zero.y,   # connect(eSST1A.VOTHSG, zero.y)
        eSST1A.VOTHSG2 ~ zero.y,   # connect(eSST1A.VOTHSG2, zero.y)
        connect(gENROE.p, GEN1.p),
        gENROE.XADIFD ~ eSST1A.XADIFD,   # connect(gENROE.XADIFD, eSST1A.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Controls.PSSE.OEL.OEL" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.OEL.OEL.jl"))
    validate_against_oracle(OEL_Test, oracle;
        # F-92: `imLimitedIntegrator` starts exactly AT its own upper limit (y_start = 0 = Vmax) and the fault
        # hands it u = 100, so `der(y) = ifelse(y > outMax and k*u > 0, 0, k*u)` is discontinuous in y at the
        # state's own value. Rodas5P's Rosenbrock Jacobian is meaningless there and its step size collapses at
        # t = 2.10 s (999 982 steps, MaxIters); FBDF, the multistep family OpenModelica's DASSL belongs to,
        # carries the same model through with 834 steps
        alg = FBDF())
end
