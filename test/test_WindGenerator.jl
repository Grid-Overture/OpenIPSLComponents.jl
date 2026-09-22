# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Electrical.Wind.WindGenerator (PLAN-08, batch 8): the three `typ`. typ = 1 (Wind.GE.WT_Test's defaults): Vw = v0 = 14.
# typ = 2 (gust, tstart = 5, tstop = 10, wmag = -4): Vw = v0 + wmag (1 - cos((t - 5) 2 pi/5))/2 inside the window:
#   Vw(4) = 14, Vw(6.25) = 12, Vw(7.5) = 10, Vw(8.75) = 12, Vw(11) = 14; the two edges are tstops of the block.
# typ = 3 (Mexican hat, the Wind.PSAT.WT_Test's shape with the GE speeds: v0 = 14, vmax = 25, tstart = 5, tstop = 15,
#   sigma = 1): Vw(10) = vmax = 25, Vw(9) = Vw(11) = v0 (the zeros of the hat at +-sigma), Vw(8) = Vw(12) = 14 +
#   11 (1 - 4) e^{-2} = 9.533935653191781, Vw(5) = Vw(15) = 14 + 11 (1 - 25) e^{-12.5} = 13.99901616356257.
@testset "Electrical.Wind.WindGenerator" begin
    @named w1 = WindGenerator()
    @named w2 = WindGenerator(; typ = 2)
    @named w3 = WindGenerator(; typ = 3, tstart = 5, tstop = 15)
    @variables x(t) = 0.0
    @named rig = System(Equation[D_nounits(x) ~ w2.Vw], t, [x], []; systems = [w1, w2, w3])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 15.0))
    own = prob.kwargs[:tstops]
    own = own isa AbstractVector ? own : own(prob.p, prob.tspan)
    @test sort(own) == [5.0, 10.0]
    sol = solve(prob, Rodas5P(); abstol = 1e-9, reltol = 1e-9, tstops = own)
    @test sol.retcode == ReturnCode.Success
    @test sol(3.0; idxs = sys.w1.Vw) ≈ 14.0 atol = 1e-12
    for (tk, v) in ((4.0, 14.0), (6.25, 12.0), (7.5, 10.0), (8.75, 12.0), (11.0, 14.0))
        @test sol(tk; idxs = sys.w2.Vw) ≈ v atol = 1e-9
    end
    # the integral of the gust over [0, 15]: 14 15 + wmag/2 5 = 210 - 10 = 200
    @test sol(15.0; idxs = sys.x) ≈ 200.0 atol = 1e-6
    for (tk, v) in ((5.0, 13.99901616356257), (8.0, 9.533935653191781), (9.0, 14.0), (10.0, 25.0), (11.0, 14.0),
                    (12.0, 9.533935653191781), (15.0, 13.99901616356257))
        @test sol(tk; idxs = sys.w3.Vw) ≈ v atol = 1e-9
    end
end
