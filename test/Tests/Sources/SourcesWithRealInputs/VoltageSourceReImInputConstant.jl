# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Sources/SourcesWithRealInputs/VoltageSourceReImInputConstant.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
@component function VoltageSourceReImInputConstant(; name, S_b = 100e6, fn = 50, mods = (;))
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    vRe = redeclared(mods, :vRe, Constant)(; name = :vRe, modified(mods, :vRe, (; k = 1))...)
    vIm = redeclared(mods, :vIm, Constant)(; name = :vIm, modified(mods, :vIm, (; k = 0))...)
    vSource = redeclared(mods, :vSource, VoltageSourceReImInput)(; name = :vSource, modified(mods, :vSource, (; S_b, fn))...)
    systems = [vRe, vIm, vSource]
    eqs = Equation[
        connect(vSource.p, GEN1.p),
        vIm.y ~ vSource.vIm,   # connect(vIm.y, vSource.vIm)
        vRe.y ~ vSource.vRe,   # connect(vRe.y, vSource.vRe)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Sources.SourcesWithRealInputs.VoltageSourceReImInputConstant" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Sources.SourcesWithRealInputs.VoltageSourceReImInputConstant.jl"))
    # The ideal voltage source holds GEN1 at 1<0 and leaves the network purely algebraic: it has a second,
    # collapsed-voltage root (LOAD.v = 4e-13) that an exact Newton reaches from SMIB's start values, whose LOAD angle
    # (-0.5762684 rad, the power flow of the machine case) is eleven times the operating point's (-0.0521 rad).
    # Levenberg-Marquardt from the same start values lands on the operating point, 2e-9 from the oracle at t = 0 (F-30).
    validate_against_oracle(VoltageSourceReImInputConstant, oracle; nlsolve = LevenbergMarquardt())
end
