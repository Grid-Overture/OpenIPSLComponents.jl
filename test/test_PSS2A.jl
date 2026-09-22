# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PSS2A (PLAN-05 phase 6). `Tests.Controls.PSSE.PSS.PSS2A` has no OpenModelica oracle (F-48), so the model is
# validated here by hand with the Test's own parameters and, numerically against OpenModelica, by the
# `Examples.Tutorial.Example_4.Experiments.SMIBVarLoad` case of phase 7 (whose PSS2A has T_w1 = 5).
#
# With constant inputs every washout blocks the DC component, so the whole chain rests at zero: the four
# `DerivativeLag`s have y_start = 0, `SimpleLag1`/`SimpleLag2` y_start = 0, the ramp-tracking filter sees 0 and
# `VOTHSG = limiter(Leadlag2.y) = 0`, with every derivative 0. The Test's `T_w1 = 0` is the interesting case: a
# `DerivativeLag` with T = 0 is the pass-through branch of the block (batch 1), so the first washout is transparent
# and the second one (T_w2 = 5) does the filtering.
# A step of +0.002 on V_S1 at t = 1 s produces a pulse on VOTHSG that decays back to 0 (all paths are washouts) and
# never leaves [V_STMIN, V_STMAX].
@testset "PSS2A" begin
    pars = (; K_S1 = 2.0, K_S2 = 0.758, K_S3 = 1.0, M = 5, N = 1, T_1 = 0.47, T_2 = 0.07, T_3 = 0.47, T_4 = 0.07,
        T_6 = 0.0, T_7 = 5.0, T_8 = 0.12, T_9 = 0.1, T_w1 = 0.0, T_w2 = 5.0, T_w3 = 5.0, T_w4 = 5.0,
        V_STMAX = 0.1, V_STMIN = -0.1)

    @named pss = PSS2A(; pars...)
    @named rig = System(Equation[pss.V_S1 ~ 0, pss.V_S2 ~ 0.4], t, [], []; systems = [pss])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 5.0))
    integ = init(prob, Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test integ[sys.pss.VOTHSG] ≈ 0 atol = 1e-9
    @test integ[sys.pss.derivativeLag.y] ≈ 0 atol = 1e-9    # T_w1 = 0: pass-through of V_S1 = 0
    @test integ[sys.pss.derivativeLag2.y] ≈ 0 atol = 1e-9   # washout of the constant V_S2
    for v in unknowns(sys)
        @test abs(initial_derivative(integ, sys, v)) < 1e-9
    end
    sol = solve(prob, Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sol.retcode == ReturnCode.Success
    @test sol(5.0; idxs = sys.pss.VOTHSG) ≈ 0 atol = 1e-9

    # a step on V_S1: a pulse that washes out
    @named stp = Step(; height = 0.002, offset = 0, startTime = 1.0)
    @named pss2 = PSS2A(; pars...)
    @named rig2 = System(Equation[pss2.V_S1 ~ stp.y, pss2.V_S2 ~ 0.4], t, [], []; systems = [pss2, stp])
    sys2 = mtkcompile(rig2)
    sol2 = solve(ODEProblem(sys2, [], (0.0, 80.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sol2.retcode == ReturnCode.Success
    @test sol2(0.5; idxs = sys2.pss2.VOTHSG) ≈ 0 atol = 1e-9
    @test abs(sol2(1.5; idxs = sys2.pss2.VOTHSG)) > 1e-5                 # the step is seen
    @test sol2(80.0; idxs = sys2.pss2.VOTHSG) ≈ 0 atol = 1e-6            # and washed out
    vs = [sol2(tk; idxs = sys2.pss2.VOTHSG) for tk in 0:0.05:80]
    @test maximum(vs) <= 0.1 + 1e-12 && minimum(vs) >= -0.1 - 1e-12      # within [V_STMIN, V_STMAX]
end
