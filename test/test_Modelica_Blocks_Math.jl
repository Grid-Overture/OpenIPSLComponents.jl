# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Mini-MSL Blocks.Math (PLAN-01): each block on constant inputs, algebraic values checked to 1e-9.
# Gain(k = 2.5): y = 2.5*u = 2.5*1.2 = 3.0. Add(k1 = 2, k2 = -1): y = 2*1.2 - 0.7 = 1.7. Add3(k3 = 3): y = 1.2 + 0.7 + 3*0.5 = 3.4.
# Product: 1.2*0.7 = 0.84. Feedback: 1.2 - 0.7 = 0.5. Division: 1.2/0.7 = 1.714285714285714. Min/Max: 0.7 / 1.2.
# Abs(u = -0.7) = 0.7. MultiSum(nu = 3, k = [1, 2, -1]): 1.2 + 2*0.7 - 0.5 = 2.1.
@testset "Modelica.Blocks.Math" begin
    @named gain = Gain(; k = 2.5)
    @named add = Add(; k1 = 2, k2 = -1)
    @named add3 = Add3(; k3 = 3)
    @named product = Product()
    @named feedback = Feedback()
    @named division = Division()
    @named mn = Min()
    @named mx = Max()
    @named absb = Abs()
    @named msum = MultiSum(; nu = 3, k = [1, 2, -1])
    @named rig = System(Equation[
            gain.u ~ 1.2,
            add.u1 ~ 1.2, add.u2 ~ 0.7,
            add3.u1 ~ 1.2, add3.u2 ~ 0.7, add3.u3 ~ 0.5,
            product.u1 ~ 1.2, product.u2 ~ 0.7,
            feedback.u1 ~ 1.2, feedback.u2 ~ 0.7,
            division.u1 ~ 1.2, division.u2 ~ 0.7,
            mn.u1 ~ 1.2, mn.u2 ~ 0.7,
            mx.u1 ~ 1.2, mx.u2 ~ 0.7,
            absb.u ~ -0.7,
            msum.u[1] ~ 1.2, msum.u[2] ~ 0.7, msum.u[3] ~ 0.5,
        ], t, [], []; systems = [gain, add, add3, product, feedback, division, mn, mx, absb, msum])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.gain.y] ≈ 3.0 atol = 1e-9
    @test integ[sys.add.y] ≈ 1.7 atol = 1e-9
    @test integ[sys.add3.y] ≈ 3.4 atol = 1e-9
    @test integ[sys.product.y] ≈ 0.84 atol = 1e-9
    @test integ[sys.feedback.y] ≈ 0.5 atol = 1e-9
    @test integ[sys.division.y] ≈ 1.714285714285714 atol = 1e-9
    @test integ[sys.mn.y] ≈ 0.7 atol = 1e-9
    @test integ[sys.mx.y] ≈ 1.2 atol = 1e-9
    @test integ[sys.absb.y] ≈ 0.7 atol = 1e-9
    @test integ[sys.msum.y] ≈ 2.1 atol = 1e-9
end

# PolarToRectangular (PLAN-02): u_abs = 2, u_arg = pi/6 -> y_re = 2*cos(pi/6) = sqrt(3), y_im = 2*sin(pi/6) = 1.
@testset "Modelica.Blocks.Math.PolarToRectangular" begin
    @named p2r = PolarToRectangular()
    @named rig = System(Equation[p2r.u_abs ~ 2, p2r.u_arg ~ pi / 6], t, [], []; systems = [p2r])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.p2r.y_re] ≈ sqrt(3) atol = 1e-9
    @test integ[sys.p2r.y_im] ≈ 1.0 atol = 1e-9
end

