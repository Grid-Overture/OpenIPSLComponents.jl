# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Mini-MSL Blocks.Logical (PLAN-01), Boolean signals as Real 0/1. Input u = t - 1 over [0, 2].
# GreaterThreshold(threshold = 0.3): y = 0 at t = 1.2 (u = 0.2), 1 at t = 1.5; the crossing t = 1.3 is a continuous
#   event without affect, so 1.3 must be a solution time (to 1e-6). GreaterEqualThreshold(threshold = 0): 1 at t = 1.
# Switch: u2 = gt.y, u1 = 10, u3 = -10: y = -10 at t = 1.2, 10 at t = 1.5. Or(u1 = gt.y, u2 = ge.y): 0 at 0.5, 1 at 1.2.
@testset "Modelica.Blocks.Logical" begin
    @named gt = GreaterThreshold(; threshold = 0.3)
    @named ge = GreaterEqualThreshold(; threshold = 0)
    @named sw = Switch()
    @named orb = Or()
    @variables x(t) = 0.0
    @named rig = System(Equation[gt.u ~ t - 1, ge.u ~ t - 1, sw.u1 ~ 10, sw.u2 ~ gt.y, sw.u3 ~ -10, orb.u1 ~ gt.y, orb.u2 ~ ge.y,
            D_nounits(x) ~ sw.y], t, [x], []; systems = [gt, ge, sw, orb])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(1.2; idxs = sys.gt.y) ≈ 0 atol = 1e-9
    @test sol(1.5; idxs = sys.gt.y) ≈ 1 atol = 1e-9
    @test sol(1.0; idxs = sys.ge.y) ≈ 1 atol = 1e-9
    @test sol(0.5; idxs = sys.ge.y) ≈ 0 atol = 1e-9
    @test sol(1.2; idxs = sys.sw.y) ≈ -10 atol = 1e-9
    @test sol(1.5; idxs = sys.sw.y) ≈ 10 atol = 1e-9
    @test sol(0.5; idxs = sys.orb.y) ≈ 0 atol = 1e-9
    @test sol(1.2; idxs = sys.orb.y) ≈ 1 atol = 1e-9
    @test minimum(abs.(sol.t .- 1.3)) < 1e-6          # the threshold crossing is a solution time
    @test sol(2.0; idxs = sys.x) ≈ -10 * 1.3 + 10 * 0.7 atol = 1e-6   # integral of the switched signal
end

# ZeroCrossing (PLAN-02): y is identically 0; the parent registers the crossing of u as a continuous event. With
# u = x - 1, x' = 1 (x = t), and a parent event on zc.u ~ 0 whose affect counts crossings, n = 0 at t = 0.5, 1 at
# t = 1.5, and the crossing t = 1 is a solution time (to 1e-6).
@testset "Modelica.Blocks.Logical.ZeroCrossing" begin
    @named zc = ZeroCrossing()
    @variables x(t) = 0.0
    disc = @discretes begin
        n(t) = 0
    end
    count = ModelingToolkit.SymbolicContinuousCallback([zc.u ~ 0],
        ModelingToolkit.ImperativeAffect((m, o, ctx, integ) -> (; n = m.n + 1); modified = (; n)))
    @named rig = System(Equation[zc.u ~ x - 1, zc.enable ~ 1, D_nounits(x) ~ 1 + zc.y], t, [x], disc; systems = [zc],
        continuous_events = [count])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.5; idxs = sys.n) ≈ 0 atol = 1e-9
    @test sol(1.5; idxs = sys.n) ≈ 1 atol = 1e-9
    @test sol(1.5; idxs = sys.zc.y) ≈ 0 atol = 1e-9
    @test sol(2.0; idxs = sys.x) ≈ 2 atol = 1e-6
    @test minimum(abs.(sol.t .- 1.0)) < 1e-6
end

# Math.RealToBoolean and MathBoolean.And (PLAN-05), Boolean signals as Real 0/1. Input u = t - 1 over [0, 2].
# RealToBoolean(threshold = 0.5): y = 0 at t = 1.2 (u = 0.2), 1 at t = 1.8 (u = 0.8); the default threshold is 0.5.
# And(nu = 2) on (r2b.y, ge.y): 0 while either input is 0, 1 at t = 1.8 where both are 1; its integral over [0, 2] is
# 0.5 (the and is 1 from t = 1.5 on).
@testset "Modelica.Blocks.Math.RealToBoolean and MathBoolean.And" begin
    @named r2b = RealToBoolean()
    @named ge2 = GreaterEqualThreshold(; threshold = 0)
    @named and2 = And(; nu = 2)
    @variables xa(t) = 0.0
    @named rig = System(Equation[r2b.u ~ t - 1, ge2.u ~ t - 1, and2.u[1] ~ r2b.y, and2.u[2] ~ ge2.y,
            D_nounits(xa) ~ and2.y], t, [xa], []; systems = [r2b, ge2, and2])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9, saveat = [0.0, 1.2, 1.8, 2.0])
    @test sol.retcode == ReturnCode.Success
    @test sol(0.0; idxs = sys.r2b.y) ≈ 0 atol = 1e-9
    @test sol(1.2; idxs = sys.r2b.y) ≈ 0 atol = 1e-9
    @test sol(1.8; idxs = sys.r2b.y) ≈ 1 atol = 1e-9
    @test sol(0.0; idxs = sys.and2.y) ≈ 0 atol = 1e-9
    @test sol(1.2; idxs = sys.and2.y) ≈ 0 atol = 1e-9
    @test sol(1.8; idxs = sys.and2.y) ≈ 1 atol = 1e-9
    @test sol(2.0; idxs = sys.xa) ≈ 0.5 atol = 1e-6
