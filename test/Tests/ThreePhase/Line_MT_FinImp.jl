# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/ThreePhase/Line_MT_FinImp.mo (a Test of this port, not OpenIPSL's: PLAN-12), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function Line_MT_FinImp(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        infiniteBus = InfiniteBus(; S_b, fn)
        Bus1 = Bus(; S_b, fn)
        Line1 = PwLine(; B = 0.0, G = 0.0, R = 0.074563536332, X = 0.152732235479, S_b, fn)
        Bus2 = Bus(; angle_0 = 0.0, v_0 = 1.0, S_b, fn)
        HybridLine = Line_MT(; ModelType = 1, G_0 = 0.729734359723, B_0 = -1.82768503568, G_1 = 2.58122706441, B_1 = -5.2872570055, G_2 = 2.58122706441, B_2 = -5.2872570055, Gseraa = 0.162162, Bseraa = -0.972973, Gserab = 0.0, Bserab = 0.0, Gserac = 0.0, Bserac = 0.0, Gserbb = 0.162162, Bserbb = -0.972973, Gserbc = 0.0, Bserbc = 0.0, Gsercc = 0.162162, Bsercc = -0.972973, Bshtaa = 0.0, Bshtab = 0.0, Bshtac = 0.0, Bshtbb = 0.0, Bshtbc = 0.0, Bshtcc = 0.0, S_b, fn)
        Bus3 = Bus_3Ph(; S_b, fn)
        Line2 = Line_3Ph(; Bseraa = -0.3687, Bserab = 0.1265, Bserac = 0.0822, Bserbb = -0.3821, Bserbc = 0.1004, Bsercc = -0.3559, Gseraa = 0.1779, Gserab = -0.0864, Gserac = -0.0312, Gserbb = 0.1989, Gserbc = -0.0529, Gsercc = 0.1598, S_b, fn)
        Bus4 = Bus_3Ph(; S_b, fn)
        Load = WyeLoad_3Ph(; ModelType = 0, P_a = 255e3, Q_a = 158e3, P_b = 360e3, Q_b = 174.4e3, P_c = 475e3, Q_c = 156.2e3, S_b, fn)
    end
    eqs = Equation[
        connect(infiniteBus.p, Bus1.p),
        connect(Line1.p, Bus1.p),
        connect(Line1.n, Bus2.p),
        connect(HybridLine.p, Bus2.p),
        connect(HybridLine.A, Bus3.p1),
        connect(HybridLine.B, Bus3.p2),
        connect(HybridLine.C, Bus3.p3),
        connect(Bus3.p1, Line2.Ain),
        connect(Bus3.p2, Line2.Bin),
        connect(Bus3.p3, Line2.Cin),
        connect(Line2.Aout, Bus4.p1),
        connect(Line2.Bout, Bus4.p2),
        connect(Line2.Cout, Bus4.p3),
        connect(Bus4.p1, Load.A),
        connect(Bus4.p2, Load.B),
        connect(Bus4.p3, Load.C),
    ]
    System(eqs, t, [], []; name, systems)
end
# Batch 13, PLAN-13 step 4.2. The same network RMT as `Line_MT.jl` with `ModelType = 1`, i.e.
# `MT_FiniteImpedance`, and the six Norton equivalent admittances `IEEE4_MonoTri` hands its `Transformer_MT`,
# where `Connection = 3` ignores them (F-83). They also have to be non-zero: with the model's shipped defaults
# that function inverts the null matrix and returns 32 NaNs (F-97). The finite admittances load the three-phase
# side, so this oracle differs from `Line_MT`'s at `Bus3` and `Bus4` (`Bus3.Va` 0.9931 against 0.9922).
# Same `skip`/`rename` as `Line_MT.jl`.
@testset "PortTests.ThreePhase.Line_MT_FinImp" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "ThreePhase.Line_MT_FinImp.jl"))
    aliases = transformer_aliases(oracle)
    skip = [aliases.skip; "Bus1.angleDisplay"; "Bus2.angleDisplay"]
    validate_against_oracle(Line_MT_FinImp, oracle; skip, aliases.rename)
end
