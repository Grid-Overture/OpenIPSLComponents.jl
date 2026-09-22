# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/ThreePhase/DeltaDynLoad_3Ph.mo (a Test of this port, not OpenIPSL's: PLAN-12), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function DeltaDynLoad_3Ph_Test(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        InfiniteBus = ThreePhase_InfiniteBus(; S_b, fn)
        Bus1 = Bus_3Ph(; S_b, fn)
        Line1 = Line_3Ph(; Bseraa = -3.9929, Bserab = 1.5824, Bserac = 1.0891, Bserbb = -4.1181, Bserbc = 1.3055, Bsercc = -3.8154, Gseraa = 1.8794, Gserab = -1.1096, Gserac = -0.5004, Gserbb = 2.0690, Gserbc = -0.7714, Gsercc = 1.6050, S_b, fn)
        Bus2 = Bus_3Ph(; S_b, fn)
        Trafo = Transformer_3Ph(; Connection = 0, R = 0.16666667, X = 1.0, tap = 1.0, S_b, fn)
        Bus3 = Bus_3Ph(; S_b, fn)
        Line2 = Line_3Ph(; Bseraa = -0.3687, Bserab = 0.1265, Bserac = 0.0822, Bserbb = -0.3821, Bserbc = 0.1004, Bsercc = -0.3559, Gseraa = 0.1779, Gserab = -0.0864, Gserac = -0.0312, Gserbb = 0.1989, Gserbc = -0.0529, Gsercc = 0.1598, S_b, fn)
        Bus4 = Bus_3Ph(; S_b, fn)
        Load = DeltaDynLoad_3Ph(; ModelType = 1, P_ab = 51e3, Q_ab = 31.6e3, P_bc = 72e3, Q_bc = 34.88e3, P_ca = 95e3, Q_ca = 31.24e3, A_ab = 50.0, B_ab = 30.0, C_ab = 20.0, A_bc = 20.0, B_bc = 30.0, C_bc = 50.0, A_ca = 100.0, S_b, fn)
        rampD = Ramp(; offset = 1, height = 0.5, startTime = 1, duration = 2)
    end
    eqs = Equation[
        connect(InfiniteBus.p1, Bus1.p1),
        connect(InfiniteBus.p2, Bus1.p2),
        connect(InfiniteBus.p3, Bus1.p3),
        connect(Bus1.p1, Line1.Ain),
        connect(Bus1.p2, Line1.Bin),
        connect(Bus1.p3, Line1.Cin),
        connect(Line1.Aout, Bus2.p1),
        connect(Line1.Bout, Bus2.p2),
        connect(Line1.Cout, Bus2.p3),
        connect(Bus2.p1, Trafo.Ain),
        connect(Bus2.p2, Trafo.Bin),
        connect(Bus2.p3, Trafo.Cin),
        connect(Trafo.Aout, Bus3.p1),
        connect(Trafo.Bout, Bus3.p2),
        connect(Trafo.Cout, Bus3.p3),
        connect(Bus3.p1, Line2.Ain),
        connect(Bus3.p2, Line2.Bin),
        connect(Bus3.p3, Line2.Cin),
        connect(Line2.Aout, Bus4.p1),
        connect(Line2.Bout, Bus4.p2),
        connect(Line2.Cout, Bus4.p3),
        connect(Bus4.p1, Load.A),
        connect(Bus4.p2, Load.B),
        connect(Bus4.p3, Load.C),
        rampD.y ~ Load.DynFact,   # connect(rampD.y, Load.DynFact)
    ]
    System(eqs, t, [], []; name, systems)
end
# Batch 13, PLAN-13 step 2.2. The delta sibling of the previous Test, on network R3 but with the branch powers
# at a FIFTH of R3's (51/72/95 kW, 31.6/34.88/31.24 kvar): with R3's own powers OpenModelica solves this network
# on a collapsed root and no flag of rule 5's ladder moves it, so the Test - which is this port's - carries the
# lighter load (F-95 c; the reason is in the `Documentation` of the `.mo`).
# The oracle also confirms the dead `P_ca` of the model from the outside: with `P_ca = 95` kW declared the source
# delivers 122.5 kW, which is `51*Coef_A + 72*Coef_B` plus losses and not a watt of branch CA, i.e. `Pca = 0`
# (F-97). `Pca` itself is `protected` in the `.mo` and is asserted directly in `test_ThreePhase_Loads.jl`.
@testset "PortTests.ThreePhase.DeltaDynLoad_3Ph" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "ThreePhase.DeltaDynLoad_3Ph.jl"))
    validate_against_oracle(DeltaDynLoad_3Ph_Test, oracle)
end
