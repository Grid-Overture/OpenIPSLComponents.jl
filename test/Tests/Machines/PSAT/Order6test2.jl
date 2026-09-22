# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Machines/PSAT/Order6test2.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.MachineTestBase. Omitted: graphical annotations, displayPF.
# `delta(fixed = true)`, `w(fixed = true)` are already the initial_conditions of baseMachine (F-20).
@component function Order6test2(; name, S_b = 100e6, fn = 50)
    @named base = MachineTestBase(; S_b, fn)
    @unpack bus1 = base
    systems = @named begin
        order6Type2_1 = Order6(; D = 0.0, M = 10.0, P_0 = 16035269.8692006, Q_0 = 11859436.505981, Sn = 100000000.0,
            T1d0 = 8.0, T1q0 = 0.8, T2d0 = 0.04, T2q0 = 0.02, Taa = 2e-3, V_b = 400000.0, Vn = 20000.0,
            angle_0 = 0.0, ra = 0.001, v_0 = 1.0, x1d = 0.302, x1q = 0.5, x2d = 0.204, x2q = 0.3, xd = 1.9, xq = 1.7,
            S_b, fn)
    end
    eqs = Equation[
        order6Type2_1.vf ~ order6Type2_1.vf0,   # connect(order6Type2_1.vf0, order6Type2_1.vf)
        order6Type2_1.pm ~ order6Type2_1.pm0,   # connect(order6Type2_1.pm, order6Type2_1.pm0)
        connect(order6Type2_1.p, bus1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Machines.PSAT.Order6test2" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Machines.PSAT.Order6test2.jl"))
    validate_against_oracle(Order6test2, oracle)
end
