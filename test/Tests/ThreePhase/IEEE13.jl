# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/ThreePhase/IEEE13.mo, transcribed automatically (2026-09-20); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function IEEE13(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        InfBus = ThreePhase_InfiniteBus(; P_A = 1.0, P_B = 1.0, P_C = 1.0, Q_A = 0.0, Q_B = 0.0, Q_C = 0.0, V_A = 1.0625, V_B = 1.05, V_C = 1.0687, angle_A = 0.0, angle_B = -120.0, angle_C = 120.0, S_b, fn)
        Bus632 = Bus_3Ph(; S_b, fn)
        Bus671 = Bus_3Ph(; S_b, fn)
        L632_671 = Line_3Ph(; Bseraa = -0.5712, Bserab = 0.2112, Bserac = 0.1579, Bserbb = -0.5413, Bserbc = 0.1206, Bsercc = -0.5106, Gseraa = 0.1982, Gserab = -0.0841, Gserac = -0.0460, Gserbb = 0.1735, Gserbc = -0.0219, Gsercc = 0.1535, S_b, fn)
        Bus633 = Bus_3Ph(; S_b, fn)
        L632_633 = Line_3Ph(; Bseraa = -1.2346, Bserab = 0.2606, Bserac = 0.2925, Bserbb = -1.2224, Bserbc = 0.2392, Bsercc = -1.2262, Gseraa = 0.9630, Gserab = -0.2587, Gserac = -0.3702, Gserbb = 0.8495, Gserbc = -0.1883, Gsercc = 0.8980, S_b, fn)
        SpotLoad634 = WyeLoad_3Ph(; ModelType = 0, P_a = 0.160, P_b = 0.120, P_c = 0.12, Q_a = 0.110, Q_b = 0.09, Q_c = 0.09, S_b, fn)
        Bus675 = Bus_3Ph(; S_b, fn)
        L692_675 = Line_3Ph(; Bseraa = -1.3443, Bserab = 0.5197, Bserac = 0.4255, Bserbb = -1.4001, Bserbc = 0.5197, Bsercc = -1.3443, Gseraa = 1.7857, Gserab = -0.4189, Gserac = -0.1865, Gserbb = 1.9810, Gserbc = -0.4189, Gsercc = 1.7857, S_b, fn)
        SpotLoad675 = WyeLoad_3Ph(; ModelType = 0, P_a = 0.485, P_b = 0.068, P_c = 0.290, Q_a = 0.19, Q_b = 0.06, Q_c = 0.212, S_b, fn)
        DistLoad671 = WyeLoad_3Ph(; ModelType = 0, P_a = 0.0085, P_b = 0.033, P_c = 0.0585, Q_a = 0.005, Q_b = 0.019, Q_c = 0.034, S_b, fn)
        DisLoad632 = WyeLoad_3Ph(; ModelType = 0, P_a = 0.0085, P_b = 0.033, P_c = 0.0585, Q_a = 0.005, Q_b = 0.019, Q_c = 0.034, S_b, fn)
        CapBank675 = CapacitorBank_3Ph(; Q_a = 0.2, Q_b = 0.2, Q_c = 0.2, S_b, fn)
        Bus634 = Bus_3Ph(; S_b, fn)
        XFM1 = Transformer_3Ph(; Connection = 0, R = 2.2, X = 4.0, tap = 1.0, S_b, fn)
        breaker = Breaker(; )
        breaker2 = Breaker(; )
        breaker3 = Breaker(; )
        Bus692 = Bus_3Ph(; S_b, fn)
        L632_645 = Line_2Ph(; Bseraa = -0.69, Bserab = 0.1038, Bserbb = -0.6931, Gseraa = 0.7502, Gserab = -0.25, Gserbb = 0.7450, S_b, fn)
        Bus645 = Bus_2Ph(; V_1 = 1.0, V_2 = 1.0, angle_1 = -120.0, angle_2 = 120.0, S_b, fn)
        L645_646 = Line_2Ph(; Bseraa = -1.1499, Bserab = 0.1729, Bserbb = -1.1552, Gseraa = 1.2503, Gserab = -0.4167, Gserbb = 1.2417, S_b, fn)
        Bus646 = Bus_2Ph(; V_1 = 1.0, V_2 = 1.0, angle_1 = -120.0, angle_2 = 120.0, S_b, fn)
        SpotLoad645 = WyeLoad_1Ph(; AngA = -120.0, P_a = 0.17, Q_a = 0.125, VA = 1.0, S_b, fn)
        Bus680 = Bus_3Ph(; S_b, fn)
        L671_680 = Line_3Ph(; Bseraa = -1.1424, Bserab = 0.4224, Bserac = 0.3157, Bserbb = -1.0825, Bserbc = 0.2411, Bsercc = -1.0212, Gseraa = 0.3963, Gserab = -0.1682, Gserac = -0.0921, Gserbb = 0.3471, Gserbc = -0.0437, Gsercc = 0.3069, S_b, fn)
        Bus684 = Bus_2Ph(; angle_2 = 120.0, S_b, fn)
        L671_684 = Line_2Ph(; Bseraa = -1.1552, Bserab = 0.1729, Bserbb = -1.1499, Gseraa = 1.2417, Gserab = -0.4167, Gserbb = 1.2503, S_b, fn)
        L684_652 = Line_1Ph(; Bser = -0.2834, Gser = 0.7426, S_b, fn)
        Bus652 = Bus_1Ph(; S_b, fn)
        SpotLoad652 = WyeLoad_1Ph(; C_pa = 100.0, ModelType = 1, P_a = 0.128, Q_a = 0.086, S_b, fn)
        Bus611 = Bus_1Ph(; angle_1 = 120.0, S_b, fn)
        L684_611 = Line_1Ph(; Bser = -1.1456, Gser = 1.1301, S_b, fn)
        SpotLoad611 = WyeLoad_1Ph(; AngA = 120.0, B_pa = 100.0, ModelType = 1, P_a = 0.17, Q_a = 0.08, S_b, fn)
        CapacitorBank611 = CapacitorBank_1Ph(; AngA = 120.0, Q_a = 0.1, S_b, fn)
        LRG60_632 = Line_3Ph(; Bseraa = -0.5712, Bserab = 0.2112, Bserac = 0.1579, Bserbb = -0.5413, Bserbc = 0.1206, Bsercc = -0.5106, Gseraa = 0.1982, Gserab = -0.0841, Gserac = -0.046, Gserbb = 0.1735, Gserbc = -0.0219, Gsercc = 0.1535, S_b, fn)
        BusRG60 = Bus_3Ph(; V_A = 1.0625, V_B = 1.05, V_C = 1.0687, S_b, fn)
        SpotLoad671 = DeltaLoad_3Ph(; P_ab = 0.385, P_bc = 0.385, P_ca = 0.385, Q_ab = 0.22, Q_bc = 0.22, Q_ca = 0.22, S_b, fn)
        SpotLoad692 = DeltaLoad_2Ph(; AngA = 120.0, AngB = 0.0, B_ab = 100.0, ModelType = 1, P_ab = 0.17, Q_ab = 0.151, VA = 1.0, VB = 1.0, S_b, fn)
        SpotLoad646 = DeltaLoad_2Ph(; AngA = -120.0, AngB = 120.0, C_ab = 100.0, ModelType = 1, P_ab = 0.23, Q_ab = 0.132, S_b, fn)
    end
    eqs = Equation[
        connect(Bus646.p2, SpotLoad646.B),
        connect(Bus646.p1, SpotLoad646.A),
        connect(SpotLoad692.B, Bus692.p1),
        connect(SpotLoad692.A, Bus692.p3),
        connect(Bus671.p3, SpotLoad671.C),
        connect(Bus671.p2, SpotLoad671.B),
        connect(Bus671.p1, SpotLoad671.A),
        connect(InfBus.p3, BusRG60.p3),
        connect(InfBus.p2, BusRG60.p2),
        connect(InfBus.p1, BusRG60.p1),
        connect(BusRG60.p3, LRG60_632.Cin),
        connect(BusRG60.p2, LRG60_632.Bin),
        connect(BusRG60.p1, LRG60_632.Ain),
        connect(LRG60_632.Cout, Bus632.p3),
        connect(LRG60_632.Bout, Bus632.p2),
        connect(LRG60_632.Aout, Bus632.p1),
        connect(Bus632.p2, L632_633.Bin),
        connect(Bus632.p3, L632_633.Cin),
        connect(Bus632.p1, L632_633.Ain),
        connect(Bus632.p1, L632_671.Ain),
        connect(Bus632.p3, L632_671.Cin),
        connect(Bus632.p2, L632_671.Bin),
        connect(Bus632.p3, DisLoad632.C),
        connect(Bus632.p2, DisLoad632.B),
        connect(Bus632.p1, DisLoad632.A),
        connect(Bus632.p2, L632_645.Ain),
        connect(Bus632.p3, L632_645.Bin),
        connect(Bus611.p1, CapacitorBank611.A),
        connect(SpotLoad611.A, Bus611.p1),
        connect(Bus684.p2, L684_611.Ain),
        connect(Bus611.p1, L684_611.Aout),
        connect(Bus652.p1, SpotLoad652.A),
        connect(L684_652.Aout, Bus652.p1),
        connect(L684_652.Ain, Bus684.p1),
        connect(L671_684.Bout, Bus684.p2),
        connect(L671_684.Aout, Bus684.p1),
        connect(Bus671.p3, L671_684.Bin),
        connect(Bus671.p1, L671_684.Ain),
        connect(L671_680.Cout, Bus680.p3),
        connect(L671_680.Bout, Bus680.p2),
        connect(L671_680.Aout, Bus680.p1),
        connect(Bus671.p3, L671_680.Cin),
        connect(Bus671.p2, L671_680.Bin),
        connect(Bus671.p1, L671_680.Ain),
        connect(Bus645.p1, SpotLoad645.A),
        connect(L645_646.Bout, Bus646.p2),
        connect(L645_646.Aout, Bus646.p1),
        connect(Bus645.p2, L645_646.Bin),
        connect(Bus645.p1, L645_646.Ain),
        connect(L632_645.Bout, Bus645.p2),
        connect(L632_645.Aout, Bus645.p1),
        connect(Bus692.p3, L692_675.Cin),
        connect(Bus692.p2, L692_675.Bin),
        connect(L692_675.Ain, Bus692.p1),
        connect(L692_675.Bout, Bus675.p2),
        connect(Bus675.p1, L692_675.Aout),
        connect(Bus675.p3, L692_675.Cout),
        connect(Bus671.p3, breaker3.s),
        connect(Bus671.p2, breaker2.s),
        connect(Bus671.p1, breaker.s),
        connect(breaker3.r, Bus692.p3),
        connect(breaker2.r, Bus692.p2),
        connect(breaker.r, Bus692.p1),
        connect(Bus671.p3, DistLoad671.C),
        connect(Bus671.p2, DistLoad671.B),
        connect(Bus671.p1, DistLoad671.A),
        connect(CapBank675.A, Bus675.p1),
        connect(Bus675.p2, CapBank675.B),
        connect(Bus675.p3, CapBank675.C),
        connect(SpotLoad675.C, Bus675.p3),
        connect(SpotLoad675.B, Bus675.p2),
        connect(SpotLoad675.A, Bus675.p1),
        connect(L632_671.Aout, Bus671.p1),
        connect(L632_671.Bout, Bus671.p2),
        connect(L632_671.Cout, Bus671.p3),
        connect(SpotLoad634.C, Bus634.p3),
        connect(SpotLoad634.B, Bus634.p2),
        connect(Bus634.p1, SpotLoad634.A),
        connect(XFM1.Cout, Bus634.p3),
        connect(XFM1.Bout, Bus634.p2),
        connect(XFM1.Aout, Bus634.p1),
        connect(XFM1.Cin, Bus633.p3),
        connect(XFM1.Bin, Bus633.p2),
        connect(XFM1.Ain, Bus633.p1),
        connect(L632_633.Cout, Bus633.p3),
        connect(L632_633.Aout, Bus633.p1),
        connect(L632_633.Bout, Bus633.p2),
    ]
    System(eqs, t, [], []; name, systems)
