# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Sources/SourcesWithRealInputs/CurrentSourceReImInputConstant.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
@component function CurrentSourceReImInputConstant(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        vRe = Constant(; k = 1)
        vIm = Constant(; k = 0)
        iSource = CurrentSourceReImInput(; S_b, fn)
    end
    eqs = Equation[
        connect(iSource.p, GEN1.p),
        iSource.iRe ~ vRe.y,   # connect(iSource.iRe, vRe.y)
        iSource.iIm ~ vIm.y,   # connect(iSource.iIm, vIm.y)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Sources.SourcesWithRealInputs.CurrentSourceReImInputConstant" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Sources.SourcesWithRealInputs.CurrentSourceReImInputConstant.jl"))
    validate_against_oracle(CurrentSourceReImInputConstant, oracle)
end
