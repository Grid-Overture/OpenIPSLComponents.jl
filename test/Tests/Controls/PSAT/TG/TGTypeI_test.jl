# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSAT/TG/TGTypeI_test.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.TGTestBase. Omitted: graphical annotations, displayPF.
# The Test redeclares `parameter Real p0` with the same value the base carries, so it is the base's keyword argument.
@component function TGTypeI_test(; name, S_b = 100e6, fn = 50, p0 = 0.160352698692006)
    @named base = TGTestBase(; S_b, fn, p0)
    @unpack gen = base
    systems = @named begin
        tGTypeI = TGTypeI(; wref = 1.0, pref = p0, R = 0.2, pmax = 1.0, pmin = 0.0, Ts = 0.1, Tc = 1.0, T3 = 0.04,
            T4 = 5.0, T5 = 0.04)
    end
    eqs = Equation[
        gen.pm ~ tGTypeI.pm,   # connect(tGTypeI.pm, gen.pm)
        tGTypeI.w ~ gen.w,     # connect(tGTypeI.w, gen.w)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSAT.TG.TGTypeI_test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSAT.TG.TGTypeI_test.jl"))
    validate_against_oracle(TGTypeI_test, oracle)
end
