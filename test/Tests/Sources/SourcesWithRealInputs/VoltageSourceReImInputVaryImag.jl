# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Sources/SourcesWithRealInputs/VoltageSourceReImInputVaryImag.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: SourcesWithRealInputs.VoltageSourceReImInputConstant. Omitted: graphical annotations, displayPF.
@component function VoltageSourceReImInputVaryImag(; name, S_b = 100e6, fn = 50)
    @named base = VoltageSourceReImInputConstant(; S_b, fn, mods = (; vIm = (; redeclare = Ramp, height = 3.14/8, duration = 2.5, startTime = 5)))
    eqs = Equation[
    ]
    extend(System(eqs, t, [], []; name, systems = System[]), base)
end

@testset "Tests.Sources.SourcesWithRealInputs.VoltageSourceReImInputVaryImag" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Sources.SourcesWithRealInputs.VoltageSourceReImInputVaryImag.jl"))
    # The ideal voltage source holds GEN1 at 1<0 and leaves the network purely algebraic: it has a second,
    # collapsed-voltage root (LOAD.v = 4e-13) that an exact Newton reaches from SMIB's start values, whose LOAD angle
    # (-0.5762684 rad, the power flow of the machine case) is eleven times the operating point's (-0.0521 rad).
    # Levenberg-Marquardt from the same start values lands on the operating point, 2e-9 from the oracle at t = 0 (F-30).
    validate_against_oracle(VoltageSourceReImInputVaryImag, oracle; nlsolve = LevenbergMarquardt())
end