# MultiProduct (PLAN-06, new in batch 6: TGTypeV/VI): nu = 2 -> 1.2*0.7 = 0.84; nu = 3 -> 1.2*0.7*0.5 = 0.42.
# Inside a system with an Integrator(k = 1, y_start = 0) fed by the nu = 2 product: y(1 s) = 0.84*1 = 0.84.
@testset "Modelica.Blocks.Math.MultiProduct" begin
    @named mp2 = MultiProduct(; nu = 2)
    @named mp3 = MultiProduct(; nu = 3)
    @named integ2 = Integrator(; k = 1, initType = :InitialState, y_start = 0.0)
    @named rig = System(Equation[
            mp2.u[1] ~ 1.2, mp2.u[2] ~ 0.7,
            mp3.u[1] ~ 1.2, mp3.u[2] ~ 0.7, mp3.u[3] ~ 0.5,
            integ2.u ~ mp2.y,
        ], t, [], []; systems = [mp2, mp3, integ2])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
    @test sol[sys.mp2.y][1] ≈ 0.84 atol = 1e-9
    @test sol[sys.mp3.y][1] ≈ 0.42 atol = 1e-9
    @test sol[sys.integ2.y][end] ≈ 0.84 atol = 1e-8
end

# Tan (PLAN-07, new in batch 7: REECA1/B1/CCU1 use it on the power-factor angle). y = tan(u):
# tan(0.7) = 0.8422883804630794, tan(-0.3) = -0.30933624960962325, tan(0) = 0.
@testset "Modelica.Blocks.Math.Tan" begin
    @named tn = Tan()
    @named tn2 = Tan()
    @named tn0 = Tan()
    @named rig = System(Equation[tn.u ~ 0.7, tn2.u ~ -0.3, tn0.u ~ 0.0], t, [], []; systems = [tn, tn2, tn0])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.tn.y] ≈ 0.8422883804630794 atol = 1e-9
    @test integ[sys.tn2.y] ≈ -0.30933624960962325 atol = 1e-9
    @test integ[sys.tn0.y] ≈ 0.0 atol = 1e-12
end

# Sin, Cos, MatrixGain, Pythagoras (PLAN-08, new in batch 8: GE_Generator's PLL, Cp_function's 5x5 matrix, the
# DIgSILENT CurrentLimiter). sin(0.7) = 0.644217687237691, cos(0.7) = 0.7648421872844885.
# MatrixGain(K = [1 2 3; 4 5 6]) on u = [1.2, 0.7, 0.5]: y = [1.2 + 1.4 + 1.5, 4.8 + 3.5 + 3.0] = [4.1, 11.3].
# Pythagoras(u1IsHypotenuse = false) on (3, 4): y = 5, valid = 1. Pythagoras(u1IsHypotenuse = true) on (5, 4): y = 3,
# valid = 1; on (3, 4): y2 = -7 < 0 -> y = 0, valid = 0.
@testset "Modelica.Blocks.Math Sin, Cos, MatrixGain, Pythagoras" begin
    @named sn = Sin()
    @named cs = Cos()
    @named mg = MatrixGain(; K = [1 2 3; 4 5 6])
    @named py = Pythagoras()
    @named pyh = Pythagoras(; u1IsHypotenuse = true)
    @named pyn = Pythagoras(; u1IsHypotenuse = true)
    @named rig = System(Equation[sn.u ~ 0.7, cs.u ~ 0.7,
            mg.u[1] ~ 1.2, mg.u[2] ~ 0.7, mg.u[3] ~ 0.5,
            py.u1 ~ 3, py.u2 ~ 4, pyh.u1 ~ 5, pyh.u2 ~ 4, pyn.u1 ~ 3, pyn.u2 ~ 4,
        ], t, [], []; systems = [sn, cs, mg, py, pyh, pyn])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.sn.y] ≈ 0.644217687237691 atol = 1e-9
    @test integ[sys.cs.y] ≈ 0.7648421872844885 atol = 1e-9
    @test integ[sys.mg.y[1]] ≈ 4.1 atol = 1e-9
    @test integ[sys.mg.y[2]] ≈ 11.3 atol = 1e-9
    @test integ[sys.py.y] ≈ 5.0 atol = 1e-9
    @test integ[sys.py.valid] ≈ 1 atol = 1e-9
    @test integ[sys.pyh.y] ≈ 3.0 atol = 1e-9
    @test integ[sys.pyh.valid] ≈ 1 atol = 1e-9
    @test integ[sys.pyn.y] ≈ 0.0 atol = 1e-9
    @test integ[sys.pyn.valid] ≈ 0 atol = 1e-9
    @test integ[sys.pyn.y2] ≈ -7.0 atol = 1e-9
end
