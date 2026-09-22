# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Mini-MSL Blocks.Sources (PLAN-01): sampled before/at/after startTime (tstops of the blocks make the solver step onto it).
# Constant(k = 0.3) = 0.3. RealExpression(expr = 2*0.3) = 0.6. BooleanConstant(k = true) = 1, (k = false) = 0.
# BooleanExpression(expr = t > 0.5): 0 at t = 0.25, 1 at t = 0.75.
# Step(height = 2, offset = 0.5, startTime = 0.5): 0.5 at 0.25, 2.5 at 0.75.
# Ramp(height = 2, duration = 1, offset = 0.5, startTime = 0.5): 0.5 at 0.25, 0.5 + 2*(0.75-0.5)/1 = 1.0 at 0.75, 2.5 at 2.
# Sine(amplitude = 2, f = 0.25, phase = pi/2, offset = 0.5, startTime = 0.5): 0.5 at 0.25;
#   at t = 1.5: 0.5 + 2*sin(2*pi*0.25*1.0 + pi/2) = 0.5 + 2*cos(pi/2) = 0.5; at t = 0.5: 0.5 + 2*sin(pi/2) = 2.5 (from the right).
@testset "Modelica.Blocks.Sources" begin
    @named c = Constant(; k = 0.3)
    @named re = RealExpression(; expr = 2 * 0.3)
    @named bt = BooleanConstant(; k = true)
    @named bf = BooleanConstant(; k = false)
    @named be = BooleanExpression(; expr = t > 0.5)
    @named st = Step(; height = 2, offset = 0.5, startTime = 0.5)
    @named ra = Ramp(; height = 2, duration = 1, offset = 0.5, startTime = 0.5)
    @named si = Sine(; amplitude = 2, f = 0.25, phase = pi / 2, offset = 0.5, startTime = 0.5)
    @variables x(t) = 0.0
    @named rig = System(Equation[D_nounits(x) ~ st.y], t, [x], []; systems = [c, re, bt, bf, be, st, ra, si])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.25; idxs = sys.c.y) ≈ 0.3 atol = 1e-9
    @test sol(0.25; idxs = sys.re.y) ≈ 0.6 atol = 1e-9
    @test sol(0.25; idxs = sys.bt.y) ≈ 1 atol = 1e-9
    @test sol(0.25; idxs = sys.bf.y) ≈ 0 atol = 1e-9
    @test sol(0.25; idxs = sys.be.y) ≈ 0 atol = 1e-9
    @test sol(0.75; idxs = sys.be.y) ≈ 1 atol = 1e-9
    @test sol(0.25; idxs = sys.st.y) ≈ 0.5 atol = 1e-9
    @test sol(0.75; idxs = sys.st.y) ≈ 2.5 atol = 1e-9
    @test sol(0.25; idxs = sys.ra.y) ≈ 0.5 atol = 1e-9
    @test sol(0.75; idxs = sys.ra.y) ≈ 1.0 atol = 1e-9
    @test sol(2.0; idxs = sys.ra.y) ≈ 2.5 atol = 1e-9
    @test sol(0.25; idxs = sys.si.y) ≈ 0.5 atol = 1e-9
    @test sol(1.5; idxs = sys.si.y) ≈ 0.5 atol = 1e-6
    # the step's tstop: the integral of st.y is exactly 0.5*t before and 0.5*0.5 + 2.5*(t - 0.5) after startTime
    @test sol(2.0; idxs = sys.x) ≈ 0.25 + 2.5 * 1.5 atol = 1e-6
    @test 0.5 in sol.t
end

# BooleanStep (PLAN-10, batch 10). `y = if time >= startTime then not startValue else startValue`, as Real 0/1 and
# with `Step`'s discrete event at startTime (F-25). Three instances: the default `startValue = false` stepping up at
# t = 0.5, its `startValue = true` twin stepping down at the same instant, and one whose startTime (5 s) is beyond
# the 2 s horizon, so that it never switches and its `tstop` falls outside `tspan`. The integral of the first is
# 1.5 and 0.5 is a solution time.
@testset "Modelica.Blocks.Sources.BooleanStep" begin
    @named bs = BooleanStep(; startTime = 0.5)
    @named bsT = BooleanStep(; startTime = 0.5, startValue = true)
    @named bsLate = BooleanStep(; startTime = 5)
    @variables xb(t) = 0.0
    @named rig = System(Equation[D_nounits(xb) ~ bs.y], t, [xb], []; systems = [bs, bsT, bsLate])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.25; idxs = sys.bs.y) ≈ 0 atol = 1e-12
    @test sol(0.75; idxs = sys.bs.y) ≈ 1 atol = 1e-12
    @test sol(0.25; idxs = sys.bsT.y) ≈ 1 atol = 1e-12
    @test sol(0.75; idxs = sys.bsT.y) ≈ 0 atol = 1e-12
    @test sol(0.25; idxs = sys.bsLate.y) ≈ 0 atol = 1e-12
    @test sol(2.0; idxs = sys.bsLate.y) ≈ 0 atol = 1e-12
    @test sol(2.0; idxs = sys.xb) ≈ 1.5 atol = 1e-6
    @test 0.5 in sol.t
end
