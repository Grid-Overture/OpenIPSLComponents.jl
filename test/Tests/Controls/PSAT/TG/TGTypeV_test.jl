# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSAT/TG/TGTypeV_test.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.TGTestBase. Omitted: graphical annotations, displayPF.
# The .mo carries no `experiment` annotation, so the oracle is omc's default run: 1 s, tol 1e-6, 500 intervals
# (precedent ULTC_Test, batch 2). The two sine perturbations on wref start at 5 and 10 s and the fault of the base at
# 3 s, all beyond that horizon: the Test checks the equilibrium.
@component function TGTypeV_test(; name, S_b = 100e6, fn = 50)
    @named base = TGTestBase(; S_b, fn)
    @unpack gen = base
    systems = @named begin
        tGTypeV = TGTypeV(; Ki = 0.5, Kp = 3.0, Tg = 0.2, Tp = 0.05, sigma = 0.04, vmin = -0.1, vmax = 0.1,
            gmax = 1.0, gmin = 0.0, Tw = 1.0, Pref = 0.160552)
        sine2 = Sine(; amplitude = 0.001, f = 0.2, offset = 1, startTime = 5)
        sine1 = Sine(; amplitude = -0.001, f = 0.2, startTime = 10, offset = 0)
        perturbation = Add()
    end
    eqs = Equation[
        perturbation.u1 ~ sine2.y,    # connect(sine2.y, perturbation.u1)
        perturbation.u2 ~ sine1.y,    # connect(sine1.y, perturbation.u2)
        tGTypeV.wref ~ perturbation.y,   # connect(perturbation.y, tGTypeV.wref)
        gen.pm ~ tGTypeV.Pm,          # connect(tGTypeV.Pm, gen.pm)
        tGTypeV.pref ~ gen.pm0,       # connect(tGTypeV.pref, gen.pm0)
        tGTypeV.w ~ gen.w,            # connect(tGTypeV.w, gen.w)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSAT.TG.TGTypeV_test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSAT.TG.TGTypeV_test.jl"))
    # the two Integrator(NoInit) carry no initialization equation; OpenModelica fixes them at their own y_start,
    # Pref and 0 (F-28, confirmed in row 0 of the oracle)
    validate_against_oracle(TGTypeV_test, oracle;
        u0 = sys -> [sys.tGTypeV.integrator.y => 0.160552, sys.tGTypeV.integrator5.y => 0.0])
end
