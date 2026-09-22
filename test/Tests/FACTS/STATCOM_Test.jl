# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/FACTS/STATCOM_Test.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# `busSC(v_0 = sTATCOM.v_0)` is transcribed with the literal 0.999989. The load steps +10 Mvar from 2 to 4 s and
# -10 Mvar from 6 to 8 s, which is what moves the STATCOM.
@component function STATCOM_Test(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        sTATCOM = STATCOM(; Q_0 = 524550.0, v_0 = 0.999989, Sn = 20000000.0, Kr = 25.0, Tr = 0.2, i_Max = 0.7,
            i_Min = -0.7, S_b, fn)
        Syn1 = GENCLS(; S_b, fn)
        pwLineSC = PwLine(; R = 0.0001, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        lOADPQ = PQvar(; P_0 = 20000000.0, Q_0 = 0.0, t_start_1 = 2.0, t_end_1 = 4.0, dP1 = 0.0, dQ1 = 10000000.0,
            t_start_2 = 6.0, t_end_2 = 8.0, dP2 = 0.0, dQ2 = -10000000.0, S_b, fn)
        pwLineLoad = PwLine(; R = 0.001, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        pwLineInf = PwLine(; R = 0.001, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        busInf = Bus(; S_b, fn)
        busSplit = Bus(; S_b, fn)
        busSC = Bus(; v_0 = 0.999989, S_b, fn)
        busLoad = Bus(; S_b, fn)
        NoPSS = Constant(; k = 0.0)
    end
    eqs = Equation[
        connect(pwLineLoad.n, lOADPQ.p),
        connect(pwLineSC.n, sTATCOM.p),
        connect(Syn1.p, pwLineInf.p),
        connect(pwLineInf.n, pwLineLoad.p),
        connect(pwLineSC.p, pwLineLoad.p),
        connect(Syn1.p, busInf.p),
        connect(pwLineInf.n, busSplit.p),
        connect(pwLineSC.n, busSC.p),
        connect(pwLineLoad.n, busLoad.p),
        sTATCOM.v_POD ~ NoPSS.y,   # connect(NoPSS.y, sTATCOM.v_POD)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.FACTS.STATCOM_Test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "FACTS.STATCOM_Test.jl"))
    validate_against_oracle(STATCOM_Test, oracle)
end