end

# Batch 9, PLAN-09 step 5.1. The IEEE 13-node feeder: 13 buses (8 three-phase, 3 two-phase, 2 single-phase),
# 10 lines, 10 loads, 2 capacitor banks, one Transformer_3Ph and three closed `Breaker`s, and the largest oracle of
# the port (572 variables). A pure power-flow network, zero states and zero events (F-81).
# What it validates is the topology, the pin aliasing and the source: F-79 - the Test writes its source angles in
# radians (-120 and +120, not degrees) and its loads in watts over a 33.3 MVA base, so the feeder is unbalanced and
# carries 298 W in total. Every bus voltage equals the source to 1e-5 and the largest pin currents of the network
# are the 1e-6 fillers of TransfConnection.Yg_Yg, not the loads. The arithmetic of the loads and banks lies under
# the 1e-4 absolute floor of the threshold and is validated by test_ThreePhase_Loads.jl and test_ThreePhase_Banks.jl.
# Batch 9, PLAN-09 step 5.1. The IEEE 13-node feeder: 13 buses (8 three-phase, 3 two-phase, 2 single-phase),
# 10 lines, 10 loads, 2 capacitor banks, one Transformer_3Ph and three closed `Breaker`s - the largest oracle of
# the port, 572 variables. A pure power-flow network, zero states and zero events (F-81).
# What it validates is the topology, the pin aliasing and the source: F-79 - the Test writes its source angles in
# radians (-120 and +120, not degrees) and its loads in watts over a 33.3 MVA base, so the feeder is unbalanced and
# carries 298 W in total. Every bus voltage equals the source to 1e-5 and the largest pin currents of the network
# are the 1e-6 fillers of TransfConnection.Yg_Yg, not the loads. The arithmetic of the loads and banks lies under
# the 1e-4 absolute floor of the threshold and is validated by test_ThreePhase_Loads.jl and test_ThreePhase_Banks.jl.
# Two escapes, neither of them a threshold:
#   `rename`: OpenModelica writes the Complex aliases vs, is, vr, ir of `Breaker.mo`, which the port keeps as the
#             pin variables of its pins s and r (`transformer_aliases` with those pin names).
#   `tol`:    with the experiment tolerance (1e-6) the algebraic system is re-solved to 1e-6 at every step, and the
#             source powers - pin currents of 1e-6 pu times a 33.3 MVA base - come out 0.3 W off 124 W. At 1e-8 the
#             whole run matches the oracle to 1e-7 W and stops moving (F-82): it is ModelingToolkit that had not
#             converged, not the reference.
@testset "Tests.ThreePhase.IEEE13" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "ThreePhase.IEEE13.jl"))
    validate_against_oracle(IEEE13, oracle; rename = transformer_aliases(oracle; pins = ("s", "r")).rename,
        tol = 1e-8)
end
