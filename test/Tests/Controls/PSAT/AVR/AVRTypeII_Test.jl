# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSAT/AVR/AVRTypeII_Test.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: none (its own four-bus network, the same topology as MachineTestBase with the buses named bus..bus3).
# Omitted: graphical annotations, displayPF.
# The machine has no delta(fixed)/w(fixed) modifier, so OpenModelica's initialization is under-determined and it fixes
# the first free start values in declaration order, delta and w (F-11, F-28); baseMachine already carries those two as
# initial_conditions, so no `u0` hook is needed. 60 s horizon: the ramp lowers aVRI.vref by 0.1 pu over 20 s from 1 s.
@component function AVRTypeII_Test(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        order6Type2_Inputs_Outputs = Order6(; angle_0 = 0.0, ra = 0.001, x1d = 0.302, M = 10.0, D = 0.0,
            P_0 = 16035269.8692006, Q_0 = 11859436.505981, Sn = 370000000.0, v_0 = 1.0, V_b = 200000.0,
            Vn = 200000.0, S_b, fn)
        pwLine1 = PwLine(; X = 0.1, R = 0.01, G = 0.0, B = 0.0005, S_b, fn)
        pwLinewithOpening1 = PwLine(; G = 0.0, R = 0.01, X = 0.1, opening = 1, B = 0.0005, t1 = 2.0, t2 = 2.15, S_b, fn)
        pwLine2 = PwLine(; G = 0.0, R = 0.01, X = 0.1, B = 0.0005, S_b, fn)
        pwLine3 = PwLine(; G = 0.0, R = 0.01, X = 0.1, B = 0.0005, S_b, fn)
        pwLine4 = PwLine(; G = 0.0, R = 0.01, X = 0.1, B = 0.0005, S_b, fn)
        pwLoadPQ1 = PQ(; angle_0 = 0.0, P_0 = 8000000.0, Q_0 = 6000000.0, v_0 = 1.0, S_b, fn)
        pwLoadPQ2 = PQ(; angle_0 = 0.0, P_0 = 8000000.0, Q_0 = 6000000.0, v_0 = 1.0, S_b, fn)
        bus = Bus(; S_b, fn)
        bus1 = Bus(; S_b, fn)
        bus2 = Bus(; S_b, fn)
        bus3 = Bus(; S_b, fn)
        aVRI = AVRTypeII()
        ramp = Ramp(; duration = 20.0, startTime = 1.0, height = -0.1)
        add = Add()
    end
    eqs = Equation[
        connect(pwLine2.p, pwLine1.p),
        connect(pwLine2.n, pwLine1.n),
        connect(pwLine4.p, pwLinewithOpening1.p),
        connect(pwLine4.n, pwLinewithOpening1.n),
        connect(bus.p, pwLine1.p),
        connect(bus1.p, pwLine1.n),
        connect(bus1.p, pwLinewithOpening1.p),
        connect(pwLine3.p, pwLinewithOpening1.p),
        connect(bus2.p, pwLoadPQ1.p),
        connect(bus2.p, pwLinewithOpening1.n),
        connect(bus3.p, pwLoadPQ2.p),
        connect(pwLine3.n, bus3.p),
        connect(bus.p, order6Type2_Inputs_Outputs.p),
        order6Type2_Inputs_Outputs.vf ~ aVRI.vf,                        # connect(aVRI.vf, order6.vf)
        aVRI.v ~ order6Type2_Inputs_Outputs.v,                          # connect(aVRI.v, order6.v)
        aVRI.vf0 ~ order6Type2_Inputs_Outputs.vf0,                      # connect(aVRI.vf0, order6.vf0)
        add.u1 ~ aVRI.vref0,                                            # connect(aVRI.vref0, add.u1)
        add.u2 ~ ramp.y,                                                # connect(ramp.y, add.u2)
        aVRI.vref ~ add.y,                                              # connect(add.y, aVRI.vref)
        order6Type2_Inputs_Outputs.pm ~ order6Type2_Inputs_Outputs.pm0,   # connect(order6.pm, order6.pm0)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.Controls.PSAT.AVR.AVRTypeII_Test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSAT.AVR.AVRTypeII_Test.jl"))
    validate_against_oracle(AVRTypeII_Test, oracle)
end
