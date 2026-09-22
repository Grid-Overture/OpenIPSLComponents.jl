# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/SEXS.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `SEXS` is the exciter (a Test named as its model gets the suffix _Test). Probe of PLAN-04's `missing` parameter
# (`Efd0`) as the start value of the sub-blocks `simpleLagLim` and `leadLag`.
@component function SEXS_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        const2 = Constant(; k = 0)
        gENROU = GENROU(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, Xpp = 0.2, H = 4.28, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        sEXS = SEXS(; T_AT_B = 0.1, T_B = 1.0, K = 100.0, T_E = 0.1, E_MIN = -10.0, E_MAX = 10.0)
        zero = Constant(; k = 0)
    end
    eqs = Equation[
        gENROU.PMECH ~ gENROU.PMECH0,   # connect(gENROU.PMECH, gENROU.PMECH0)
        gENROU.EFD0 ~ sEXS.EFD0,   # connect(gENROU.EFD0, sEXS.EFD0)
        gENROU.ETERM ~ sEXS.ECOMP,   # connect(gENROU.ETERM, sEXS.ECOMP)
        sEXS.VOEL ~ zero.y,   # connect(sEXS.VOEL, zero.y)
        sEXS.VOTHSG ~ zero.y,   # connect(sEXS.VOTHSG, zero.y)
        sEXS.VUEL ~ zero.y,   # connect(sEXS.VUEL, zero.y)
        sEXS.EFD ~ gENROU.EFD,   # connect(sEXS.EFD, gENROU.EFD)
        connect(gENROU.p, GEN1.p),
        gENROU.XADIFD ~ sEXS.XADIFD,   # connect(gENROU.XADIFD, sEXS.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.SEXS" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.SEXS.jl"))
    validate_against_oracle(SEXS_Test, oracle)
end
