# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/NonElectrical/Continuous/SimpleLagRateLimVar.mo (a Test of this port, not OpenIPSL's:
# PLAN-12, family A), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# The block alone, with the two output limits as constant signals that bite before the rate limit is reached.
# The .mo declares no defaults either, so every parameter is this port's. The Test function takes the suffix
# _Test because `SimpleLagRateLimVar` is the model (PLAN-02 rule).
@component function SimpleLagRateLimVar_Test(; name)
    systems = @named begin
        simpleLagRateLimVar = SimpleLagRateLimVar(; T = 0.5, y_start = 0, rmin = -0.5, rmax = 0.5)
        u = Step(; height = 2, startTime = 1)
        outMax = Constant(; k = 0.8)
        outMin = Constant(; k = -0.8)
    end
    eqs = Equation[
        u.y ~ simpleLagRateLimVar.u,   # connect(u.y, simpleLagRateLimVar.u)
        outMax.y ~ simpleLagRateLimVar.outMax,   # connect(outMax.y, simpleLagRateLimVar.outMax)
        outMin.y ~ simpleLagRateLimVar.outMin,   # connect(outMin.y, simpleLagRateLimVar.outMin)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "PortTests.NonElectrical.Continuous.SimpleLagRateLimVar" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "NonElectrical.Continuous.SimpleLagRateLimVar.jl"))
    validate_against_oracle(SimpleLagRateLimVar_Test, oracle)
end
