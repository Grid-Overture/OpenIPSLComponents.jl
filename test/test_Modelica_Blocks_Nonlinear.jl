# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Mini-MSL Blocks.Nonlinear (PLAN-01) on a ramp input u = t - 1 over [0, 2] (u from -1 to 1).
# Limiter(uMax = 0.5, uMin = -0.3): y = -0.3 at u = -1 (t = 0), y = u = 0.2 at t = 1.2, y = 0.5 at t = 2.
# VariableLimiter(limit1 = 0.4, limit2 = -0.6): y = -0.6 at t = 0, 0.2 at t = 1.2, 0.4 at t = 2.
# DeadZone(uMax = 0.5, uMin = -0.3): y = u - uMin = -0.7 at t = 0, 0 at t = 1.2, u - uMax = 0.5 at t = 2.
@testset "Modelica.Blocks.Nonlinear" begin
    @named lim = Limiter(; uMax = 0.5, uMin = -0.3)
    @named vlim = VariableLimiter()
    @named dz = DeadZone(; uMax = 0.5, uMin = -0.3)
    @named rig = System(Equation[lim.u ~ t - 1, vlim.u ~ t - 1, vlim.limit1 ~ 0.4, vlim.limit2 ~ -0.6, dz.u ~ t - 1],
        t, [], []; systems = [lim, vlim, dz])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9, saveat = [0.0, 1.2, 2.0])
    @test sol.retcode == ReturnCode.Success
    @test sol(0.0; idxs = sys.lim.y) ≈ -0.3 atol = 1e-9
    @test sol(1.2; idxs = sys.lim.y) ≈ 0.2 atol = 1e-9
    @test sol(2.0; idxs = sys.lim.y) ≈ 0.5 atol = 1e-9
    @test sol(0.0; idxs = sys.vlim.y) ≈ -0.6 atol = 1e-9
    @test sol(1.2; idxs = sys.vlim.y) ≈ 0.2 atol = 1e-9
    @test sol(2.0; idxs = sys.vlim.y) ≈ 0.4 atol = 1e-9
    @test sol(0.0; idxs = sys.dz.y) ≈ -0.7 atol = 1e-9
    @test sol(1.2; idxs = sys.dz.y) ≈ 0 atol = 1e-9
    @test sol(2.0; idxs = sys.dz.y) ≈ 0.5 atol = 1e-9
end

# FixedDelay (PLAN-05, F-20 d). `delayTime <= Modelica.Constants.eps` degenerates to y = u, which keeps GGOV1DU
# (Teng = 0) an ODE; a real delay makes the system a DDE, solved as DDEProblem + MethodOfSteps(Rodas5P()).
# Rig: u = t (a ramp), so y(t) = u(t - 0.3) = t - 0.3 exactly for t >= 0.3 and u(0) = 0 before that; `z` is an
# algebraic output that depends on the delayed signal (z = 2*y), the case F-20 d probed with a mass matrix.
@testset "Modelica.Blocks.Nonlinear.FixedDelay" begin
    @named d0 = FixedDelay(; delayTime = 0)
    @named rig0 = System(Equation[d0.u ~ t], t, [], []; systems = [d0])
    sys0 = mtkcompile(rig0)
    sol0 = solve(ODEProblem(sys0, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol0.retcode == ReturnCode.Success
    @test sol0(0.7; idxs = sys0.d0.y) ≈ 0.7 atol = 1e-9

    @named fd = FixedDelay(; delayTime = 0.3)
    @variables x(t) z(t)
    @named rig = System(Equation[fd.u ~ t, z ~ 2 * fd.y, D_nounits(x) ~ z], t, [x, z], []; systems = [fd],
        guesses = Dict(x => 0.0, z => 0.0))
    sys = mtkcompile(rig)
    @test ModelingToolkit.is_dde(sys)
    prob = DDEProblem(sys, [sys.x => 0.0], (0.0, 1.0); constant_lags = [0.3])
    sol = solve(prob, MethodOfSteps(Rodas5P()); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.2; idxs = sys.fd.y) ≈ 0.0 atol = 1e-8      # history before the delay: u(t.start) = 0
    @test sol(0.5; idxs = sys.fd.y) ≈ 0.2 atol = 1e-8
    @test sol(1.0; idxs = sys.fd.y) ≈ 0.7 atol = 1e-8
    @test sol(1.0; idxs = sys.z) ≈ 1.4 atol = 1e-8
    @test sol(1.0; idxs = sys.x) ≈ 0.49 atol = 1e-7        # 2 * integral of max(t - 0.3, 0) over [0, 1] = 0.7^2
end

# PadeDelay (PLAN-05, plan B of F-20 d / F-51): the rational approximation of the same transport delay, an ODE.
# On a ramp input it reproduces the shift exactly once its own start-up transient has decayed: a Pade approximant
# matches the Taylor expansion of exp(-sT) to order n + m, so the group delay of a linear signal is exact.
# `balance = true` starts it at `der(x) = 0`, which is the steady state for the input *value* at t0 (y(0) = u(0) = 0
# here), not on the ramp and not MSL's history clamp of the true delay (y = u(t.start) for t <= t.start + T): the
# block approximates the delay, not its start-up. That is exactly the case of its users, which start from an
# equilibrium where the delayed signal is constant.
@testset "Modelica.Blocks.Nonlinear.PadeDelay" begin
    @named pd = PadeDelay(; delayTime = 0.3, n = 4, balance = true)
    @named rigp = System(Equation[pd.u ~ t], t, [], []; systems = [pd])
    sysp = mtkcompile(rigp)
    @test !ModelingToolkit.is_dde(sysp)
    solp = solve(ODEProblem(sysp, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-12, reltol = 1e-12, initializealg = INIT)
    @test solp.retcode == ReturnCode.Success
    @test solp(0.0; idxs = sysp.pd.y) ≈ 0.0 atol = 1e-8     # steady state of the input value at t0, u(0) = 0
    @test solp(1.0; idxs = sysp.pd.y) ≈ 0.7 atol = 1e-5     # the start-up transient is down to 2.7e-7 here
    @test solp(2.0; idxs = sysp.pd.y) ≈ 1.7 atol = 1e-8     # and gone: the ramp shifted by exactly 0.3 s
end
