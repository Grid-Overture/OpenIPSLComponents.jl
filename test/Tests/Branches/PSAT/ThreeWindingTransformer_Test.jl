# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Branches/PSAT/ThreeWindingTransformer_Test.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function ThreeWindingTransformer_Test(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        pwLine3 = PwLine(; B = 0.001/2, G = 0.0, R = 0.01, X = 0.1, S_b, fn)
        pwLine4 = PwLine(; B = 0.001/2, G = 0.0, R = 0.01, X = 0.1, S_b, fn)
        sine1 = Sine(; amplitude = 0.001, f = 0.2)
        add2 = Add(; k2 = -1)
        sine2 = Sine(; amplitude = 0.001, f = 0.2, startTime = 5)
        Gen1 = Order2(; D = 5.0, angle_0 = 0.0, ra = 0.001, x1d = 0.302, M = 10.0, P_0 = 80124.48966387101, Q_0 = 59251.697676828, Sn = 370000000.0, v_0 = 1.0, V_b = 400000.0, Vn = 400000.0, S_b, fn)
        add = Add(; )
        lOADPQ = PQvar(; t_start_1 = 5.0, t_end_1 = 8.0, t_start_2 = 8.0, t_end_2 = 12.0, dP1 = 0.0, dP2 = 0.0, dQ1 = 0.01, dQ2 = -0.01, P_0 = 40000.0, Q_0 = 20000.0, S_b, fn)
        lOADPQ1 = PQvar(; t_start_1 = 0.0, t_end_1 = 0.0, t_start_2 = 0.0, t_end_2 = 0.0, dP1 = 0.0, dQ1 = 0.0, dP2 = 0.0, dQ2 = 0.0, P_0 = 40000.0, Q_0 = 40000.0, S_b, fn)
        threeWindingTransformer = ThreeWindingTransformer(; S_b, fn)
        Bus1 = Bus(; S_b, fn)
        Bus2 = Bus(; S_b, fn)
        Bus3 = Bus(; S_b, fn)
        Bus4 = Bus(; S_b, fn)
    end
    eqs = Equation[
        add2.y ~ add.u1,   # connect(add2.y, add.u1)
        add.y ~ Gen1.vf,   # connect(add.y, Gen1.vf)
        Gen1.vf0 ~ add.u2,   # connect(Gen1.vf0, add.u2)
        Gen1.pm0 ~ Gen1.pm,   # connect(Gen1.pm0, Gen1.pm)
        connect(pwLine4.n, pwLine3.n),
        connect(pwLine4.p, pwLine3.p),
        connect(Gen1.p, Bus1.p),
        connect(Bus1.p, pwLine3.p),
        connect(Bus2.p, pwLine3.n),
        connect(Bus2.p, threeWindingTransformer.b1),
        connect(threeWindingTransformer.b2, Bus3.p),
        connect(lOADPQ.p, Bus3.p),
        connect(threeWindingTransformer.b3, Bus4.p),
        connect(Bus4.p, lOADPQ1.p),
        sine1.y ~ add2.u1,   # connect(sine1.y, add2.u1)
        sine2.y ~ add2.u2,   # connect(sine2.y, add2.u2)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.Branches.PSAT.ThreeWindingTransformer_Test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Branches.PSAT.ThreeWindingTransformer_Test.jl"))
    validate_against_oracle(ThreeWindingTransformer_Test, oracle; transformer_aliases(oracle)...)
end
