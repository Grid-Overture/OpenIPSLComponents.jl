# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# The nine TransfConnection functions and Transformer_3Ph (PLAN-09 steps 4.1 and 4.2). No upstream Test covers the
# functions, and `Tests.ThreePhase.{IEEE4, IEEE13}` only ever instantiate Connection = 0, so the other eight
# connections are exercised here.
# Each function returns the 12x12 real embedding of the complex 6x6 pi matrix [A B; C D], with the 2x2 blocks
# [G -B; B G] of an admittance G + jB. `cplx` below folds it back to the complex 6x6, which is an independent
# check of the embedding. `zero = 1e-6` is a filler of the .mo (not `eps` as in the lines) and is copied: it shows
# up as 1e-6 in the off-diagonal entries of B and as its double in A, because Y_ser and Yshtk both carry it.
@testset "TransfConnection and Transformer_3Ph" begin
    cplx(M) = [M[2i - 1, 2j - 1] + im * M[2i, 2j - 1] for i in 1:div(size(M, 1), 2), j in 1:div(size(M, 2), 2)]
    blocks(M) = (cplx(M[1:6, 1:6]), cplx(M[1:6, 7:12]), cplx(M[7:12, 1:6]), cplx(M[7:12, 7:12]))
    R, X = 0.16666667, 1.0
    y = 1 / (R + im * X)
    fns = [(0, TransfConnection_Yg_Yg), (1, TransfConnection_D_D), (2, TransfConnection_Y_Y),
        (3, TransfConnection_D_Yg), (4, TransfConnection_Yg_D), (5, TransfConnection_D_Y),
        (6, TransfConnection_Y_D), (7, TransfConnection_Y_Yg), (8, TransfConnection_Yg_Y)]
    symmetric = (0, 1, 2, 7, 8)   # B = C = -Y_ser; the other four have B = -Y_ser1, C = -Y_ser2 = -transpose(Y_ser1)

    for (conn, f) in fns, tap in (1.0, 1.05)
        M = f(X, R, tap)
        @test size(M) == (12, 12)
        A, B, C, D = blocks(M)
        @test C == transpose(B)                      # C = -Y_ser2 is the block transpose of B = -Y_ser1
        @test (B == C) == (conn in symmetric)
    end

    # Yg_Yg with tap = 1: one series admittance 1/(R + jX) per phase, no shunt, and the 1e-6 fillers off the diagonal
    A, B, C, D = blocks(TransfConnection_Yg_Yg(X, R, 1.0))
    @test A[1, 1] ≈ y atol = 1e-12
    @test B[1, 1] ≈ -y atol = 1e-12
    @test A == D                                     # Gshk = Gshm = 0 at tap = 1
    for k in 2:3
        @test A[1, k] ≈ 2e-6 + 2e-6im atol = 1e-15   # zero in Y_ser plus zero in Yshtk
        @test B[1, k] ≈ -1e-6 - 1e-6im atol = 1e-15
    end
    # tap != 1: Yser = (1/tap)*y, Yshtk = (1/tap)*((1/tap) - 1)*y, Yshtm = (1 - 1/tap)*y
    tap = 1.05
    A, B, C, D = blocks(TransfConnection_Yg_Yg(X, R, tap))
    @test B[1, 1] ≈ -(1 / tap) * y atol = 1e-12
    @test A[1, 1] ≈ (1 / tap) * y + (1 / tap) * ((1 / tap) - 1) * y atol = 1e-12
    @test D[1, 1] ≈ (1 / tap) * y + (1 - 1 / tap) * y atol = 1e-12
    # D_D and Y_Y are the same function of (X, R, tap) in OpenIPSL 3.1.0, and so are D_Y and Y_D
    @test TransfConnection_D_D(X, R, 1.03) == TransfConnection_Y_Y(X, R, 1.03)
    @test TransfConnection_D_Y(X, R, 1.03) == TransfConnection_Y_D(X, R, 1.03)

    # Transformer_3Ph with both sides held at a fixed voltage: the twelve pin currents are the matrix product, for
    # every connection. This is what checks the pin order (Ain, Bin, Cin, Aout, Bout, Cout) and the four blocks.
    Vin = [1.02 * cis(0.0), 1.0 * cis(-2pi / 3), 0.98 * cis(2pi / 3)]
    Vout = [0.97 * cis(-0.12), 0.95 * cis(-2pi / 3 - 0.1), 0.99 * cis(2pi / 3 - 0.08)]
    stack(V) = vcat([[real(v), imag(v)] for v in V]...)
    for (conn, f) in fns
        @named tr = Transformer_3Ph(; Connection = conn, R, X, tap = 1.0)
        srcs = [FixedVoltageSource(; name = Symbol(:s, i), vr = real(v), vi = imag(v))
                for (i, v) in enumerate([Vin; Vout])]
        pins = (:Ain, :Bin, :Cin, :Aout, :Bout, :Cout)
        @named rig = System(Equation[[connect(s.p, getproperty(tr, p)) for (s, p) in zip(srcs, pins)]...],
            t, [], []; systems = [srcs; tr])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-12, reltol = 1e-12)
        expected = f(X, R, 1.0) * stack([Vin; Vout])
        for (k, p) in enumerate(pins)
            pin = getproperty(sys.tr, p)
            @test integ[pin.ir] ≈ expected[2k - 1] atol = 1e-9
            @test integ[pin.ii] ≈ expected[2k] atol = 1e-9
        end
    end

    # Connection = 0 at tap = 1 is three independent R + jX branches: with a balanced load it draws the same
    # current as one PwLine feeding the equivalent PQ load of batch 0 (the 1e-6 fillers are the whole difference).
    P0, Q0 = 30e6, 10e6
    @named a1 = FixedVoltageSource(; vr = 1.0, vi = 0.0)
    @named a2 = FixedVoltageSource(; vr = cos(-2pi / 3), vi = sin(-2pi / 3))
    @named a3 = FixedVoltageSource(; vr = cos(2pi / 3), vi = sin(2pi / 3))
    @named tr0 = Transformer_3Ph(; Connection = 0, R, X, tap = 1.0)
    @named bo = Bus_3Ph()
    @named ld = WyeLoad_3Ph(; P_a = P0 / 3, Q_a = Q0 / 3, P_b = P0 / 3, Q_b = Q0 / 3, P_c = P0 / 3, Q_c = Q0 / 3)
    @named rig0 = System(Equation[connect(a1.p, tr0.Ain), connect(a2.p, tr0.Bin), connect(a3.p, tr0.Cin),
            connect(tr0.Aout, bo.p1), connect(tr0.Bout, bo.p2), connect(tr0.Cout, bo.p3),
            connect(bo.p1, ld.A), connect(bo.p2, ld.B), connect(bo.p3, ld.C)], t, [], [];
        systems = [a1, a2, a3, tr0, bo, ld])
    sys0 = mtkcompile(rig0)
    i0 = init(ODEProblem(sys0, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-12, reltol = 1e-12)
    @named m1 = FixedVoltageSource(; vr = 1.0, vi = 0.0)
    @named mline = PwLine(; R, X, G = 0.0, B = 0.0)
    @named mb = Bus()
    @named mld = PQ(; P_0 = P0, Q_0 = Q0)
    @named mrig = System(Equation[connect(m1.p, mline.p), connect(mline.n, mb.p), connect(mb.p, mld.p)],
        t, [], []; systems = [m1, mline, mb, mld])
    msys = mtkcompile(mrig)
    mi = init(ODEProblem(msys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-12, reltol = 1e-12)
    @test i0[sys0.bo.Va] ≈ mi[msys.mb.v] atol = 1e-5
    @test i0[sys0.tr0.Ain.ir] ≈ mi[msys.mline.p.ir] atol = 1e-5
    @test i0[sys0.tr0.Ain.ii] ≈ mi[msys.mline.p.ii] atol = 1e-5

    # Phase displacement, read on an OPEN secondary (a Bus_3Ph forces zero current): 0 for the wye-wye family and
    # +30 degrees for D-Yg. Only Connection 0, 3 and 7 can be read this way - the other six have an ungrounded-wye
    # or delta secondary, whose D block has no zero-sequence path and is singular when the pins carry no current.
    for (conn, shift) in ((0, 0.0), (7, 0.0), (3, pi / 6))
        @named b1 = FixedVoltageSource(; vr = 1.0, vi = 0.0)
        @named b2 = FixedVoltageSource(; vr = cos(-2pi / 3), vi = sin(-2pi / 3))
        @named b3 = FixedVoltageSource(; vr = cos(2pi / 3), vi = sin(2pi / 3))
        @named trn = Transformer_3Ph(; Connection = conn, R, X, tap = 1.0)
        @named bus = Bus_3Ph()
        @named orig = System(Equation[connect(b1.p, trn.Ain), connect(b2.p, trn.Bin), connect(b3.p, trn.Cin),
                connect(trn.Aout, bus.p1), connect(trn.Bout, bus.p2), connect(trn.Cout, bus.p3)], t, [], [];
            systems = [b1, b2, b3, trn, bus])
        osys = mtkcompile(orig)
        oi = init(ODEProblem(osys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-12, reltol = 1e-12)
        @test oi[osys.bus.Va] ≈ 1.0 atol = 1e-5
        @test oi[osys.bus.angle_a] ≈ shift atol = 1e-4
        @test oi[osys.bus.angle_b] ≈ shift - 2pi / 3 atol = 1e-4
    end
end
