# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/ThreePhase/Line_MT.mo (a Test of this port, not OpenIPSL's: PLAN-12), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function Line_MT_Test(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        infiniteBus = InfiniteBus(; S_b, fn)
        Bus1 = Bus(; S_b, fn)
        Line1 = PwLine(; B = 0.0, G = 0.0, R = 0.074563536332, X = 0.152732235479, S_b, fn)
        Bus2 = Bus(; angle_0 = 0.0, v_0 = 1.0, S_b, fn)
        HybridLine = Line_MT(; ModelType = 0, Gseraa = 0.162162, Bseraa = -0.972973, Gserab = 0.0, Bserab = 0.0, Gserac = 0.0, Bserac = 0.0, Gserbb = 0.162162, Bserbb = -0.972973, Gserbc = 0.0, Bserbc = 0.0, Gsercc = 0.162162, Bsercc = -0.972973, Bshtaa = 0.0, Bshtab = 0.0, Bshtac = 0.0, Bshtbb = 0.0, Bshtbc = 0.0, Bshtcc = 0.0, S_b, fn)
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
# Batch 13, PLAN-13 step 4.2. Network RMT of the plan: the positive-sequence side of
# `Tests.ThreePhase.IEEE4_MonoTri` (the PSAT `infiniteBus`, two `Bus`, one `PwLine`) feeding the hybrid line in
# the slot its sibling `Transformer_MT` occupies there, and from there the three-phase `Line2`, `Bus4` and load of
# that Test at one fifth. `ModelType = 0`, i.e. `MT_InfiniteImpedances`, on the decoupled series admittance of the
# transformer it replaces, `1/(0.166666666667 + j1) = 0.162162 - j0.972973`. Zero states, zero events (F-81).
# `skip` and `rename`: OpenModelica writes the display columns the batch-0/2 ports omit (`Bus.angleDisplay`,
# `PwLine.P12/P21/Q12/Q21`) and the Complex aliases vs, is, vr, ir of `PwLine`, which the port keeps as the pin
# variables of p and n (`transformer_aliases`, as in `IEEE4_MonoTri.jl`).
@testset "PortTests.ThreePhase.Line_MT" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "ThreePhase.Line_MT.jl"))
    aliases = transformer_aliases(oracle)
    skip = [aliases.skip; "Bus1.angleDisplay"; "Bus2.angleDisplay"]
    validate_against_oracle(Line_MT_Test, oracle; skip, aliases.rename)
end
