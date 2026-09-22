# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/NonElectrical/Continuous/SimpleLagRateLimBlock.mo (a Test of this port, not OpenIPSL's:
# PLAN-12, family A), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# The block alone: a step of 2 on `u` at 1 s asks for more than the rate limit and more than the output limiter
# allow, and a step of 1 on `Block` at 4 s freezes the state. The .mo declares no defaults, so every parameter is
# this port's. `SimpleLagRateLimBlock` is the model, so the Test function takes the suffix _Test (PLAN-02 rule);
# `block_` is the Modelica instance `block_`, already suffixed there because `block` is a Modelica keyword.
@component function SimpleLagRateLimBlock_Test(; name)
    systems = @named begin
        simpleLagRateLimBlock = SimpleLagRateLimBlock(; K = 1, T = 0.5, y_start = 0, outMax = 1, outMin = -1, rmin = -0.5, rmax = 0.5)
        u = Step(; height = 2, startTime = 1)
        block_ = Step(; height = 1, startTime = 4)
    end
    eqs = Equation[
        u.y ~ simpleLagRateLimBlock.u,   # connect(u.y, simpleLagRateLimBlock.u)
        block_.y ~ simpleLagRateLimBlock.Block,   # connect(block_.y, simpleLagRateLimBlock.Block)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "PortTests.NonElectrical.Continuous.SimpleLagRateLimBlock" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "NonElectrical.Continuous.SimpleLagRateLimBlock.jl"))
    validate_against_oracle(SimpleLagRateLimBlock_Test, oracle)
end