end

# Not, Nor, Pre, Timer, RSFlipFlop (PLAN-08, batch 8: the sub-blocks of Picdro; F-73), Boolean signals as Real 0/1.
# Truth tables at fixed inputs: Not(1) = 0, Not(0) = 1; Nor(0, 0) = 1, Nor(1, 0) = Nor(0, 1) = Nor(1, 1) = 0.
# The pulse gt.y = (-cos(pi t/2) > 0) is 1 on (1, 3). Pre: y follows u from the jump (0 at 0.9, 1 at 1.001 and 2,
# 0 at 3.001). Timer: y = 0 at 0.9, t - 1 on (1, 3) (0.001 at 1.001, 1 at 2), 0 at 3.001; its integral over [0, 5]
# is int_1^3 (t - 1) dt = 2. RSFlipFlop with S on (1, 1.5), R on (2, 2.5) and both on (3, 3.5): Q = 1 from the set
# at 1 (1.25, 1.75) until the reset at 2 (0 at 2.25, 2.75), 0 while both are on (R dominant, 3.25), and 1 after both
# release at 3.5 (pre(nor.y) = 0 was latched during the both-on state, which is MSL's fixpoint): the integral of Q
# over [0, 4] is 1 + 0.5 = 1.5; QI = pre.y = 1 - Q except while both are on (Q = QI = 0).
@testset "Modelica.Blocks.Logical Not, Nor, Pre, Timer, RSFlipFlop" begin
    @named n1 = Not()
    @named n0 = Not()
    @named nr00 = Nor()
    @named nr10 = Nor()
    @named nr01 = Nor()
    @named nr11 = Nor()
    @named rig = System(Equation[n1.u ~ 1, n0.u ~ 0, nr00.u1 ~ 0, nr00.u2 ~ 0, nr10.u1 ~ 1, nr10.u2 ~ 0,
            nr01.u1 ~ 0, nr01.u2 ~ 1, nr11.u1 ~ 1, nr11.u2 ~ 1], t, [], []; systems = [n1, n0, nr00, nr10, nr01, nr11])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.n1.y] ≈ 0 atol = 1e-12
    @test integ[sys.n0.y] ≈ 1 atol = 1e-12
    @test integ[sys.nr00.y] ≈ 1 atol = 1e-12
    @test integ[sys.nr10.y] ≈ 0 atol = 1e-12
    @test integ[sys.nr01.y] ≈ 0 atol = 1e-12
    @test integ[sys.nr11.y] ≈ 0 atol = 1e-12

    @named gt = GreaterThreshold(; threshold = 0)
    @named pr = Pre_()
    @named tm = Timer_()
    @variables xt(t) = 0.0
    @named rig2 = System(Equation[gt.u ~ -cos(pi * t / 2), pr.u ~ gt.y, tm.u ~ gt.y, D_nounits(xt) ~ tm.y], t, [xt], [];
        systems = [gt, pr, tm])
    sys2 = mtkcompile(rig2)
    sol2 = solve(ODEProblem(sys2, [], (0.0, 5.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol2.retcode == ReturnCode.Success
    @test sol2(0.9; idxs = sys2.pr.y) ≈ 0 atol = 1e-12
    @test sol2(1.001; idxs = sys2.pr.y) ≈ 1 atol = 1e-12
    @test sol2(2.0; idxs = sys2.pr.y) ≈ 1 atol = 1e-12
    @test sol2(3.001; idxs = sys2.pr.y) ≈ 0 atol = 1e-12
    @test sol2(0.9; idxs = sys2.tm.y) ≈ 0 atol = 1e-12
    @test sol2(1.001; idxs = sys2.tm.y) ≈ 0.001 atol = 1e-6
    @test sol2(2.0; idxs = sys2.tm.y) ≈ 1.0 atol = 1e-6
    @test sol2(3.001; idxs = sys2.tm.y) ≈ 0 atol = 1e-12
    @test sol2(5.0; idxs = sys2.xt) ≈ 2.0 atol = 1e-6

    @named ff = RSFlipFlop()
    @named bS = BooleanExpression(; expr = ((t > 1) & (t < 1.5)) | ((t > 3) & (t < 3.5)))
    @named bR = BooleanExpression(; expr = ((t > 2) & (t < 2.5)) | ((t > 3) & (t < 3.5)))
    @variables xq(t) = 0.0
    @named rig3 = System(Equation[ff.S ~ bS.y, ff.R ~ bR.y, D_nounits(xq) ~ ff.Q], t, [xq], []; systems = [ff, bS, bR])
    sys3 = mtkcompile(rig3)
    sol3 = solve(ODEProblem(sys3, [], (0.0, 4.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9, tstops = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5])
    @test sol3.retcode == ReturnCode.Success
    for (tk, q, qi) in ((0.5, 0, 1), (1.25, 1, 0), (1.75, 1, 0), (2.25, 0, 1), (2.75, 0, 1), (3.25, 0, 0), (3.75, 1, 0))
        @test sol3(tk; idxs = sys3.ff.Q) ≈ q atol = 1e-12
        @test sol3(tk; idxs = sys3.ff.QI) ≈ qi atol = 1e-12
    end
    @test sol3(4.0; idxs = sys3.xq) ≈ 1.5 atol = 1e-6
end

# Xor, And (Logical_And) and LessEqualThreshold (PLAN-10, batch 10: the blocks only `Examples.OpenCPS` instantiates).
# Truth tables of Xor and Logical_And on the four constant input pairs, and LessEqualThreshold(threshold = 0.3) on the
# ramp u = t - 1 over [0, 2]: y = 1 at t = 1.2 (u = 0.2), 0 at t = 1.5 (u = 0.5), and the crossing t = 1.3 is a
# continuous event without affect, so it must be a solution time (to 1e-6); it is the mirror image of
# GreaterThreshold's above. Its integral over [0, 2] is 1.3.
@testset "Modelica.Blocks.Logical.Xor, And and LessEqualThreshold" begin
    pairs = ((0, 0), (1, 0), (0, 1), (1, 1))
    xors = [Xor(; name = Symbol("xor_", i)) for i in eachindex(pairs)]
    ands = [Logical_And(; name = Symbol("and_", i)) for i in eachindex(pairs)]
    eqs = Equation[]
    for (i, (a, b)) in enumerate(pairs)
        append!(eqs, [xors[i].u1 ~ a, xors[i].u2 ~ b, ands[i].u1 ~ a, ands[i].u2 ~ b])
    end
    @named rig = System(eqs, t, [], []; systems = [xors; ands])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    for (i, (a, b)) in enumerate(pairs)
        @test integ[getproperty(sys, Symbol("xor_", i)).y] ≈ (a == b ? 0 : 1) atol = 1e-12
        @test integ[getproperty(sys, Symbol("and_", i)).y] ≈ (a == 1 && b == 1 ? 1 : 0) atol = 1e-12
    end

    @named le = LessEqualThreshold(; threshold = 0.3)
    @variables xl(t) = 0.0
    @named rig2 = System(Equation[le.u ~ t - 1, D_nounits(xl) ~ le.y], t, [xl], []; systems = [le])
    sys2 = mtkcompile(rig2)
    sol = solve(ODEProblem(sys2, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(1.2; idxs = sys2.le.y) ≈ 1 atol = 1e-9
    @test sol(1.5; idxs = sys2.le.y) ≈ 0 atol = 1e-9
    @test minimum(abs.(sol.t .- 1.3)) < 1e-6          # the threshold crossing is a solution time
    @test sol(2.0; idxs = sys2.xl) ≈ 1.3 atol = 1e-6
end

# LessThreshold (batch 12, the twin of GreaterThreshold; it comes in with NonElectrical.Logical.Relay3). Input
# u = t - 1 over [0, 2] and threshold -0.3: y = 1 while u < -0.3 (t < 0.7) and 0 afterwards, and the crossing
# t = 0.7 is a continuous event without affect, so it must be a solution time. The comparison is strict, so at
# exactly u = -0.3 the output is already 0.
@testset "Modelica.Blocks.Logical.LessThreshold" begin
    @named lt = LessThreshold(; threshold = -0.3)
    @variables x(t) = 0.0
    @named rig = System(Equation[lt.u ~ t - 1, D_nounits(x) ~ lt.y], t, [x], []; systems = [lt])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.5; idxs = sys.lt.y) ≈ 1 atol = 1e-9
    @test sol(1.2; idxs = sys.lt.y) ≈ 0 atol = 1e-9
    @test minimum(abs.(sol.t .- 0.7)) < 1e-6          # the threshold crossing is a solution time
    @test sol(2.0; idxs = sys.x) ≈ 0.7 atol = 1e-6    # the integral of the gate is the time it was open
end
