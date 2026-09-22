# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSAT/TG/TGTypeII_test.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.TGTestBase. Omitted: graphical annotations, displayPF.
# `tGtypeII(S_b = SysData.S_b)` is the keyword argument S_b. `Sn = 20e6` is the .mo's default, the same rating as
# `gen`, so Ro = R = 0.2 and pmax = 0.2 here.
@component function TGTypeII_test(; name, S_b = 100e6, fn = 50)
    @named base = TGTestBase(; S_b, fn)
    @unpack gen = base
    systems = @named begin
        tGtypeII = TGTypeII(; S_b)
    end
    eqs = Equation[
        gen.pm ~ tGtypeII.pm,     # connect(tGtypeII.pm, gen.pm)
        tGtypeII.w ~ gen.w,       # connect(tGtypeII.w, gen.w)
        tGtypeII.pm0 ~ gen.pm0,   # connect(tGtypeII.pm0, gen.pm0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSAT.TG.TGTypeII_test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSAT.TG.TGTypeII_test.jl"))
    # the TransferFunction keeps MSL's NoInit, so its state has no initialization equation and the system is one
    # short; OpenModelica fixes it at its own start, x[1] = 0 (F-28, confirmed in row 0 of the oracle)
    validate_against_oracle(TGTypeII_test, oracle;
        u0 = sys -> [sys.tGtypeII.transferFunction1.x_scaled => [0.0]])
end
