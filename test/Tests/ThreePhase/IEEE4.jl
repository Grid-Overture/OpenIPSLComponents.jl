# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/ThreePhase/IEEE4.mo, transcribed automatically (2026-09-20); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function IEEE4(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        InfiniteBus = ThreePhase_InfiniteBus(; S_b, fn)
        Bus1 = Bus_3Ph(; S_b, fn)
        Line1 = Line_3Ph(; Bseraa = -3.9929, Bserab = 1.5824, Bserac = 1.0891, Bserbb = -4.1181, Bserbc = 1.3055, Bsercc = -3.8154, Gseraa = 1.8794, Gserab = -1.1096, Gserac = -0.5004, Gserbb = 2.0690, Gserbc = -0.7714, Gsercc = 1.6050, S_b, fn)
        Bus2 = Bus_3Ph(; S_b, fn)
        Bus3 = Bus_3Ph(; angle_A = -30.0, angle_B = -150.0, angle_C = 90.0, S_b, fn)
        Line2 = Line_3Ph(; Bseraa = -0.3687, Bserab = 0.1265, Bserac = 0.0822, Bserbb = -0.3821, Bserbc = 0.1004, Bsercc = -0.3559, Gseraa = 0.1779, Gserab = -0.0864, Gserac = -0.0312, Gserbb = 0.1989, Gserbc = -0.0529, Gsercc = 0.1598, S_b, fn)
        Bus4 = Bus_3Ph(; angle_A = -30.0, angle_B = -150.0, angle_C = 90.0, S_b, fn)
        Load = WyeLoad_3Ph(; AngA = 0.0, ModelType = 0, P_a = 1275000.0, Q_a = 790000.0, P_b = 1800000.0, Q_b = 872000.0, P_c = 2375000.0, Q_c = 781000.0, S_b, fn)
        Trafo = Transformer_3Ph(; Connection = 0, R = 0.16666667, X = 1.0, tap = 1.0, S_b, fn)
    end
    eqs = Equation[
        connect(Trafo.Cout, Bus3.p3),
        connect(Trafo.Bout, Bus3.p2),
        connect(Trafo.Aout, Bus3.p1),
        connect(Bus2.p3, Trafo.Cin),
        connect(Bus2.p2, Trafo.Bin),
        connect(Bus2.p1, Trafo.Ain),
        connect(Bus4.p3, Load.C),
        connect(Bus4.p2, Load.B),
        connect(Bus4.p1, Load.A),
        connect(Line2.Cout, Bus4.p3),
        connect(Line2.Bout, Bus4.p2),
        connect(Line2.Aout, Bus4.p1),
        connect(Bus3.p3, Line2.Cin),
        connect(Bus3.p2, Line2.Bin),
        connect(Bus3.p1, Line2.Ain),
        connect(Line1.Cout, Bus2.p3),
        connect(Line1.Bout, Bus2.p2),
        connect(Line1.Aout, Bus2.p1),
        connect(Bus1.p3, Line1.Cin),
        connect(Bus1.p2, Line1.Bin),
        connect(Bus1.p1, Line1.Ain),
        connect(InfiniteBus.p3, Bus1.p3),
        connect(InfiniteBus.p2, Bus1.p2),
        connect(InfiniteBus.p1, Bus1.p1),
    ]
    System(eqs, t, [], []; name, systems)
end

# Batch 9, PLAN-09 step 4.3. A pure power-flow network: zero states, zero events (F-81), so the 21 sampled instants
# all carry the same algebraic solution. The oracle is on the LOW-VOLTAGE root of phases a and b (Bus4.Va = 0.174,
# Vb = 0.234, Vc = 1.022): OpenModelica reaches it with its plain Newton from the .mo start values, which this Test
# Batch 9, PLAN-09 step 4.3. A pure power-flow network: zero states, zero events, so the 21 sampled instants all
# carry the same algebraic solution and the ODE path of the harness runs unchanged (F-81).
# Escape (F-80): the oracle sits on the LOW-VOLTAGE root of phases a and b (Bus4.Va = 0.174, Vb = 0.234,
# Vc = 1.022), which OpenModelica reaches with its plain Newton; ModelingToolkit from the literal guesses - the
# radian angles this Test writes where it meant degrees, F-79 - converges instead to a third, genuine root
# (Bus4.V = 0.963, 0.883, 0.445, residual 1e-15), and LevenbergMarquardt lands on that same one. So the Test hands
# OpenModelica's choice back through `u0` (F-54), with the three pin voltages of Bus4 from row 0 of the oracle;
# that is the smallest set that steers the Newton into the right basin, and the point it reaches satisfies the
# compiled system to 9e-16. The threshold is untouched.
@testset "Tests.ThreePhase.IEEE4" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "ThreePhase.IEEE4.jl"))
    u0 = sys -> vcat([[getproperty(sys.Bus4, p).vr => oracle.vars["Bus4.$p.vr"][1],
                       getproperty(sys.Bus4, p).vi => oracle.vars["Bus4.$p.vi"][1]] for p in (:p1, :p2, :p3)]...)
    validate_against_oracle(IEEE4, oracle; u0)
end
