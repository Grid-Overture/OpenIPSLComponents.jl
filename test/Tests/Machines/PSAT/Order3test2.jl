# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Machines/PSAT/Order3test2.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.MachineTestBase. Omitted: graphical annotations, displayPF.
@component function Order3test2(; name, S_b = 100e6, fn = 50)
    @named base = MachineTestBase(; S_b, fn)
    @unpack bus1 = base
    systems = @named begin
        order31 = Order3(; angle_0 = 0.0, ra = 0.01, x1d = 0.302, M = 10.0, D = 0.0, xd = 1.9, T1d0 = 8.0, xq = 1.7, P_0 = 16035269.8692006, Q_0 = 11859436.505981, Sn = 20000000.0, v_0 = 1.0, V_b = 400000.0, Vn = 400000.0, S_b, fn)
    end
    eqs = Equation[
        order31.vf ~ order31.vf0,   # connect(order31.vf, order31.vf0)
        order31.pm ~ order31.pm0,   # connect(order31.pm, order31.pm0)
        connect(order31.p, bus1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Machines.PSAT.Order3test2" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Machines.PSAT.Order3test2.jl"))
    validate_against_oracle(Order3test2, oracle)
end
