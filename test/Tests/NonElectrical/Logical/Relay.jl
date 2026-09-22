# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/NonElectrical/Logical/Relay.mo (a Test of this port, not OpenIPSL's: PLAN-12, family A),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# The block alone: a 0.5 Hz sine on u1 crosses zero at 0, 1, 2, 3 and 4 s, so the switch toggles between
# u2 = 2 and u3 = -2 four times inside the horizon. The block has no parameters. The Test function takes the
# suffix _Test because `Relay` is the model (PLAN-02 rule).
# `probe` is not in the .mo. The rig compiles to a system with **no unknowns** and the block registers exactly
# **one** continuous event, and that is the one combination ModelingToolkit 11 cannot integrate: its scalar
# callback path indexes `u[1]` and raises a `BoundsError` before the first step (F-91). Two or more events
# take the vector path and work, which is why the twin `Relay3` Test and the `SaturationBlockTan` one need
# nothing. One integrator of the switch output gives the problem a state and changes no oracle variable; its own
# value is checked here so the state is not dead weight.
@component function Relay_Test(; name)
    systems = @named begin
        relay = Relay()
        u1 = Sine(; amplitude = 1, f = 0.5)
        u2 = Constant(; k = 2)
        u3 = Constant(; k = -2)
    end
    @variables probe(t) = 0.0
    eqs = Equation[
        u1.y ~ relay.u1,   # connect(u1.y, relay.u1)
        u2.y ~ relay.u2,   # connect(u2.y, relay.u2)
        u3.y ~ relay.u3,   # connect(u3.y, relay.u3)
        D_nounits(probe) ~ relay.y,   # not in the .mo: one state for ModelingToolkit's callback path (F-91)
    ]
    System(eqs, t, [probe], []; name, systems)
end

@testset "PortTests.NonElectrical.Logical.Relay" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "NonElectrical.Logical.Relay.jl"))
    sol = validate_against_oracle(Relay_Test, oracle)
    # the integral of the switched output: +2 while sin(pi t) > 0 and -2 while it is not, from t = 0 to 4 s, so
    # the probe returns to 0 at every full period and sits at +2 at the end of each positive half period
    @test sol(1.0; idxs = sol.prob.f.sys.probe) ≈ 2 atol = 1e-5
    @test sol(2.0; idxs = sol.prob.f.sys.probe) ≈ 0 atol = 1e-5
    @test sol(4.0; idxs = sol.prob.f.sys.probe) ≈ 0 atol = 1e-5
end
