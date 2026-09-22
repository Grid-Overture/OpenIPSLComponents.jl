# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PSSTypeII has no Test of its own in OpenIPSL 3.1.0; its numeric validation against OpenModelica comes from
# Examples.Tutorial.Example_2 and Examples.KundurSMIB.SMIB_AVR_PSS (the `pss` group of CASES). Hand test, the rig of
# test_STAB2A.jl, with Example_2's parameters (Kw = 9.5, Tw = 1.41, T1 = 0.154, T2 = 0.033, T3 = T4 = 1,
# vsmax/vsmin = +-0.2).
#
# The chain is derivativeLag(K = Kw*Tw, T = Tw) -> imLeadLag(1, T1, T2) -> imLeadLag1(1, T3, T4) -> limiter.
# `derivativeLag` is the washout Kw*Tw*s/(1 + Tw*s) written as a TransferFunction with b = {Kw*Tw, 0}, a = {Tw, 1}
# and `InitialOutput, y_start = 0`, so with a constant vSI it rests at y = 0 and the whole chain rests at vs = 0:
# every derivative vanishes at t = 0 and vs stays 0 over 10 s.
# `imLeadLag1` has T3 = T4, which selects the .mo's degenerate branch y = K*u = u (F-50: the branch is decided in
# Julia), so the stabilizer is really washout + one lead-lag here.
# A step of +0.001 on vSI at 1 s gives a pulse that washes out with the 1.41 s wash-out and returns below 1e-6,
# inside the +-0.2 limits: the instantaneous gain of the chain is Kw*(T1/T2) = 9.5*4.67 = 44.3, so the peak is
# ~0.044 pu. A step of +0.01 against a 1e-3 limit is clamped there.
@testset "PSSTypeII" begin
    pars = (; vsmax = 0.2, vsmin = -0.2, Kw = 9.5, Tw = 1.41, T1 = 0.154, T2 = 0.033, T3 = 1.0, T4 = 1.0)

    @named pss = PSSTypeII(; pars...)
    @named rig = System(Equation[pss.vSI ~ 1.0], t, [], []; systems = [pss])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 10.0))
    integ = init(prob, Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test integ[sys.pss.vs] ≈ 0 atol = 1e-9
    @test integ[sys.pss.derivativeLag.y] ≈ 0 atol = 1e-9
    @test integ[sys.pss.imLeadLag.y] ≈ 0 atol = 1e-9
    @test integ[sys.pss.imLeadLag1.y] ≈ 0 atol = 1e-9
    for v in unknowns(sys)
        @test abs(initial_derivative(integ, sys, v)) < 1e-9
    end
    sol = solve(prob, Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sol.retcode == ReturnCode.Success
    @test sol(10.0; idxs = sys.pss.vs) ≈ 0 atol = 1e-9

    # a step of +0.001 on vSI at 1 s: a pulse that washes out inside the limits
    @named stp = Step(; height = 0.001, offset = 1.0, startTime = 1.0)
    @named pss2 = PSSTypeII(; pars...)
    @named rig2 = System(Equation[pss2.vSI ~ stp.y], t, [], []; systems = [pss2, stp])
    sys2 = mtkcompile(rig2)
    sol2 = solve(ODEProblem(sys2, [], (0.0, 30.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sol2.retcode == ReturnCode.Success
    @test sol2(0.5; idxs = sys2.pss2.vs) ≈ 0 atol = 1e-9
    vs = [sol2(tk; idxs = sys2.pss2.vs) for tk in 0:0.01:30]
    @test 0 < maximum(abs.(vs)) < 0.2            # a pulse, strictly inside the limits
    @test abs(sol2(30.0; idxs = sys2.pss2.vs)) < 1e-6   # washed out

    # the same pulse against a 1e-3 limit is clamped there
    @named pss3 = PSSTypeII(; pars..., vsmax = 1e-3, vsmin = -1e-3)
    @named stp3 = Step(; height = 0.01, offset = 1.0, startTime = 1.0)
    @named rig3 = System(Equation[pss3.vSI ~ stp3.y], t, [], []; systems = [pss3, stp3])
    sys3 = mtkcompile(rig3)
    sol3 = solve(ODEProblem(sys3, [], (0.0, 30.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sol3.retcode == ReturnCode.Success
    vs3 = [sol3(tk; idxs = sys3.pss3.vs) for tk in 0:0.01:30]
    @test maximum(abs.(vs3)) ≈ 1e-3 atol = 1e-9
    @test maximum(abs.(vs3)) <= 1e-3 + 1e-12
end
