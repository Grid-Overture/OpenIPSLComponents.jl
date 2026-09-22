# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# The fourteen TransformerFcn functions and Transformer_MT (PLAN-09 steps 6.2 and 6.3). The only upstream Test that
# instantiates Transformer_MT is `Tests.ThreePhase.IEEE4_MonoTri`, and it uses Connection = 3 with ModelType = 0:
# the other eight connections and the whole finite-impedance path are exercised here.
# A TransformerFcn returns the 32 coefficients [Ar, Ai, MB1r, ..., D33i] of the hybrid pi model; the nine D
# coefficients are the same 3x3 complex block as the D block of the corresponding TransfConnection 12x12, which is
# the bridge between the two families. They differ by at most the 1e-6 fillers TransfConnection puts off the
# diagonal and TransformerFcn writes as a literal zero.
@testset "TransformerFcn and Transformer_MT" begin
    cplx(M) = [M[2i - 1, 2j - 1] + im * M[2i, 2j - 1] for i in 1:div(size(M, 1), 2), j in 1:div(size(M, 2), 2)]
    dcoef(v) = [v[15]+im*v[16] v[17]+im*v[18] v[19]+im*v[20]
                v[21]+im*v[22] v[23]+im*v[24] v[25]+im*v[26]
                v[27]+im*v[28] v[29]+im*v[30] v[31]+im*v[32]]
    R, X = 0.16666667, 1.0
    y = 1 / (R + im * X)
    pairs = [(0, TransfConnection_Yg_Yg, TransformerFcn_Yg_Yg), (1, TransfConnection_D_D, TransformerFcn_D_D),
        (2, TransfConnection_Y_Y, TransformerFcn_Y_Y), (3, TransfConnection_D_Yg, TransformerFcn_D_Yg),
        (4, TransfConnection_Yg_D, TransformerFcn_Yg_D), (5, TransfConnection_D_Y, TransformerFcn_D_Y),
        (6, TransfConnection_Y_D, TransformerFcn_Y_D), (7, TransfConnection_Y_Yg, TransformerFcn_Y_Yg),
        (8, TransfConnection_Yg_Y, TransformerFcn_Yg_Y)]
    for (_, tc, tf) in pairs, tap in (1.0, 1.05)
        v = tf(X, R, tap)
        @test length(v) == 32
        @test maximum(abs, cplx(tc(X, R, tap)[7:12, 7:12]) - dcoef(v)) < 3e-6
    end
    # Yg_Yg at tap = 1: the interface coefficient A is the series admittance itself
    v = TransformerFcn_Yg_Yg(X, R, 1.0)
    @test v[1] + im * v[2] ≈ y atol = 1e-12
    @test v[3] + im * v[4] ≈ -y / 3 atol = 1e-12          # MB1 = -y/3, the positive-sequence combination
    @test v[9] + im * v[10] ≈ -y atol = 1e-12             # C1 = -y

    # The finite-impedance variants. Only Yg_Yg_FinImp tends to its own base as the Norton admittances grow: its
    # error falls like 1/Y012 (6.1e-7 at 1e6, 6.1e-13 at 1e12). The other four cannot, because they invert a
    # SINGULAR matrix: their series matrix is the wye/delta circulant 2y/3 on the diagonal and -y/3 off it, whose
    # determinant is exactly zero (no zero-sequence path), so `C = Inverse(Yser)` comes out at 1e16 and
    # `Yshtm2 = NegZerFilter(E)` never recovers Yser. Their D coefficients keep a constant offset of |mBser|, which
    # is |Im(y)|/3, for every value of Y012. Copied as it is (F-83): an OpenIPSL 3.1.0 quirk, not a transcription
    # error, and no Test of the library reaches it - `IEEE4_MonoTri` uses Connection = 3, where ModelType is ignored.
    Y012(g) = [g, 0.0, 0, 0, 0, 0, 0, 0, g, 0.0, 0, 0, 0, 0, 0, 0, g, 0.0]
    base = TransformerFcn_Yg_Yg(X, R, 1.0)
    prev = Inf
    for g in (1e6, 1e9, 1e12)
        d = maximum(abs, TransformerFcn_Yg_Yg_FinImp(X, R, 1.0, Y012(g)) .- base)
        @test d < prev / 100          # falls like 1/Y012
        prev = d
    end
    @test maximum(abs, TransformerFcn_Yg_Yg_FinImp(X, R, 1.0, Y012(1e12)) .- base) < 1e-11
    for (b, f) in ((TransformerFcn_D_D, TransformerFcn_D_D_FinImp), (TransformerFcn_Y_Y, TransformerFcn_Y_Y_FinImp),
                   (TransformerFcn_Y_Yg, TransformerFcn_Y_Yg_FinImp), (TransformerFcn_Yg_Y, TransformerFcn_Yg_Y_FinImp))
        @test maximum(abs, f(X, R, 1.0, Y012(1e12)) .- b(X, R, 1.0)) ≈ abs(imag(y)) / 3 atol = 1e-9
    end
    # with the Norton admittances of IEEE4_MonoTri all five return 32 finite numbers
    Y = [0.729734359723, -1.82768503568, 0, 0, 0, 0, 0, 0, 2.58122706441, -5.2872570055, 0, 0, 0, 0, 0, 0,
        2.58122706441, -5.2872570055]
    for f in (TransformerFcn_Yg_Yg_FinImp, TransformerFcn_D_D_FinImp, TransformerFcn_Y_Y_FinImp,
              TransformerFcn_Y_Yg_FinImp, TransformerFcn_Yg_Y_FinImp)
        w = f(X, R, 1.0, Y)
        @test length(w) == 32 && all(isfinite, w)
    end

    # Transformer_MT: pin p on the positive-sequence side, A, B, C on the three-phase side, all held at a fixed
    # voltage so that the currents are the matrix product alone.
    function rig(; V1, V3, kwargs...)
        @named sp = FixedVoltageSource(; vr = real(V1), vi = imag(V1))
        @named sa = FixedVoltageSource(; vr = real(V3[1]), vi = imag(V3[1]))
        @named sb = FixedVoltageSource(; vr = real(V3[2]), vi = imag(V3[2]))
        @named sc = FixedVoltageSource(; vr = real(V3[3]), vi = imag(V3[3]))
        @named tr = Transformer_MT(; kwargs...)
        @named r = System(Equation[connect(sp.p, tr.p), connect(sa.p, tr.A), connect(sb.p, tr.B),
                connect(sc.p, tr.C)], t, [], []; systems = [sp, sa, sb, sc, tr])
        sys = mtkcompile(r)
        init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-12, reltol = 1e-12), sys
    end
    cur(i, s, p) = i[getproperty(s.tr, p).ir] + im * i[getproperty(s.tr, p).ii]
    a = cis(2pi / 3)
    V = 1.0 + 0.0im

    # The eight equations are the complex products  p.I = A*p.V + MB1*A.V + MB2*B.V + MB3*C.V,
    # A.I = C1*p.V + D11*A.V + D12*B.V + D13*C.V, and so on: with all four pins held at a fixed voltage the currents
    # are those products alone, which is what checks that the 32 coefficients reach the right equation in the right
    # order, for every connection.
    Vp = 1.01 * cis(0.03)
    Vabc = [0.97 * cis(-0.1), 1.02 * cis(-2pi / 3 + 0.05), 0.99 * cis(2pi / 3 - 0.07)]
    for (conn, _, f) in pairs
        i5, s5 = rig(; V1 = Vp, V3 = Vabc, Connection = conn, ModelType = 0, tap = 1.05, R, X)
        c = f(X, R, 1.05)
        z(k) = c[2k - 1] + im * c[2k]
        @test cur(i5, s5, :p) ≈ z(1) * Vp + z(2) * Vabc[1] + z(3) * Vabc[2] + z(4) * Vabc[3] atol = 1e-12
        @test cur(i5, s5, :A) ≈ z(5) * Vp + z(8) * Vabc[1] + z(9) * Vabc[2] + z(10) * Vabc[3] atol = 1e-12
        @test cur(i5, s5, :B) ≈ z(6) * Vp + z(11) * Vabc[1] + z(12) * Vabc[2] + z(13) * Vabc[3] atol = 1e-12
        @test cur(i5, s5, :C) ≈ z(7) * Vp + z(14) * Vabc[1] + z(15) * Vabc[2] + z(16) * Vabc[3] atol = 1e-12
    end

    # Connection = 0, tap = 1: a grounded-wye-grounded-wye bank of three R + jX branches. With the three-phase side
    # at the positive-sequence image of the mono side there is no drop anywhere and nothing flows.
    i1, s1 = rig(; V1 = V, V3 = [V, V * conj(a), V * a], Connection = 0, ModelType = 0, tap = 1.0, R, X)
    for p in (:p, :A, :B, :C)
        @test abs(cur(i1, s1, p)) < 1e-12
    end
    # with the three-phase side 5% low, each phase draws y*(0.95 - 1)*V and the mono pin carries the same PER-UNIT
    # current with the opposite sign - i.e. three times the phase current in amperes, since its base is S_b and the
    # phase base is S_b/3 (the "one third" of the PLAN-09 decision table, corrected here).
    i2, s2 = rig(; V1 = V, V3 = [0.95V, 0.95V * conj(a), 0.95V * a], Connection = 0, ModelType = 0, tap = 1.0, R, X)
    @test cur(i2, s2, :A) ≈ y * (0.95V - V) atol = 1e-12
    @test cur(i2, s2, :p) ≈ -cur(i2, s2, :A) atol = 1e-12
    # ModelType is only read for Connection 0, 1, 2, 7 and 8; with huge Norton admittances it changes nothing there
    i2b, s2b = rig(; V1 = V, V3 = [0.95V, 0.95V * conj(a), 0.95V * a], Connection = 0, ModelType = 1, tap = 1.0,
        R, X, G_0 = 1e12, G_1 = 1e12, G_2 = 1e12)
    @test cur(i2b, s2b, :p) ≈ cur(i2, s2, :p) atol = 1e-9
    # and for Connection 3 to 6 the .mo ignores it altogether
    V3u = [0.97 * cis(-0.1), 1.02 * cis(-2pi / 3 + 0.05), 0.99 * cis(2pi / 3 - 0.07)]
    V1u = 1.01 * cis(0.03)
    i3a, s3a = rig(; V1 = V1u, V3 = V3u, Connection = 3, ModelType = 0, tap = 1.0, R, X)
    i3b, s3b = rig(; V1 = V1u, V3 = V3u, Connection = 3, ModelType = 1, tap = 1.0, R, X, G_0 = 5.0, G_1 = 5.0)
    @test cur(i3b, s3b, :p) ≈ cur(i3a, s3a, :p) atol = 1e-12

    # Power balance across the interface: with R = 0 the model is lossless, so the watts the mono side absorbs are
    # the watts the three phases deliver, on their own bases S_b and S_p = S_b/3. This holds for all nine
    # connections and is what ties the two per-unit systems together.
    S_b = 100e6
    for conn in 0:8
        i4, s4 = rig(; V1 = V1u, V3 = V3u, Connection = conn, ModelType = 0, tap = 1.0, R = 0.0, X = 1.0)
        Pm = real(V1u * conj(cur(i4, s4, :p))) * S_b
        P3 = sum(real(V3u[k] * conj(cur(i4, s4, p))) for (k, p) in enumerate((:A, :B, :C))) * (S_b / 3)
        @test abs(Pm + P3) < 1e-6 * max(abs(Pm), 1.0)
    end
end
