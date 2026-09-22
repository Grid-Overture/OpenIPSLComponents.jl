# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Machines/PSAT/Order4test2_TG.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.MachineTestBase. Omitted: graphical annotations, displayPF.
# `TGTypeII1` and `Generator` keep the .mo's instance names. The governor stays at its default `Sn = 20e6` in front of
# a 370 MVA machine (sic), so Ro = 1 and pmax = 0.2. `delta(fixed = true)`, `w(fixed = true)` are already the
# initial_conditions of Order4.jl (F-20, F-54).
@component function Order4test2_TG(; name, S_b = 100e6, fn = 50)
    @named base = MachineTestBase(; S_b, fn)
    @unpack bus1 = base
    systems = @named begin
        TGTypeII1 = TGTypeII()
        Generator = Order4(; D = 0.0, M = 10.0, P_0 = 16035269.8692006, Q_0 = 11859436.505981, Sn = 370000000.0,
            V_b = 200000.0, Vn = 200000.0, angle_0 = 0.0, ra = 0.001, v_0 = 1.0, x1d = 0.302, S_b, fn)
    end
    eqs = Equation[
        connect(Generator.p, bus1.p),
        Generator.pm ~ TGTypeII1.pm,        # connect(TGTypeII1.pm, Generator.pm)
        TGTypeII1.pm0 ~ Generator.pm0,      # connect(Generator.pm0, TGTypeII1.pm0)
        Generator.vf ~ Generator.vf0,       # connect(Generator.vf0, Generator.vf)
        TGTypeII1.w ~ Generator.w,          # connect(Generator.w, TGTypeII1.w)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Machines.PSAT.Order4test2_TG" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Machines.PSAT.Order4test2_TG.jl"))
    # the TransferFunction of TGTypeII keeps MSL's NoInit: OpenModelica fixes its state at x[1] = 0 (F-28)
    validate_against_oracle(Order4test2_TG, oracle;
        u0 = sys -> [sys.TGTypeII1.transferFunction1.x_scaled => [0.0]])
end
