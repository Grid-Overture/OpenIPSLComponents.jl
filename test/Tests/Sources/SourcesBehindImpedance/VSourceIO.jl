# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Sources/SourcesBehindImpedance/VSourceIO.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
@component function VSourceIO_Test(; name, S_b = 100e6, fn = 50)   # `VSourceIO` is the model (PLAN-02: suffix _Test)
    @named base = SMIB(; S_b, fn, mods = (; pwFault = (; R = 1e-6, X = 1e-3, t1 = 2, t2 = 2.05)))
    @unpack GEN1 = base
    systems = @named begin
        VSIO = VSourceIO(; P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, angle_0 = 0.070492225331847, M_b = S_b, S_b, fn)
        DEang = Ramp(; height = deg2rad(20), duration = 3, startTime = 6)
        DEm = Ramp(; height = 0.3, duration = 1, startTime = 4)
    end
    eqs = Equation[
        connect(VSIO.p, GEN1.p),
        DEm.y ~ VSIO.uDEmag,   # connect(DEm.y, VSIO.uDEmag)
        DEang.y ~ VSIO.uDEang,   # connect(DEang.y, VSIO.uDEang)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Sources.SourcesBehindImpedance.VSourceIO" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Sources.SourcesBehindImpedance.VSourceIO.jl"))
    validate_against_oracle(VSourceIO_Test, oracle)
end
