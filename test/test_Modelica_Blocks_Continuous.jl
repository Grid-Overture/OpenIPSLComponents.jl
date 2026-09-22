# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Mini-MSL Blocks.Continuous (PLAN-01): closed-form responses to a unit step u = 1 (t >= 0), checked to 1e-6.
# Integrator(k = 2, InitialState, y_start = 0.5): y = 0.5 + 2t -> 2.5 at t = 1. (SteadyState is exercised by
#   LeadLagLim in test_NonElectrical_Continuous.jl: alone with u = 0 it is undetermined, in Modelica as well.)
# LimIntegrator(k = 2, outMax = 1.5, InitialState, y_start = 0.5): y = 0.5 + 2t until 1.5 (t = 0.5), then held at 1.5.
# Derivative(k = 3, T = 0.2, InitialOutput, y_start = 0): y(0) = 0 gives x(0) = u = 1; then x stays 1, y = 0.
#   With SteadyState and u = 1: x = 1, y = 0 too. With InitialState x_start = 0: y = (k/T)(u - x) = 15 e^{-t/T}: 15 e^-5 at t = 1.
# FirstOrder(k = 2, T = 0.5, InitialState, y_start = 0): y = 2(1 - e^{-2t}) -> 2(1 - e^-2) at t = 1.
# TransferFunction(b = [1], a = [Te = 0.314, Ke = 1], InitialOutput, y_start = 0): Te y' = u - Ke y -> y = (1 - e^{-t/Te}).
# TransferFunction(b = [K T1, K], a = [T2, 1]) with K = 2, T1 = 0.1, T2 = 0.5, InitialOutput, y_start = 2 (u = 1 equilibrium):
#   steady state y = K = 2 stays 2.
@testset "Modelica.Blocks.Continuous" begin
    @named int1 = Integrator(; k = 2, initType = :InitialState, y_start = 0.5)
    @named lim = LimIntegrator(; k = 2, outMax = 1.5, initType = :InitialState, y_start = 0.5)
    @named der1 = Derivative(; k = 3, T = 0.2, initType = :InitialOutput, y_start = 0)
    @named der2 = Derivative(; k = 3, T = 0.2, initType = :InitialState, x_start = 0)
    @named fo = FirstOrder(; k = 2, T = 0.5, initType = :InitialState, y_start = 0)
    @named tf1 = TransferFunction(; b = [1], a = [0.314, 1], initType = :InitialOutput, y_start = 0)
    @named tf2 = TransferFunction(; b = [2 * 0.1, 2], a = [0.5, 1], initType = :InitialOutput, y_start = 2)
    @named rig = System(Equation[int1.u ~ 1, lim.u ~ 1, der1.u ~ 1, der2.u ~ 1, fo.u ~ 1, tf1.u ~ 1, tf2.u ~ 1],
        t, [], []; systems = [int1, lim, der1, der2, fo, tf1, tf2])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.0; idxs = sys.int1.y) ≈ 0.5 atol = 1e-9
    @test sol(1.0; idxs = sys.int1.y) ≈ 2.5 atol = 1e-6
    @test sol(0.25; idxs = sys.lim.y) ≈ 1.0 atol = 1e-6
    @test sol(1.0; idxs = sys.lim.y) ≈ 1.5 atol = 1e-6
    @test sol(0.0; idxs = sys.der1.y) ≈ 0 atol = 1e-9
    @test sol(0.0; idxs = sys.der1.x) ≈ 1 atol = 1e-9
    @test sol(1.0; idxs = sys.der1.y) ≈ 0 atol = 1e-6
    @test sol(0.0; idxs = sys.der2.y) ≈ 15 atol = 1e-6
    @test sol(1.0; idxs = sys.der2.y) ≈ 15 * exp(-5) atol = 1e-6
    @test sol(1.0; idxs = sys.fo.y) ≈ 2 * (1 - exp(-2)) atol = 1e-6
    @test sol(0.0; idxs = sys.tf1.y) ≈ 0 atol = 1e-9
    @test sol(1.0; idxs = sys.tf1.y) ≈ 1 - exp(-1 / 0.314) atol = 1e-6
    @test sol(0.0; idxs = sys.tf2.y) ≈ 2 atol = 1e-9
    @test sol(1.0; idxs = sys.tf2.y) ≈ 2 atol = 1e-6
    @test sol(1.0; idxs = sys.tf1.x[1]) ≈ 1 - exp(-1 / 0.314) atol = 1e-6   # x = x_scaled/a_end, a_end = 1
end

# Der (batch 12, PLAN-12 step 2.1): the block is the analytic `y = der(u)`, with no state and no parameter (F-89).
# On a state it is exact by construction; the case that matters is `u` algebraic, which raises the index of the
# system and leaves the reduction to `mtkcompile`. Both are checked here on x' = 3x (x(0) = 1, x = e^{3t}):
# `d1.u = x` gives y = 3 e^{3t}, and `d2.u = a` with the algebraic equation `a = 2x + 1` gives y = 6 e^{3t}.
# OpenModelica cannot reduce the same index on the SMIB (F-89); ModelingToolkit reduces it here and on the network
# of `Tests/Sensors/SoftPMU.jl`.
@testset "Modelica.Blocks.Continuous.Der" begin
    @named d1 = Der()
    @named d2 = Der()
    @variables x(t) = 1.0 a(t)
    @named rig = System(Equation[D_nounits(x) ~ 3x, a ~ 2x + 1, d1.u ~ x, d2.u ~ a], t, [x, a], []; systems = [d1, d2])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.0; idxs = sys.d1.y) ≈ 3 atol = 1e-6
    @test sol(0.0; idxs = sys.d2.y) ≈ 6 atol = 1e-6
    @test sol(1.0; idxs = sys.d1.y) ≈ 3 * exp(3) atol = 1e-5
    @test sol(1.0; idxs = sys.d2.y) ≈ 6 * exp(3) atol = 1e-5
end
