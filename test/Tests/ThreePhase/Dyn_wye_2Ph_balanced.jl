# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/ThreePhase/Dyn_wye_2Ph_balanced.mo (a Test of this port, not OpenIPSL's: PLAN-12), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function Dyn_wye_2Ph_balanced_Test(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        InfiniteBus = ThreePhase_InfiniteBus(; S_b, fn)
        Bus1 = Bus_3Ph(; S_b, fn)
        L632_645 = Line_2Ph(; Bseraa = -0.69, Bserab = 0.1038, Bserbb = -0.6931, Gseraa = 0.7502, Gserab = -0.25, Gserbb = 0.7450, S_b, fn)
        Bus645 = Bus_2Ph(; angle_1 = -2.0943951023931953, angle_2 = 2.0943951023931953, S_b, fn)
        Load = Dyn_wye_2Ph_balanced(; P0 = 400e3, Q0 = 257e3, S_b, fn)
        rampP = Ramp(; offset = 0.012, height = 0.006, startTime = 1, duration = 2)
        constQ = Constant(; k = 0.00771)
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
        rampP.y ~ Load.P_in,   # connect(rampP.y, Load.P_in)
        constQ.y ~ Load.Q_in,   # connect(constQ.y, Load.Q_in)
    ]
    System(eqs, t, [], []; name, systems)
end
# Batch 13, PLAN-13 step 2.1. Network R2 of the plan: the two-phase lateral of `IEEE13`'s `L632_645` on phases
# b and c, with the total of `SpotLoad645` and `SpotLoad646` read in kW (400 kW/257 kvar). The model is the
# balanced one, so the ramp on `P_in` is the TOTAL and each phase takes half of it.
@testset "PortTests.ThreePhase.Dyn_wye_2Ph_balanced" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "ThreePhase.Dyn_wye_2Ph_balanced.jl"))
    validate_against_oracle(Dyn_wye_2Ph_balanced_Test, oracle)
end
