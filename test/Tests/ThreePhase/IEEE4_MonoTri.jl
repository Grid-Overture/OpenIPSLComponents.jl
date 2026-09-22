# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/ThreePhase/IEEE4_MonoTri.mo, transcribed automatically (2026-09-20); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function IEEE4_MonoTri(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        infiniteBus = InfiniteBus(; S_b, fn)
        Bus1 = Bus(; S_b, fn)
        Line1 = PwLine(; B = 0.0, G = 0.0, R = 0.074563536332, X = 0.152732235479, S_b, fn)
        Bus2 = Bus(; angle_0 = 0.0, v_0 = 1.0, S_b, fn)
        Transformer = Transformer_MT(; B_0 = -1.82768503568, B_1 = -5.2872570055, B_2 = -5.2872570055, Connection = 3, G_0 = 0.729734359723, G_1 = 2.58122706441, G_2 = 2.58122706441, ModelType = 0, R = 0.166666666667, X = 1.0, tap = 1.0, S_b, fn)
        Bus3 = Bus_3Ph(; S_b, fn)
        Line2 = Line_3Ph(; Bseraa = -0.3687, Bserab = 0.1265, Bserac = 0.0822, Bserbb = -0.3821, Bserbc = 0.1004, Bsercc = -0.3559, Gseraa = 0.1779, Gserab = -0.0864, Gserac = -0.0312, Gserbb = 0.1989, Gserbc = -0.0529, Gsercc = 0.1598, S_b, fn)
        Bus4 = Bus_3Ph(; S_b, fn)
        Load = WyeLoad_3Ph(; ModelType = 0, P_a = 1275000.0, P_b = 1800000.0, P_c = 2375000.0, Q_a = 790000.0, Q_b = 872000.0, Q_c = 781000.0, S_b, fn)
    end
    eqs = Equation[
        connect(Transformer.C, Bus3.p3),
        connect(Transformer.B, Bus3.p2),
        connect(Transformer.A, Bus3.p1),
        connect(infiniteBus.p, Bus1.p),
        connect(Bus4.p3, Load.C),
        connect(Bus4.p2, Load.B),
        connect(Bus4.p1, Load.A),
        connect(Line2.Cout, Bus4.p3),
        connect(Line2.Bout, Bus4.p2),
        connect(Line2.Aout, Bus4.p1),
        connect(Bus3.p3, Line2.Cin),
        connect(Bus3.p2, Line2.Bin),
        connect(Bus3.p1, Line2.Ain),
        connect(Line1.n, Bus2.p),
        connect(Transformer.p, Bus2.p),
        connect(Line1.p, Bus1.p),
    ]
    System(eqs, t, [], []; name, systems)
end
# Batch 9, PLAN-09 step 6.4. The hybrid case: the positive-sequence side of batches 0 and 2 (the PSAT infiniteBus,
# two `Bus`, one `PwLine`) feeding `Transformer_MT(Connection = 3)` - D-Yg, the connection that has no finite
# impedance variant, so its ModelType and the six G_*/B_* are inert here - and from there the three-phase `Line2`
# and `Load` of IEEE4. Zero states, zero events (F-81).
# `skip` and `rename`: OpenModelica writes the display columns the batch-0/2 ports omit (`Bus.angleDisplay`,
# `PwLine.P12/P21/Q12/Q21`) and the Complex aliases vs, is, vr, ir of `PwLine`, which the port keeps as the pin
# variables of p and n (`transformer_aliases`, the precedent of the PSAT transformer Tests).
# Escape (F-80): the oracle is again on the low-voltage root of phases a and b (Bus4.Va = 0.169, Vb = 0.229,
# Vc = 0.975), and here OpenModelica reaches it from the DEFAULT start values - it is its Newton that selects the
# root, not the guesses. ModelingToolkit from the same guesses converges to the high-voltage root
# (Bus4.V = 0.898, 0.804, 0.774), so the Test hands OpenModelica's choice back through `u0` (F-54) with the three
# pin voltages of Bus4 from row 0 of the oracle, exactly as `IEEE4` does. The threshold is untouched.
@testset "Tests.ThreePhase.IEEE4_MonoTri" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "ThreePhase.IEEE4_MonoTri.jl"))
    aliases = transformer_aliases(oracle)
    skip = [aliases.skip; "Bus1.angleDisplay"; "Bus2.angleDisplay"]
    u0 = sys -> vcat([[getproperty(sys.Bus4, p).vr => oracle.vars["Bus4.$p.vr"][1],
                       getproperty(sys.Bus4, p).vi => oracle.vars["Bus4.$p.vi"][1]] for p in (:p1, :p2, :p3)]...)
    validate_against_oracle(IEEE4_MonoTri, oracle; skip, aliases.rename, u0)
end
