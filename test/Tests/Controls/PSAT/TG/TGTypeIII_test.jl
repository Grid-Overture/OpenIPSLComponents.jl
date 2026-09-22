# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSAT/TG/TGTypeIII_test.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.TGTestBase. Omitted: graphical annotations, displayPF.
# `P_0 = 0.1` is not the base's power flow (p0 = 0.1604) and `int3 = 2.712336`, so the governor does not start in
# equilibrium: `gen.pm(0) = 2.51` pu and the machine runs away in the oracle too (w -> 2.09, delta -> 2556 rad at
# 10 s). That is the Test as OpenIPSL wrote it.
@component function TGTypeIII_test(; name, S_b = 100e6, fn = 50)
    @named base = TGTestBase(; S_b, fn)
    @unpack gen = base
    systems = @named begin
        tGTypeIII = TGTypeIII(; Tg = 0.2, Tp = 0.04, delta = 0.3, sigma = 0.04, Tr = 5.0, vmin = -0.1, vmax = 0.1,
            gmax = 1.0, gmin = 0.0, Tw = 1.0, a11 = 0.5, a13 = 1.0, a21 = 1.5, a23 = 1.0, int3 = 2.712336,
            P_0 = 0.1)
    end
    eqs = Equation[
        gen.pm ~ tGTypeIII.pm,   # connect(tGTypeIII.pm, gen.pm)
        tGTypeIII.w ~ gen.w,     # connect(tGTypeIII.w, gen.w)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSAT.TG.TGTypeIII_test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSAT.TG.TGTypeIII_test.jl"))
    # the four Integrator(NoInit) carry no initialization equation, so the system is four equations short;
    # OpenModelica fixes them at their own y_start, 0/0/0/int3 (F-28, confirmed in row 0 of the oracle)
    validate_against_oracle(TGTypeIII_test, oracle;
        u0 = sys -> [sys.tGTypeIII.integrator.y => 0.0, sys.tGTypeIII.integrator1.y => 0.0,
            sys.tGTypeIII.integrator2.y => 0.0, sys.tGTypeIII.integrator3.y => 2.712336])
end
