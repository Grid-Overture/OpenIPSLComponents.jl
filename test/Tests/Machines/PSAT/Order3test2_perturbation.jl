# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Machines/PSAT/Order3test2_perturbation.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.MachineTestBase. Omitted: graphical annotations, displayPF.
@component function Order3test2_perturbation(; name, S_b = 100e6, fn = 50)
    @named base = MachineTestBase(; S_b, fn)
    @unpack bus1 = base
    systems = @named begin
        order3_Inputs_Outputs1 = Order3(; angle_0 = 0.0, ra = 0.01, x1d = 0.302, M = 10.0, D = 0.0, xd = 1.9, T1d0 = 8.0, xq = 1.7, P_0 = 16035269.8692006, Q_0 = 11859436.505981, Sn = 20000000.0, v_0 = 1.0, V_b = 400000.0, Vn = 400000.0, S_b, fn)
        add31 = Add3(; )
        add1 = Add(; )
        step1 = Step(; height = 0.0005, startTime = 2)
        step2 = Step(; height = -0.0005, startTime = 2.1)
        sine1 = Sine(; amplitude = 0.001, f = 0.2)
        add2 = Add(; k2 = -1)
        sine2 = Sine(; amplitude = 0.001, f = 0.2, startTime = 5)
        sine3 = Sine(; amplitude = 0.001, f = 0.2, startTime = 10)
        add3 = Add(; k2 = -1)
        sine4 = Sine(; amplitude = 0.001, f = 0.2, startTime = 5)
        step3 = Step(; height = -0.0005, startTime = 7.1)
        step4 = Step(; height = 0.0005, startTime = 7)
        add4 = Add(; )
        add32 = Add3(; )
    end
    eqs = Equation[
        step3.y ~ add4.u2,   # connect(step3.y, add4.u2)
        step4.y ~ add4.u1,   # connect(step4.y, add4.u1)
        add1.y ~ add31.u1,   # connect(add1.y, add31.u1)
        add2.y ~ add31.u2,   # connect(add2.y, add31.u2)
        step2.y ~ add1.u2,   # connect(step2.y, add1.u2)
        step1.y ~ add1.u1,   # connect(step1.y, add1.u1)
        sine2.y ~ add2.u2,   # connect(sine2.y, add2.u2)
        sine1.y ~ add2.u1,   # connect(sine1.y, add2.u1)
        add4.y ~ add32.u2,   # connect(add4.y, add32.u2)
        sine4.y ~ add3.u1,   # connect(sine4.y, add3.u1)
        sine3.y ~ add3.u2,   # connect(sine3.y, add3.u2)
        add3.y ~ add32.u3,   # connect(add3.y, add32.u3)
        connect(order3_Inputs_Outputs1.p, bus1.p),
        add31.y ~ order3_Inputs_Outputs1.vf,   # connect(add31.y, order3_Inputs_Outputs1.vf)
        add32.y ~ order3_Inputs_Outputs1.pm,   # connect(add32.y, order3_Inputs_Outputs1.pm)
        order3_Inputs_Outputs1.vf0 ~ add31.u3,   # connect(order3_Inputs_Outputs1.vf0, add31.u3)
        order3_Inputs_Outputs1.pm0 ~ add32.u1,   # connect(order3_Inputs_Outputs1.pm0, add32.u1)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Machines.PSAT.Order3test2_perturbation" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Machines.PSAT.Order3test2_perturbation.jl"))
    # rtol 5e-3 instead of 1e-3 (F-27): with D = 0 and a constant field voltage the Order3 machine of this Test has an
    # unstable electromechanical mode; both simulators' tolerance-level errors grow exponentially and the MTK-OM
    # difference at 20 s (2.5e-3 rad in delta) is identical at abstol = reltol = 1e-8, i.e. it is the oracle's own floor
    validate_against_oracle(Order3test2_perturbation, oracle; rtol = 5e-3)
end
