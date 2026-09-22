# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Branches/Generic/ULTC.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function ULTC_Test(; name, S_b = 100e6, fn = 50)   # `ULTC` is the model (PLAN-02: a Test named as its model gets the suffix _Test)
    systems = @named begin
        B1 = Bus(; S_b, fn)
        B2 = Bus(; S_b, fn)
        B3 = Bus(; S_b, fn)
        B4 = Bus(; S_b, fn)
        Line12_a = PwLine(; G = 0.0, R = 0.0, X = 0.65, B = 0.0, S_b, fn)
        Line34 = PwLine(; G = 0.0, R = 0.0, X = 0.80, B = 0.0, S_b, fn)
        slack = InfiniteBus(; v_0 = 1.05, S_b, fn)
        ultc = ULTC(; )
        Line12_b = PwLine(; B = 0.0, G = 0.0, R = 0.0, X = 0.40625, t1 = 20.0, t2 = 200.0, S_b, fn)
        load = ExponentialRecovery(; P_0 = 40000000.0, Tp = 5.0, Tq = 5.0, alpha_s = 0.0, alpha_t = 2.0, beta_s = 0.0, beta_t = 2.0, S_b, fn)
    end
    eqs = Equation[
        connect(Line12_a.n, B2.p),
        connect(Line12_a.p, B1.p),
        connect(B3.p, Line34.p),
        connect(Line34.n, B4.p),
        connect(slack.p, B1.p),
        connect(ultc.n, B3.p),
        connect(ultc.p, B2.p),
        connect(Line12_b.n, B2.p),
        connect(Line12_b.p, B1.p),
        connect(B4.p, load.p),
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.Branches.Generic.ULTC" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Branches.Generic.ULTC.jl"))
    # the load's states xp, xq have no initial equation: OpenModelica fixes them at their start values (F-28);
    # zeroCrossing.y is the instantaneous Boolean pulse OM writes at the tap events (0 in continuous time here)
    validate_against_oracle(ULTC_Test, oracle; u0 = sys -> [sys.load.xp => 0.0, sys.load.xq => 0.0],
        skip = ["ultc.zeroCrossing.y"])
end
