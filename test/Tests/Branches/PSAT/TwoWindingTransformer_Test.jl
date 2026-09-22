# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Branches/PSAT/TwoWindingTransformer_Test.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function TwoWindingTransformer_Test(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        order2_1 = Order2(; D = 5.0, angle_0 = 0.0, ra = 0.001, x1d = 0.302, M = 10.0, P_0 = 50249.405357958, Q_0 = 10496.891745129, Sn = 100000000.0, v_0 = 1.0, V_b = 13800000.0, Vn = 13800000.0, S_b, fn)
        lOADPQ = PQ(; P_0 = 30000.0, Q_0 = 1000.0, S_b, fn)
        twoWindingTransformer = TwoWindingTransformer(; Vn = 13800.0, xT = 0.1, rT = 0.01, V_b = 13800.0, S_b, fn)
        pwLine1 = PwLine(; R = 0.01, X = 0.1, G = 0.0, B = 0.001/2, S_b, fn)
        pwLine2 = PwLine(; R = 0.01, X = 0.1, G = 0.0, B = 0.001, S_b, fn)
        bus1 = Bus(; S_b, fn)
        bus2 = Bus(; S_b, fn)
        bus3 = Bus(; S_b, fn)
    end
    eqs = Equation[
        connect(bus3.p, pwLine2.n),
        connect(twoWindingTransformer.n, bus2.p),
        connect(twoWindingTransformer.p, bus1.p),
        connect(bus1.p, order2_1.p),
        connect(bus2.p, pwLine2.p),
        order2_1.vf0 ~ order2_1.vf,   # connect(order2_1.vf0, order2_1.vf)
        order2_1.pm ~ order2_1.pm0,   # connect(order2_1.pm, order2_1.pm0)
        connect(bus3.p, lOADPQ.p),
        connect(pwLine1.p, bus2.p),
        connect(pwLine1.n, bus3.p),
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.Branches.PSAT.TwoWindingTransformer_Test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Branches.PSAT.TwoWindingTransformer_Test.jl"))
    # P12/P21/Q12/Q21 are display variables the lot-0 TwoWindingTransformer.jl omits; vs/is/vr/ir are the pins (PLAN-02)
    validate_against_oracle(TwoWindingTransformer_Test, oracle; transformer_aliases(oracle)...)
end
