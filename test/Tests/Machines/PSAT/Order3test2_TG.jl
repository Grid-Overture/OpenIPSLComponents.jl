# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Machines/PSAT/Order3test2_TG.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.MachineTestBase. Omitted: graphical annotations, displayPF.
# `TGTypeII1` keeps the .mo's instance name. Oracle generated in batch 2 with the TGTypeII1.* columns already in it.
@component function Order3test2_TG(; name, S_b = 100e6, fn = 50)
    @named base = MachineTestBase(; S_b, fn)
    @unpack bus1 = base
    systems = @named begin
        order3_Inputs_Outputs1 = Order3(; angle_0 = 0.0, ra = 0.01, x1d = 0.302, M = 10.0, D = 0.0, xd = 1.9,
            T1d0 = 8.0, xq = 1.7, P_0 = 16035269.8692006, Q_0 = 11859436.505981, Sn = 20000000.0, v_0 = 1.0,
            V_b = 400000.0, Vn = 400000.0, S_b, fn)
        TGTypeII1 = TGTypeII()
    end
    eqs = Equation[
        order3_Inputs_Outputs1.pm ~ TGTypeII1.pm,          # connect(TGTypeII1.pm, order3.pm)
        order3_Inputs_Outputs1.vf ~ order3_Inputs_Outputs1.vf0,   # connect(order3.vf0, order3.vf)
        TGTypeII1.pm0 ~ order3_Inputs_Outputs1.pm0,        # connect(order3.pm0, TGTypeII1.pm0)
        connect(order3_Inputs_Outputs1.p, bus1.p),
        TGTypeII1.w ~ order3_Inputs_Outputs1.w,            # connect(order3.w, TGTypeII1.w)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Machines.PSAT.Order3test2_TG" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Machines.PSAT.Order3test2_TG.jl"))
    # the TransferFunction of TGTypeII keeps MSL's NoInit: OpenModelica fixes its state at x[1] = 0 (F-28)
    validate_against_oracle(Order3test2_TG, oracle;
        u0 = sys -> [sys.TGTypeII1.transferFunction1.x_scaled => [0.0]])
end
