# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Machines/PSAT/Order4test2_AVR.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.MachineTestBase. Omitted: graphical annotations, displayPF.
# The .mo writes `AVRtypeIII1(v(fixed = true))`: `v` is an *input* connected to the machine's terminal voltage, whose
# `start = 1` is also its value at t = 0 (v_0 = 1), so the modifier has no effect and is not transcribed; the t = 0
# row of the oracle confirms it. The `const` instance is `const_` (Julia keyword).
@component function Order4test2_AVR(; name, S_b = 100e6, fn = 50)
    @named base = MachineTestBase(; S_b, fn)
    @unpack bus1 = base
    systems = @named begin
        AVRtypeIII1 = AVRtypeIII()
        order4_Inputs_Outputs = Order4(; D = 0.0, M = 10.0, P_0 = 16035269.8692006, Q_0 = 11859436.505981,
            Sn = 370000000.0, V_b = 200000.0, Vn = 200000.0, angle_0 = 0.0, ra = 0.001, v_0 = 1.0, x1d = 0.302,
            S_b, fn)
        const_ = Constant(; k = 0.0)
    end
    eqs = Equation[
        order4_Inputs_Outputs.vf ~ AVRtypeIII1.vf,           # connect(AVRtypeIII1.vf, order4.vf)
        AVRtypeIII1.vs ~ const_.y,                           # connect(const.y, AVRtypeIII1.vs)
        AVRtypeIII1.v ~ order4_Inputs_Outputs.v,             # connect(AVRtypeIII1.v, order4.v)
        order4_Inputs_Outputs.pm ~ order4_Inputs_Outputs.pm0,   # connect(order4.pm0, order4.pm)
        connect(order4_Inputs_Outputs.p, bus1.p),
        AVRtypeIII1.vf0 ~ order4_Inputs_Outputs.vf0,         # connect(AVRtypeIII1.vf0, order4.vf0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Machines.PSAT.Order4test2_AVR" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Machines.PSAT.Order4test2_AVR.jl"))
    validate_against_oracle(Order4test2_AVR, oracle)
end
