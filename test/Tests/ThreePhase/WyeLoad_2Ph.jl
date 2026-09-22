# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/ThreePhase/WyeLoad_2Ph.mo (a Test of this port, not OpenIPSL's: PLAN-12), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function WyeLoad_2Ph_Test(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        InfiniteBus = ThreePhase_InfiniteBus(; S_b, fn)
        Bus1 = Bus_3Ph(; S_b, fn)
        L632_645 = Line_2Ph(; Bseraa = -0.69, Bserab = 0.1038, Bserbb = -0.6931, Gseraa = 0.7502, Gserab = -0.25, Gserbb = 0.7450, S_b, fn)
        Bus645 = Bus_2Ph(; angle_1 = -2.0943951023931953, angle_2 = 2.0943951023931953, S_b, fn)
        Load = WyeLoad_2Ph(; ModelType = 1, P_a = 170e3, Q_a = 125e3, P_b = 230e3, Q_b = 132e3, VA = 1.0, AngA = -2.0943951023931953, VB = 1.0, AngB = 2.0943951023931953, A_pa = 50.0, B_pa = 30.0, C_pa = 20.0, A_pb = 20.0, B_pb = 30.0, C_pb = 50.0, S_b, fn)
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
    ]
    System(eqs, t, [], []; name, systems)
end
# Batch 13, PLAN-13 step 2.3. Network R2 with the static two-phase wye load, the one member of the batch-9
# wye/delta family that `Tests.ThreePhase.IEEE13` does not instantiate. No input and no state, so the trajectory
# is constant over the 1 s horizon, as in the three upstream `ThreePhase` Tests (F-81). `ModelType = 1` with
# 50/30/20 % and 20/30/50 %; the `ModelType = 0` branch is a hand test in `test_ThreePhase_Loads.jl`.
@testset "PortTests.ThreePhase.WyeLoad_2Ph" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "ThreePhase.WyeLoad_2Ph.jl"))
    validate_against_oracle(WyeLoad_2Ph_Test, oracle)
end
