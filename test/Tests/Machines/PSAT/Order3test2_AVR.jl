# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Machines/PSAT/Order3test2_AVR.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.MachineTestBase. Omitted: graphical annotations, displayPF.
# The `const` instance is `const_` (Julia keyword). `delta(fixed = true)`, `w(fixed = true)` are already the
# initial_conditions of baseMachine (F-20). Oracle generated in batch 2 with the AVRtypeIII1.* columns already in it.
@component function Order3test2_AVR(; name, S_b = 100e6, fn = 50)
    @named base = MachineTestBase(; S_b, fn)
    @unpack bus1 = base
    systems = @named begin
        order3_Inputs_Outputs1 = Order3(; D = 0.0, M = 10.0, P_0 = 16035269.8692006, Q_0 = 11859436.505981,
            Sn = 20000000.0, T1d0 = 8.0, V_b = 400000.0, Vn = 400000.0, angle_0 = 0.0, ra = 0.01, v_0 = 1.0,
            x1d = 0.302, xd = 1.9, xq = 1.7, S_b, fn)
        AVRtypeIII1 = AVRtypeIII()
        const_ = Constant(; k = 0.0)
    end
    eqs = Equation[
        connect(order3_Inputs_Outputs1.p, bus1.p),
        order3_Inputs_Outputs1.vf ~ AVRtypeIII1.vf,          # connect(AVRtypeIII1.vf, order3.vf)
        AVRtypeIII1.v ~ order3_Inputs_Outputs1.v,            # connect(AVRtypeIII1.v, order3.v)
        order3_Inputs_Outputs1.pm ~ order3_Inputs_Outputs1.pm0,   # connect(order3.pm0, order3.pm)
        AVRtypeIII1.vf0 ~ order3_Inputs_Outputs1.vf0,        # connect(AVRtypeIII1.vf0, order3.vf0)
        AVRtypeIII1.vs ~ const_.y,                           # connect(AVRtypeIII1.vs, const.y)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Machines.PSAT.Order3test2_AVR" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Machines.PSAT.Order3test2_AVR.jl"))
    validate_against_oracle(Order3test2_AVR, oracle)
end
