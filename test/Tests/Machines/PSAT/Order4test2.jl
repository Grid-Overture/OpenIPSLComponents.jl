# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Machines/PSAT/Order4test2.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.MachineTestBase. Omitted: graphical annotations, displayPF.
@component function Order4test2(; name, S_b = 100e6, fn = 50)
    @named base = MachineTestBase(; S_b, fn)
    @unpack bus1 = base
    systems = @named begin
        Generator = Order4(; D = 0.0, M = 10.0, P_0 = 16035269.8692006, Q_0 = 11859436.505981, Sn = 100000000.0, V_b = 400000.0, Vn = 20000.0, angle_0 = 0.0, ra = 0.001, v_0 = 1.0, x1d = 0.302, S_b, fn)
    end
    eqs = Equation[
        Generator.vf0 ~ Generator.vf,   # connect(Generator.vf0, Generator.vf)
        Generator.pm ~ Generator.pm0,   # connect(Generator.pm, Generator.pm0)
        connect(Generator.p, bus1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Machines.PSAT.Order4test2" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Machines.PSAT.Order4test2.jl"))
    validate_against_oracle(Order4test2, oracle)
end
