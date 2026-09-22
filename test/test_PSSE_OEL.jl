# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Hand test (batch 12, PLAN-12 phase 4): the four branches of Electrical/Controls/PSSE/OEL/IF_comparisor.mo, which
# the Test of `PSSE_OEL` cannot all reach from one operating point (F-90), and the shape of the whole limiter.
#
# With the .mo's defaults IFD1 = 1.1, IFD2 = 1.2, IFD3 = 1.5 the three thresholds are
#   HL = 1 - IFD1 = -0.1,  ML = 1 - IFD2 = -0.2,  LL = 1 - IFD3 = -0.5
# and the four branches of the `if` are
#   p >= -0.1            -> n1 = 100, n2 = n3 = n4 = 0
#   -0.2 <= p < -0.1     -> n2 = -0.1, the rest 0
#   -0.5 <= p < -0.2     -> n3 = -0.2, the rest 0
#   p < -0.5             -> n4 = -0.5, the rest 0
# A ramp p = -0.7 + 0.2 t over [0, 5] visits them in order: p = -0.7 at t = 0, crosses LL at t = 1, ML at t = 2.5
# and HL at t = 3. The three crossings are continuous events, so each must be a solution time (to 1e-6).
@testset "PSSE OEL IF_comparisor branches" begin
    @named cmp = IF_comparisor()
    @variables p(t)
    @named rig = System(Equation[cmp.p ~ p, p ~ -0.7 + 0.2t], t, [p], []; systems = [cmp])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 5.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    for (tk, n1, n2, n3, n4) in ((0.5, 0, 0, 0, -0.5), (1.5, 0, 0, -0.2, 0), (2.8, 0, -0.1, 0, 0), (4.0, 100, 0, 0, 0))
        @test sol(tk; idxs = sys.cmp.n1) ≈ n1 atol = 1e-9
        @test sol(tk; idxs = sys.cmp.n2) ≈ n2 atol = 1e-9
        @test sol(tk; idxs = sys.cmp.n3) ≈ n3 atol = 1e-9
        @test sol(tk; idxs = sys.cmp.n4) ≈ n4 atol = 1e-9
    end
    for tk in (1.0, 2.5, 3.0)
        @test minimum(abs.(sol.t .- tk)) < 1e-6      # each threshold crossing is a solution time
    end
end

# The limiter as a whole, with the same ramp on the field current: IFD = 1.3 + 0.2 t and IFDdes = 2 put
# p = IFD - IFDdes = -0.7 + 0.2 t, i.e. the ramp above.
# The four LimIntegrators start at y = 0, 6, 6 and 7.5 against limits [Vmin, Vmax] = [-0.05, 0], so three of the
# four start far outside their own limiter (sic, F-90). `der(y) = 0` whenever `y > outMax and k u > 0` or
# `y < outMin and k u < 0`, so:
#   - imLimitedIntegrator (y = 0 = outMax) sees u = n1 >= 0 and never moves: y stays 0 for the whole run.
#   - imLimitedIntegrator1 (y = 6) sees u = n2 = -0.1 only while -0.2 <= p < -0.1, i.e. t in [2.5, 3]: it falls
#     at 0.1/s for 0.5 s, from 6 to 5.95, and holds.
#   - imLimitedIntegrator2 (y = 6) sees u = n3 = -0.2 while -0.5 <= p < -0.2, i.e. t in [1, 2.5]: 6 - 0.2*1.5 = 5.7.
#   - imLimitedIntegrator3 (y = 7.5) sees u = n4 = -0.5 while p < -0.5, i.e. t in [0, 1]: 7.5 - 0.5 = 7.0.
# so VOEL = 0 + 5.95 + 5.7 + 7.0 = 18.65 at t = 5, from 0 + 6 + 6 + 7.5 = 19.5 at t = 0.
@testset "PSSE OEL VOEL" begin
    @named oel = PSSE_OEL(; IFDdes = 2)
    @named rig = System(Equation[oel.IFD ~ 1.3 + 0.2t], t, [], []; systems = [oel])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 5.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.0; idxs = sys.oel.VOEL) ≈ 19.5 atol = 1e-6
    @test sol(5.0; idxs = sys.oel.imLimitedIntegrator.y) ≈ 0 atol = 1e-6
    @test sol(5.0; idxs = sys.oel.imLimitedIntegrator1.y) ≈ 5.95 atol = 1e-5
    @test sol(5.0; idxs = sys.oel.imLimitedIntegrator2.y) ≈ 5.7 atol = 1e-5
    @test sol(5.0; idxs = sys.oel.imLimitedIntegrator3.y) ≈ 7.0 atol = 1e-5
    @test sol(5.0; idxs = sys.oel.VOEL) ≈ 18.65 atol = 1e-5
end
