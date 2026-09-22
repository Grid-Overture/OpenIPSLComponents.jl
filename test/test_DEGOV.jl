# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# DEGOV (PLAN-05 phase 2). No Test of OpenIPSL 3.1.0 instantiates it and no other model uses it, so it is validated
# by hand on a rig that drives the three causal ports directly: SPEED from a Step, PMECH0 constant.
#
# At rest (SPEED = 0) the chain is: transferFunction(b = {-T3, -1}, a = {T2*T1, T1, 1}) has y_start = 0 and a zero
# input, so its output stays 0; integrator(k = K, y_start = P0) holds P0; leadLag and simpleLagLim start at P0 and
# see P0; the delay passes P0; add = 1 + SPEED = 1; PMECH = product1 = 1*P0 = P0 = PMECH0, with every derivative 0.
#
# The transport delay cannot be integrated here: `DEGOV` carries a `SimpleLagLim`, and ModelingToolkit 11.43 cannot
# evaluate the condition of any event inside a delayed system (F-51). The delayed legs therefore use the Julia-only
# `pade` fallback of `FixedDelay` (a `PadeDelay(delayTime, n, balance = true)`, an ODE); the literal `u(t - TD)` is
# exercised by `test_Modelica_Blocks_Nonlinear.jl` on a rig without events.
@testset "DEGOV" begin
    PMECH0 = 0.8
    pars = (; T1 = 0.2, T2 = 0.1, T3 = 0.5, K = 8.0, T4 = 0.25, T5 = 0.05, T6 = 0.2, TMAX = 1.1, TMIN = 0.0)

    # --- TD = 0: the FixedDelay degenerates to y = u and the model is a plain ODE at its operating point
    @named deg0 = DEGOV(; pars..., TD = 0.0)
    @named rig0 = System(Equation[deg0.SPEED ~ 0, deg0.PMECH0 ~ PMECH0], t, [], []; systems = [deg0])
    sys0 = mtkcompile(rig0)
    @test !ModelingToolkit.is_dde(sys0)
    prob0 = ODEProblem(sys0, [], (0.0, 2.0))
    integ0 = init(prob0, Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test integ0[sys0.deg0.PMECH] ≈ PMECH0 atol = 1e-9
    @test integ0[sys0.deg0.integrator.y] ≈ PMECH0 atol = 1e-9
    @test integ0[sys0.deg0.transferFunction.y] ≈ 0 atol = 1e-9
    for v in unknowns(sys0)
        @test abs(initial_derivative(integ0, sys0, v)) < 1e-9
    end
    sol0 = solve(prob0, Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sol0.retcode == ReturnCode.Success
    @test sol0(2.0; idxs = sys0.deg0.PMECH) ≈ PMECH0 atol = 1e-9

    # --- TD = 0 with a step of -0.01 on SPEED at t = 1 s: the governor reacts at once (no delay)
    @named stp0 = Step(; height = -0.01, offset = 0, startTime = 1.0)
    @named degs = DEGOV(; pars..., TD = 0.0)
    @named rigs = System(Equation[degs.SPEED ~ stp0.y, degs.PMECH0 ~ PMECH0], t, [], []; systems = [degs, stp0])
    syss = mtkcompile(rigs)
    sols = solve(ODEProblem(syss, [], (0.0, 3.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sols.retcode == ReturnCode.Success
    @test sols(0.9; idxs = syss.degs.PMECH) ≈ PMECH0 atol = 1e-9
    @test abs(sols(1.02; idxs = syss.degs.PMECH) - PMECH0) > 1e-6

    # --- TD = 0.05 through the Pade fallback: the operating point is unchanged and stays
    @named degd = DEGOV(; pars..., TD = 0.05, pade = 4)
    @named rigd = System(Equation[degd.SPEED ~ 0, degd.PMECH0 ~ PMECH0], t, [], []; systems = [degd])
    sysd = mtkcompile(rigd)
    @test !ModelingToolkit.is_dde(sysd)
    probd = ODEProblem(sysd, [], (0.0, 2.0))
    integd = init(probd, Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test integd[sysd.degd.PMECH] ≈ PMECH0 atol = 1e-9
    for v in unknowns(sysd)
        @test abs(initial_derivative(integd, sysd, v)) < 1e-9
    end
    sold = solve(probd, Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sold.retcode == ReturnCode.Success
    @test sold(2.0; idxs = sysd.degd.PMECH) ≈ PMECH0 atol = 1e-9

    # --- TD = 0.05 with the step: the delay block shifts its input by TD (the Pade group delay), checked once the
    # transient of the step has passed
    @named stp1 = Step(; height = -0.01, offset = 0, startTime = 1.0)
    @named degp = DEGOV(; pars..., TD = 0.05, pade = 4)
    @named rigp = System(Equation[degp.SPEED ~ stp1.y, degp.PMECH0 ~ PMECH0], t, [], []; systems = [degp, stp1])
    sysp = mtkcompile(rigp)
    solp = solve(ODEProblem(sysp, [], (0.0, 3.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test solp.retcode == ReturnCode.Success
    @test abs(solp(2.0; idxs = sysp.degp.PMECH) - PMECH0) > 1e-6
    for tk in (1.5, 2.0, 2.5)
        @test solp(tk; idxs = sysp.degp.fixedDelay.y) ≈ solp(tk - 0.05; idxs = sysp.degp.fixedDelay.u) atol = 1e-5
    end
end
