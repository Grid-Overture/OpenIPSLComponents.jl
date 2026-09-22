# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/ST5B.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `ST5B` is the exciter (suffix _Test); the Constant instances VOEL/VUEL are named as the ports they feed (sic).
@component function ST5B_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        sT5B = ST5B(; T_R = 0.0, T_C1 = 0.8, T_B1 = 6.0, T_C2 = 0.08, T_B2 = 0.01, T_UC1 = 2.0, T_UB1 = 10.0, T_UC2 = 0.1, T_UB2 = 0.05, T_OC1 = 0.1, T_OB1 = 2.0, T_OC2 = 0.08, T_OB2 = 0.08, K_C = 0.004, T_1 = 0.001, K_R = 200.0, V_RMAX = 5.0, V_RMIN = -4.0)
        PSS_off = Constant(; k = 0)
        VOEL = Constant(; k = 100)
        VUEL = Constant(; k = -100)
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
    end
    eqs = Equation[
        PSS_off.y ~ sT5B.VOTHSG,   # connect(PSS_off.y, sT5B.VOTHSG)
        VOEL.y ~ sT5B.VOEL,   # connect(VOEL.y, sT5B.VOEL)
        VUEL.y ~ sT5B.VUEL,   # connect(VUEL.y, sT5B.VUEL)
        gENROE.ETERM ~ sT5B.ECOMP,   # connect(gENROE.ETERM, sT5B.ECOMP)
        sT5B.XADIFD ~ gENROE.XADIFD,   # connect(sT5B.XADIFD, gENROE.XADIFD)
        sT5B.EFD0 ~ gENROE.EFD0,   # connect(sT5B.EFD0, gENROE.EFD0)
        sT5B.EFD ~ gENROE.EFD,   # connect(sT5B.EFD, gENROE.EFD)
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        connect(gENROE.p, GEN1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.ST5B" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.ST5B.jl"))
    validate_against_oracle(ST5B_Test, oracle)
end
