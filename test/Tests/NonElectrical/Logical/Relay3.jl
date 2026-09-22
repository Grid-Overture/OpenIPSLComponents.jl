# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/NonElectrical/Logical/Relay3.mo (a Test of this port, not OpenIPSL's: PLAN-12, family A),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# The block alone with its own default `Vov = 0.5`: a 0.5 Hz sine on u1 crosses +0.5 and -0.5 twice each inside
# the horizon, so the output visits u3 = 1, u2 = 0 and u4 = -1. This is the Test that brings
# Modelica.Blocks.Logical.LessThreshold into the mini-MSL. The Test function takes the suffix _Test because
# `Relay3` is the model (PLAN-02 rule).
@component function Relay3_Test(; name)
    systems = @named begin
        relay3 = Relay3()
        u1 = Sine(; amplitude = 1, f = 0.5)
        u2 = Constant(; k = 0)
        u3 = Constant(; k = 1)
        u4 = Constant(; k = -1)
    end
    eqs = Equation[
        u1.y ~ relay3.u1,   # connect(u1.y, relay3.u1)
        u2.y ~ relay3.u2,   # connect(u2.y, relay3.u2)
        u3.y ~ relay3.u3,   # connect(u3.y, relay3.u3)
        u4.y ~ relay3.u4,   # connect(u4.y, relay3.u4)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "PortTests.NonElectrical.Logical.Relay3" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "NonElectrical.Logical.Relay3.jl"))
    validate_against_oracle(Relay3_Test, oracle)
end
