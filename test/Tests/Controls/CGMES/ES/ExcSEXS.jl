# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/CGMES/ES/ExcSEXS.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `ExcSEXS` is the exciter (suffix _Test). The .mo names its GENROU instance `gENROE` (sic), kept as is.
@component function ExcSEXS_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        const2 = Constant(; k = 0)
        gENROE = GENROU(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, Xpp = 0.2, H = 4.28, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        sEXS = ExcSEXS(; T_AT_B = 0.1, T_B = 1.0, K = 100.0, T_E = 0.1, E_MIN = -10.0, E_MAX = 10.0, K_C = 0.08, EFD_MAX = 5.0, EFD_MIN = -5.0, T_C = 1.0)
        zero = Constant(; k = 0)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        gENROE.EFD0 ~ sEXS.EFD0,   # connect(gENROE.EFD0, sEXS.EFD0)
        gENROE.ETERM ~ sEXS.ECOMP,   # connect(gENROE.ETERM, sEXS.ECOMP)
        sEXS.VOEL ~ zero.y,   # connect(sEXS.VOEL, zero.y)
        sEXS.VOTHSG ~ zero.y,   # connect(sEXS.VOTHSG, zero.y)
        sEXS.VUEL ~ zero.y,   # connect(sEXS.VUEL, zero.y)
        sEXS.EFD ~ gENROE.EFD,   # connect(sEXS.EFD, gENROE.EFD)
        connect(gENROE.p, GEN1.p),
        gENROE.XADIFD ~ sEXS.XADIFD,   # connect(gENROE.XADIFD, sEXS.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.CGMES.ES.ExcSEXS" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.CGMES.ES.ExcSEXS.jl"))
    validate_against_oracle(ExcSEXS_Test, oracle)
end
