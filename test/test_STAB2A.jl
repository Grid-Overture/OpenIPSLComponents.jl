# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# STAB2A (PLAN-05 phase 6). No Test of OpenIPSL 3.1.0 instantiates it and no other model uses it, so it is
# validated by hand.
#
# The six `TransferFunction`s initialize with `Init.SteadyState` (`der(x) = 0`), the only models of the port that do.
# With a constant PELEC the three washouts (`b = {-+K_2 T_2, 0}`, `a = {T_2, 1}`) have d = -+K_2 and, at
# `der(x) = 0`, `x = u`, so `y = K_2 x - K_2 u = 0`: the whole chain, the two output low-pass filters and the
# limiter included, rests at `VOTHSG = 0` with every derivative 0.
# A step on PELEC produces a pulse on VOTHSG that returns to 0 (the input filter is a washout) and stays inside
# +-H_LIM; with a small H_LIM the pulse is clamped there.
@testset "STAB2A" begin
    pars = (; K_2 = 3.0, T_2 = 2.0, K_3 = 1.5, T_3 = 0.5, K_4 = 0.8, K_5 = 1.2, T_5 = 0.3)

    @named st = STAB2A(; pars..., H_LIM = 5)
    @named rig = System(Equation[st.PELEC ~ 0.4], t, [], []; systems = [st])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 5.0))
    integ = init(prob, Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test integ[sys.st.VOTHSG] ≈ 0 atol = 1e-9
    @test integ[sys.st.transferFunction.y] ≈ 0 atol = 1e-9
    @test integ[sys.st.transferFunction3.y] ≈ 0 atol = 1e-9
    for v in unknowns(sys)
        @test abs(initial_derivative(integ, sys, v)) < 1e-9
    end
    sol = solve(prob, Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sol.retcode == ReturnCode.Success
    @test sol(5.0; idxs = sys.st.VOTHSG) ≈ 0 atol = 1e-9

    # a step of +0.1 on PELEC at t = 1 s: a pulse that washes out, clamped at H_LIM = 0.05
    @named stp = Step(; height = 0.1, offset = 0.4, startTime = 1.0)
    @named st2 = STAB2A(; pars..., H_LIM = 0.05)
    @named rig2 = System(Equation[st2.PELEC ~ stp.y], t, [], []; systems = [st2, stp])
    sys2 = mtkcompile(rig2)
    sol2 = solve(ODEProblem(sys2, [], (0.0, 60.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sol2.retcode == ReturnCode.Success
    @test sol2(0.5; idxs = sys2.st2.VOTHSG) ≈ 0 atol = 1e-9
    vs = [sol2(tk; idxs = sys2.st2.VOTHSG) for tk in 0:0.02:60]
    @test maximum(abs.(vs)) ≈ 0.05 atol = 1e-9                  # the limiter is reached
    @test maximum(abs.(vs)) <= 0.05 + 1e-12
    @test sol2(60.0; idxs = sys2.st2.VOTHSG) ≈ 0 atol = 1e-6    # washed out
end
