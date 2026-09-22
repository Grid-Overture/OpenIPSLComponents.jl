# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSAT/TG/TGTypeIV_test.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.TGTestBase. Omitted: graphical annotations, displayPF.
@component function TGTypeIV_test(; name, S_b = 100e6, fn = 50)
    @named base = TGTestBase(; S_b, fn)
    @unpack gen = base
    systems = @named begin
        tGTypeIV = TGTypeIV(; Ki = 0.105, Tg = 0.2, Tp = 0.04, delta = 0.3, sigma = 0.05, Tr = 5.0, vmin = -0.1,
            vmax = 0.1, gmax = 1.0, gmin = 0.0, Tw = 1.0, a11 = 0.5, a13 = 1.0, a21 = 1.5, a23 = 1.0, Kp = 1.163,
            Pref = 0.080199, wref = 1.0)
    end
    eqs = Equation[
        gen.pm ~ tGTypeIV.Pm,   # connect(tGTypeIV.Pm, gen.pm)
        tGTypeIV.w ~ gen.w,     # connect(tGTypeIV.w, gen.w)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSAT.TG.TGTypeIV_test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSAT.TG.TGTypeIV_test.jl"))
    # the five Integrator(NoInit) carry no initialization equation, so the system is five equations short;
    # OpenModelica fixes them at their own y_start, int1..int5 (F-28, confirmed in row 0 of the oracle)
    Pref = 0.080199
    validate_against_oracle(TGTypeIV_test, oracle;
        u0 = sys -> [sys.tGTypeIV.integrator1.y => 0.05 * Pref,          # int1 = sigma*Pref
            sys.tGTypeIV.integrator2.y => 0.0,                            # int2 = 0
            sys.tGTypeIV.integrator3.y => Pref,                           # int3 = Pref
            sys.tGTypeIV.integrator4.y => 5.0 * Pref,                     # int4 = Tr*Pref
            sys.tGTypeIV.integrator5.y => 1.0 * 1.5 / 0.5 * Pref])        # int5 = a13*a21/a11*Pref
end
