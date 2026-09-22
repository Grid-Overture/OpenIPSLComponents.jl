# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/NonElectrical/Nonlinear/Div0Block.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function Div0Block(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        div0block1 = Div0block(; )
        num = RealExpression(; expr = 1.0)
        den = RealExpression(; expr = 0.0)
    end
    eqs = Equation[
        num.y ~ div0block1.u1,   # connect(num.y, div0block1.u1)
        den.y ~ div0block1.u2,   # connect(den.y, div0block1.u2)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.NonElectrical.Nonlinear.Div0Block" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "NonElectrical.Nonlinear.Div0Block.jl"))
    validate_against_oracle(Div0Block, oracle)
end
