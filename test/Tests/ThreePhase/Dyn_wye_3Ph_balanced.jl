# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/ThreePhase/Dyn_wye_3Ph_balanced.mo (a Test of this port, not OpenIPSL's: PLAN-12), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function Dyn_wye_3Ph_balanced_Test(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        InfiniteBus = ThreePhase_InfiniteBus(; S_b, fn)
        Bus1 = Bus_3Ph(; S_b, fn)
        Line1 = Line_3Ph(; Bseraa = -3.9929, Bserab = 1.5824, Bserac = 1.0891, Bserbb = -4.1181, Bserbc = 1.3055, Bsercc = -3.8154, Gseraa = 1.8794, Gserab = -1.1096, Gserac = -0.5004, Gserbb = 2.0690, Gserbc = -0.7714, Gsercc = 1.6050, S_b, fn)
        Bus2 = Bus_3Ph(; S_b, fn)
        Trafo = Transformer_3Ph(; Connection = 0, R = 0.16666667, X = 1.0, tap = 1.0, S_b, fn)
        Bus3 = Bus_3Ph(; S_b, fn)
        Line2 = Line_3Ph(; Bseraa = -0.3687, Bserab = 0.1265, Bserac = 0.0822, Bserbb = -0.3821, Bserbc = 0.1004, Bsercc = -0.3559, Gseraa = 0.1779, Gserab = -0.0864, Gserac = -0.0312, Gserbb = 0.1989, Gserbc = -0.0529, Gsercc = 0.1598, S_b, fn)
        Bus4 = Bus_3Ph(; S_b, fn)
        Load = Dyn_wye_3Ph_balanced(; P0 = 1090e3, Q0 = 488.6e3, S_b, fn)
        rampP = Ramp(; offset = 0.0327, height = 0.01635, startTime = 1, duration = 2)
        constQ = Constant(; k = 0.014658)
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
        rampP.y ~ Load.P_in,   # connect(rampP.y, Load.P_in)
        constQ.y ~ Load.Q_in,   # connect(constQ.y, Load.Q_in)
    ]
    System(eqs, t, [], []; name, systems)
end
# Batch 13, PLAN-13 step 2.1. Network R3 of the plan: the network of `Tests.ThreePhase.IEEE4` without its
# "degree" start values and with the load at one fifth, which is what puts the power flow on the high-voltage
# root (`Bus4.Va = 0.9697` here against the 0.174 of `IEEE4`'s own oracle, F-80/F-95 b). The model is the
# balanced one: the ramp on `P_in` is the total 1090 kW and each phase takes a third.
@testset "PortTests.ThreePhase.Dyn_wye_3Ph_balanced" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "ThreePhase.Dyn_wye_3Ph_balanced.jl"))
    validate_against_oracle(Dyn_wye_3Ph_balanced_Test, oracle)
end
