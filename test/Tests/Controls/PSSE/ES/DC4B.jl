# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/DC4B.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `DC4B` is the exciter (suffix _Test); `const` is the instance `const_`. Experiment: tol 1e-5, interval 1e-4 (oracle).
@component function DC4B_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROU = GENROU(; P_0 = 40000000.0, Q_0 = 5415812.0, angle_0 = 0.070619983433093, M_b = 100000000.0, Tpd0 = 5.5, Tppd0 = 0.035, Tppq0 = 0.07, H = 2.71, D = 0.0, Xd = 1.9, Xq = 1.8, Xpd = 0.27, Xppd = 0.15, Xppq = 0.15, Xl = 0.101, S10 = 0.11, S12 = 0.48, Xpq = 0.6, Tpq0 = 0.75, S_b, fn)
        dC4B = DC4B(; T_R = 0.01, K_PR = 40.0, K_IR = 14.0, K_DR = 15.0, T_DR = 0.01, V_RMAX = 10.9, V_RMIN = 0.0, K_A = 0.15, K_E = 1.0, T_E = 1.0, K_F = 0.0, E_1 = 1.5, S_EE_1 = 0.03, E_2 = 3.0, S_EE_2 = 1.2, UEL = 1, OEL = 1)
        const_ = Constant(; k = 0)
    end
    eqs = Equation[
        connect(gENROU.p, GEN1.p),
        gENROU.PMECH0 ~ gENROU.PMECH,   # connect(gENROU.PMECH0, gENROU.PMECH)
        dC4B.EFD ~ gENROU.EFD,   # connect(dC4B.EFD, gENROU.EFD)
        gENROU.XADIFD ~ dC4B.XADIFD,   # connect(gENROU.XADIFD, dC4B.XADIFD)
        const_.y ~ dC4B.VOTHSG,   # connect(const.y, dC4B.VOTHSG)
        dC4B.VUEL ~ dC4B.VOTHSG,   # connect(dC4B.VUEL, dC4B.VOTHSG)
        dC4B.VOEL ~ dC4B.VOTHSG,   # connect(dC4B.VOEL, dC4B.VOTHSG)
        gENROU.ETERM ~ dC4B.ECOMP,   # connect(gENROU.ETERM, dC4B.ECOMP)
        dC4B.VT ~ gENROU.ETERM,   # connect(dC4B.VT, gENROU.ETERM)
        gENROU.EFD0 ~ dC4B.EFD0,   # connect(gENROU.EFD0, dC4B.EFD0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.DC4B" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.DC4B.jl"))
    validate_against_oracle(DC4B_Test, oracle)
end
