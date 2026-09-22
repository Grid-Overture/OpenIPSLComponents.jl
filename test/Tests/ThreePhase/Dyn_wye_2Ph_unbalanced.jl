# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/ThreePhase/Dyn_wye_2Ph_unbalanced.mo (a Test of this port, not OpenIPSL's: PLAN-12), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function Dyn_wye_2Ph_unbalanced_Test(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        InfiniteBus = ThreePhase_InfiniteBus(; S_b, fn)
        Bus1 = Bus_3Ph(; S_b, fn)
        L632_645 = Line_2Ph(; Bseraa = -0.69, Bserab = 0.1038, Bserbb = -0.6931, Gseraa = 0.7502, Gserab = -0.25, Gserbb = 0.7450, S_b, fn)
        Bus645 = Bus_2Ph(; angle_1 = -2.0943951023931953, angle_2 = 2.0943951023931953, S_b, fn)
        Load = Dyn_wye_2Ph_unbalanced(; P0_a = 170e3, Q0_a = 125e3, P0_b = 230e3, Q0_b = 132e3, S_b, fn)
        rampPa = Ramp(; offset = 0.0051, height = 0.00255, startTime = 1, duration = 2)
        constPb = Constant(; k = 0.0069)
        constQa = Constant(; k = 0.00375)
        constQb = Constant(; k = 0.00396)
    end
    eqs = Equation[
        connect(InfiniteBus.p1, Bus1.p1),
        connect(InfiniteBus.p2, Bus1.p2),
        connect(InfiniteBus.p3, Bus1.p3),
        connect(Bus1.p2, L632_645.Ain),
        connect(Bus1.p3, L632_645.Bin),
        connect(L632_645.Aout, Bus645.p1),
        connect(L632_645.Bout, Bus645.p2),
        connect(Bus645.p1, Load.A),
        connect(Bus645.p2, Load.B),
        rampPa.y ~ Load.P_in[1],   # connect(rampPa.y, Load.P_in[1])
        constPb.y ~ Load.P_in[2],   # connect(constPb.y, Load.P_in[2])
        constQa.y ~ Load.Q_in[1],   # connect(constQa.y, Load.Q_in[1])
        constQb.y ~ Load.Q_in[2],   # connect(constQb.y, Load.Q_in[2])
    ]
    System(eqs, t, [], []; name, systems)
end
# Batch 13, PLAN-13 step 2.1. Network R2, with the two phases loaded independently (170 kW/125 kvar and
# 230 kW/132 kvar) from the two input vectors: the `Ramp` drives `P_in[1]` alone and the other three elements are
# `Constant`s, so the unbalance grows during the run. The element-by-element connects are what
# the transcriber writes for a `RealInput[2]` (rule 6.5).
@testset "PortTests.ThreePhase.Dyn_wye_2Ph_unbalanced" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "ThreePhase.Dyn_wye_2Ph_unbalanced.jl"))
    validate_against_oracle(Dyn_wye_2Ph_unbalanced_Test, oracle)
end
