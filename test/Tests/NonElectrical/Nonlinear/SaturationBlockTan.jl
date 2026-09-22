# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/NonElectrical/Nonlinear/SaturationBlockTan.mo (a Test of this port, not OpenIPSL's: PLAN-12,
# family A), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# The block alone with a ramp from -0.2 to 1.0 that crosses -0.1 and 0 inside the horizon, so the three branches of
# the `if` are all visited. `r` and `f` are this port's (the .mo has no defaults). The Test function takes the
# suffix _Test because `SaturationBlockTan` is the model (PLAN-02 rule).
@component function SaturationBlockTan_Test(; name)
    systems = @named begin
        saturationBlockTan = SaturationBlockTan(; r = 0.5, f = 0.1)
        p1 = Ramp(; height = 1.2, duration = 4, offset = -0.2, startTime = 0.5)
    end
    eqs = Equation[
        p1.y ~ saturationBlockTan.p1,   # connect(p1.y, saturationBlockTan.p1)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "PortTests.NonElectrical.Nonlinear.SaturationBlockTan" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "NonElectrical.Nonlinear.SaturationBlockTan.jl"))
    validate_against_oracle(SaturationBlockTan_Test, oracle)
end
