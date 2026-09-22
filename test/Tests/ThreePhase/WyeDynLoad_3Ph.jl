# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/ThreePhase/WyeDynLoad_3Ph.mo (a Test of this port, not OpenIPSL's: PLAN-12), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function WyeDynLoad_3Ph_Test(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        InfiniteBus = ThreePhase_InfiniteBus(; S_b, fn)
        Bus1 = Bus_3Ph(; S_b, fn)
        Line1 = Line_3Ph(; Bseraa = -3.9929, Bserab = 1.5824, Bserac = 1.0891, Bserbb = -4.1181, Bserbc = 1.3055, Bsercc = -3.8154, Gseraa = 1.8794, Gserab = -1.1096, Gserac = -0.5004, Gserbb = 2.0690, Gserbc = -0.7714, Gsercc = 1.6050, S_b, fn)
        Bus2 = Bus_3Ph(; S_b, fn)
        Trafo = Transformer_3Ph(; Connection = 0, R = 0.16666667, X = 1.0, tap = 1.0, S_b, fn)
        Bus3 = Bus_3Ph(; S_b, fn)
        Line2 = Line_3Ph(; Bseraa = -0.3687, Bserab = 0.1265, Bserac = 0.0822, Bserbb = -0.3821, Bserbc = 0.1004, Bsercc = -0.3559, Gseraa = 0.1779, Gserab = -0.0864, Gserac = -0.0312, Gserbb = 0.1989, Gserbc = -0.0529, Gsercc = 0.1598, S_b, fn)
        Bus4 = Bus_3Ph(; S_b, fn)
        Load = WyeDynLoad_3Ph(; ModelType = 1, P_a = 255e3, Q_a = 158e3, P_b = 360e3, Q_b = 174.4e3, P_c = 475e3, Q_c = 156.2e3, A_pa = 50.0, B_pa = 30.0, C_pa = 20.0, A_pb = 20.0, B_pb = 30.0, C_pb = 50.0, A_pc = 100.0, S_b, fn)
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
# Batch 13, PLAN-13 step 2.2. Network R3 with the ZIP branch of `WyeDynLoad_3Ph` (`ModelType = 1`, 50/30/20 %
# on phase a, 20/30/50 % on phase b, 100 % constant power on phase c) under a `Ramp` on `DynFact` from 1 to 1.5:
# the three coefficients differ from each other and from 1 and follow the voltage as the curve loads the feeder.
# `ModelType = 0` is covered by the Test of `MeasurementBus`.
@testset "PortTests.ThreePhase.WyeDynLoad_3Ph" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "ThreePhase.WyeDynLoad_3Ph.jl"))
    validate_against_oracle(WyeDynLoad_3Ph_Test, oracle)
end
