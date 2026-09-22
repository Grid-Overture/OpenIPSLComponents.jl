# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/FACTS/TCSC_Test.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# `ctrl = OpenIPSL.Types.Ctrl.xTCSC` is `ctrl = :xTCSC`, so the `xTCSC` branch of `b` is the one compiled and the
# limits of X1 are xTCSC_min/xTCSC_max. `pwLineInf1(opening = 2)` has no `t1`, so it never opens (its t1 defaults to
# Inf). The load steps +2 MW from 2 to 10 s.
@component function TCSC_Test(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        lOADPQ = PQvar(; P_0 = 50000000.0, Q_0 = 10000000.0, v_0 = 0.991992, angle_0 = -0.010060269794713,
            t_start_1 = 2.0, t_end_1 = 10.0, dP1 = 2000000.0, S_b, fn)
        tCSC = TCSC(; ctrl = :xTCSC, alpha_min = 0.87266462599716, alpha_max = 1.5707963267949, Tr = 0.01, Kp = 2.0,
            Ki = 20.0, XL = 0.08, alpha0 = 1.0471975511966, pref = -0.0500733, G = 0.0, B = 0.0,
            xTCSC0 = 0.0133767, S_b, fn)
        pwLineInf = PwLine(; R = 0.001, X = 0.2, G = 0.0, B = 0.0, S_b, fn)
        Gen = Bus(; angle_0 = 0.070618464996643, S_b, fn)
        Load = Bus(; v_0 = 0.991992, angle_0 = -0.010060269794713, S_b, fn)
        Inf_ = Bus(; S_b, fn)
        Gen1 = Order2(; D = 0.0, angle_0 = 0.070618464996643, ra = 0.01, x1d = 0.302, M = 10.0, P_0 = 40000000.0,
            Q_0 = 5417240.0, Sn = 100000000.0, v_0 = 1.0, V_b = 400000.0, Vn = 400000.0, S_b, fn)
        NoPSS = Constant(; k = 0.0)
        pwLineInf1 = PwLine(; opening = 2, R = 0.001, X = 0.2, G = 0.0, B = 0.0, S_b, fn)
        pwLineInf3 = PwLine(; B = 0.0, R = 0.001, X = 0.1, G = 0.0, S_b, fn)
        Inter = Bus(; S_b, fn)
        infiniteBus = InfiniteBus(; P_0 = 10017100.0, Q_0 = 8005930.0, S_b, fn)
    end
    eqs = Equation[
        connect(pwLineInf.n, Load.p),
        connect(tCSC.n, Inf_.p),
        connect(Gen.p, pwLineInf.p),
        connect(Gen1.p, Gen.p),
        Gen1.pm ~ Gen1.pm0,        # connect(Gen1.pm0, Gen1.pm)
        Gen1.vf ~ Gen1.vf0,        # connect(Gen1.vf0, Gen1.vf)
        tCSC.Vs_pod ~ NoPSS.y,     # connect(NoPSS.y, tCSC.Vs_pod)
        connect(Load.p, pwLineInf1.p),
        connect(pwLineInf3.p, pwLineInf1.p),
        connect(pwLineInf3.n, Inter.p),
        connect(tCSC.p, Inter.p),
        connect(pwLineInf1.n, Inf_.p),
        connect(Load.p, lOADPQ.p),
        connect(Inf_.p, infiniteBus.p),
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.FACTS.TCSC_Test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "FACTS.TCSC_Test.jl"))
    # `Inf` is a Julia constant, so the bus is `Inf_` here (JULIA_RENAMES of runtests.jl)
    validate_against_oracle(TCSC_Test, oracle)
end
