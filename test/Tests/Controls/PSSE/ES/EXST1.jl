# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/EXST1.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `EXST1` is the exciter (suffix _Test). rtol = 5e-3 and atol = 5e-4 (F-27's rule, F-42): after the clearing
# OpenModelica holds the saturated branch of the self-referential `if` on EFD for one event window (2.150-2.1546 s,
# PLAN-04), a field pulse the limiter form does not have; the MTK solution is identical at tol 1e-8 and the
# difference (2.7e-3 in EFD at 2.5 s) decays to 2e-5 by 10 s. The atol covers the voltage error signal (DiffV.y and
# its three aliases, |OM| <= 0.024): its absolute deviation (2.8e-4) is the terminal voltage's, which rtol alone
# admits only on the O(1) variables.
@component function EXST1_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        eXST1 = EXST1(; V_IMAX = 10.0, V_IMIN = -10.0, T_R = 0.02, T_B = 1.0, K_A = 80.0, T_A = 0.05, V_RMAX = 8.0, V_RMIN = -3.0, K_C = 0.2, K_F = 0.1, T_F = 1.0, T_C = 0.1)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        eXST1.EFD ~ gENROE.EFD,   # connect(eXST1.EFD, gENROE.EFD)
        eXST1.ECOMP ~ gENROE.ETERM,   # connect(eXST1.ECOMP, gENROE.ETERM)
        zero.y ~ eXST1.VOEL,   # connect(zero.y, eXST1.VOEL)
        eXST1.VOTHSG ~ eXST1.VOEL,   # connect(eXST1.VOTHSG, eXST1.VOEL)
        eXST1.VUEL ~ eXST1.VOEL,   # connect(eXST1.VUEL, eXST1.VOEL)
        eXST1.XADIFD ~ gENROE.XADIFD,   # connect(eXST1.XADIFD, gENROE.XADIFD)
        eXST1.EFD0 ~ gENROE.EFD0,   # connect(eXST1.EFD0, gENROE.EFD0)
        connect(gENROE.p, GEN1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.EXST1" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.EXST1.jl"))
    validate_against_oracle(EXST1_Test, oracle; rtol = 5e-3, atol = 5e-4)
end
