# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Sources/SourcesBehindImpedance/VSourceIO_StartFromExternal_using_RealExpression.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
@component function VSourceIO_StartFromExternal_using_RealExpression(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn, mods = (; pwFault = (; R = 1e-6, X = 1e-3, t1 = 2, t2 = 2.05)))
    @unpack GEN1 = base
    systems = @named begin
        VSIO = VSourceIO(; P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, angle_0 = 0.070492225331847, M_b = S_b, useEphasorInternalAsInput = false, S_b, fn)
        DEm = Ramp(; height = 0.3, duration = 1, startTime = 4)
        addE0_DE = Add(; )
        addEang_DEang = Add(; )
        DEang = Ramp(; height = deg2rad(20), duration = 3, startTime = 6)
        E0 = RealExpression(; expr = nothing)   # y = VSIO.Emag0: written below as the parent's equation (F-22)
        delta0 = RealExpression(; expr = nothing)   # y = VSIO.Eang0
    end
    eqs = Equation[
        connect(VSIO.p, GEN1.p),
        addE0_DE.y ~ VSIO.uDEmag,   # connect(addE0_DE.y, VSIO.uDEmag)
        addEang_DEang.y ~ VSIO.uDEang,   # connect(addEang_DEang.y, VSIO.uDEang)
        DEm.y ~ addE0_DE.u2,   # connect(DEm.y, addE0_DE.u2)
        DEang.y ~ addEang_DEang.u1,   # connect(DEang.y, addEang_DEang.u1)
        delta0.y ~ addEang_DEang.u2,   # connect(delta0.y, addEang_DEang.u2)
        E0.y ~ addE0_DE.u1,   # connect(E0.y, addE0_DE.u1)
        E0.y ~ VSIO.Emag0,   # E0(y = VSIO.Emag0)
        delta0.y ~ VSIO.Eang0,   # delta0(y = VSIO.Eang0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Sources.SourcesBehindImpedance.VSourceIO_StartFromExternal_using_RealExpression" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Sources.SourcesBehindImpedance.VSourceIO_StartFromExternal_using_RealExpression.jl"))
    validate_against_oracle(VSourceIO_StartFromExternal_using_RealExpression, oracle)
end
