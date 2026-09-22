# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Branches/PSAT/ULTC_Test.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function ULTC_Test(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        pwLine3 = PwLine(; B = 0.001/2, G = 0.0, R = 0.01, X = 0.1, S_b, fn)
        pwLine4 = PwLine(; B = 0.001/2, G = 0.0, R = 0.01, X = 0.1, S_b, fn)
        order2_Inputs_Outputs = Order2(; D = 5.0, angle_0 = 0.0, ra = 0.001, x1d = 0.302, M = 10.0, P_0 = 8103287.7181982, Q_0 = 5852304.4412627, Sn = 370000000.0, v_0 = 1.0, V_b = 400000.0, Vn = 400000.0, S_b, fn)
        lOADPQ_B3 = PQvar(; t_start_1 = 5.0, t_end_1 = 8.0, t_start_2 = 8.0, t_end_2 = 12.0, dP1 = 0.0, dP2 = 0.0, dQ1 = -5000000.0, dQ2 = 5000000.0, P_0 = 8000000.0, Q_0 = 6000000.0, S_b, fn)
        uLTC_VoltageControl = ULTC_VoltageControl(; m0 = 0.9785)
        B1 = Bus(; S_b, fn)
        B2 = Bus(; S_b, fn)
        B3 = Bus(; S_b, fn)
    end
    eqs = Equation[
        order2_Inputs_Outputs.pm0 ~ order2_Inputs_Outputs.pm,   # connect(order2_Inputs_Outputs.pm0, order2_Inputs_Outputs.pm)
        connect(pwLine4.p, pwLine3.p),
        connect(order2_Inputs_Outputs.p, B1.p),
        connect(B1.p, pwLine3.p),
        connect(B2.p, pwLine3.n),
        connect(uLTC_VoltageControl.n, B3.p),
        connect(lOADPQ_B3.p, B3.p),
        connect(B2.p, uLTC_VoltageControl.p),
        connect(B2.p, pwLine4.n),
        order2_Inputs_Outputs.vf0 ~ order2_Inputs_Outputs.vf,   # connect(order2_Inputs_Outputs.vf0, order2_Inputs_Outputs.vf)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.Branches.PSAT.ULTC_Test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Branches.PSAT.ULTC_Test.jl"))
    validate_against_oracle(ULTC_Test, oracle)
end
