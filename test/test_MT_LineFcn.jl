# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# The two LineFcn functions and Line_MT (PLAN-13 steps 4.1 and 4.2). OpenIPSL 3.1.0 has no Test, Example or class
# that instantiates any of the three; `PortTests.ThreePhase.Line_MT` and `Line_MT_FinImp` (this port's own Tests)
# cover the two `ModelType`s on the RMT network, and what an oracle cannot see is here: the cross-check against the
# TransformerFcn family, the 1/Y012 limit of the finite-impedance branch, the NaN of its shipped defaults, and the
# per-phase equivalence of a decoupled `Line_MT(ModelType = 0)` with a positive-sequence `PwLine`.
# A LineFcn returns the 32 coefficients [Ar, Ai, MB1r, ..., D33i] of the hybrid pi model, from the 1x18 rows
# Yser, Ysht (and Y012), which are Vectors of 18 here.
@testset "MT_LineFcn and Line_MT" begin
    row(m) = [real(m[1, 1]), imag(m[1, 1]), real(m[1, 2]), imag(m[1, 2]), real(m[1, 3]), imag(m[1, 3]),
              real(m[2, 1]), imag(m[2, 1]), real(m[2, 2]), imag(m[2, 2]), real(m[2, 3]), imag(m[2, 3]),
              real(m[3, 1]), imag(m[3, 1]), real(m[3, 2]), imag(m[3, 2]), real(m[3, 3]), imag(m[3, 3])]
    diagrow(y) = row([y 0 0; 0 y 0; 0 0 y])
    R, X = 0.166666666667, 1.0
    y = 1 / (R + im * X)
    Z18 = zeros(18)

    # (a) A decoupled line with no shunt IS a Yg_Yg transformer at tap = 1: the two families share the closing
    # formulas, and at tap = 1 that transformer's two shunt halves (Gshk, Bshk, Gshm, Bshm) vanish, so both
    # functions see the same Yser and the same zero Ysht. This is the bridge between LineFcn and TransformerFcn.
    @test maximum(abs, MT_InfiniteImpedances(diagrow(y), Z18) .- TransformerFcn_Yg_Yg(X, R, 1.0)) < 1e-12
    # the interface coefficients of that case, as in test_TransformerFcn.jl
    v = MT_InfiniteImpedances(diagrow(y), Z18)
    @test v[1] + im * v[2] ≈ y atol = 1e-12            # A = the series admittance itself
    @test v[3] + im * v[4] ≈ -y / 3 atol = 1e-12       # MB1 = -y/3
    @test v[9] + im * v[10] ≈ -y atol = 1e-12          # C1 = -y

    # (b) MT_FiniteImpedance tends to MT_InfiniteImpedances as the Norton admittances grow - for a BALANCED
    # line. Nothing is singular here, unlike four of the five TransformerFcn._FinImp functions (F-83): a line's
    # Yser has a non-zero diagonal, so `Inverse(Yser)` is finite, and `Ysernew + Yshtmnew` returns Yser in the
    # limit, which is what the D coefficients and the G1..B3 sums read.
    Y012(g) = [g, 0.0, 0, 0, 0, 0, 0, 0, g, 0.0, 0, 0, 0, 0, 0, 0, g, 0.0]
    base = MT_InfiniteImpedances(diagrow(y), Z18)
    prev = Inf
    for g in (1e6, 1e9, 1e12)
        d = maximum(abs, MT_FiniteImpedance(diagrow(y), Z18, Y012(g)) .- base)
        @test d < prev / 100          # one factor of 1000 in Y012 is one factor of 1000 in the error
        prev = d
    end
    @test prev < 1e-9

    # For an UNBALANCED line it does not, and the reason is not the inverse but the filter (F-97 b). The
    # six C coefficients are computed from `Ysernew = PositiveFilter(Yser)` where MT_InfiniteImpedances uses
    # `Yser` itself, and `PositiveFilter` is a LEFT product C*Z: it projects the column index only. The MB
    # combination reads a column of the matrix and is therefore idempotent under it; the C combination reads a
    # ROW and is not, so on an unbalanced Yser the six C coefficients keep a CONSTANT offset - the same at every
    # Y012 - while the other 26 still converge as 1/Y012. The offset is exactly the difference the two
    # combinations see, which is what the last assertion pins down.
    Ycoupled = row([1.8794-3.9929im -1.1096+1.5824im -0.5004+1.0891im
                    -1.1096+1.5824im 2.0690-4.1181im -0.7714+1.3055im
                    -0.5004+1.0891im -0.7714+1.3055im 1.6050-3.8154im])
    Ccomb(Y) = [-(2*Y[1] - Y[3] + sqrt(3)*Y[4] - Y[5] - sqrt(3)*Y[6])/2,
                -(2*Y[2] - Y[4] - sqrt(3)*Y[3] - Y[6] + sqrt(3)*Y[5])/2,
                -(2*Y[7] - Y[9] + sqrt(3)*Y[10] - Y[11] - sqrt(3)*Y[12])/2,
                -(2*Y[8] - Y[10] - sqrt(3)*Y[9] - Y[12] + sqrt(3)*Y[11])/2,
                -(2*Y[13] - Y[15] + sqrt(3)*Y[16] - Y[17] - sqrt(3)*Y[18])/2,
                -(2*Y[14] - Y[16] - sqrt(3)*Y[15] - Y[18] + sqrt(3)*Y[17])/2]
    MBcomb(Y) = [-(2*Y[1] - Y[7] - sqrt(3)*Y[8] - Y[13] + sqrt(3)*Y[14])/6,
                 -(2*Y[2] - Y[8] + sqrt(3)*Y[7] - Y[14] - sqrt(3)*Y[13])/6]
    cbase = MT_InfiniteImpedances(Ycoupled, Z18)
    others = [i for i in 1:32 if !(9 <= i <= 14)]
    prev = Inf
    for g in (1e6, 1e9, 1e12)
        v = MT_FiniteImpedance(Ycoupled, Z18, Y012(g))
        d = maximum(abs, v[others] .- cbase[others])
        @test d < prev / 100                                            # the other 26 converge as 1/Y012
        @test maximum(abs, v[9:14] .- cbase[9:14]) ≈ 0.5419925777834678 atol = 1e-12   # the C offset does not move
        @test v[9:14] ≈ Ccomb(PositiveFilter(Ycoupled)) atol = 1e-8     # and this is where it comes from
        prev = d
    end
    @test prev < 1e-9
    @test Ccomb(Ycoupled) - Ccomb(PositiveFilter(Ycoupled)) != zeros(6)  # the C combination is not idempotent
    @test MBcomb(PositiveFilter(Ycoupled)) ≈ MBcomb(Ycoupled) atol = 1e-12   # the MB combination is

    # (c) With the shipped defaults of `Line_MT` (`Y012 = 0` and every `Bsht = 0`) the matrix
    # `A = Yabcnrt + Yshtk` that MT_FiniteImpedance inverts first is the NULL matrix: `Inverse` divides by
    # A*A + B*B = 0, so `B`, `D`, `E`, `Yshtm2` and `Yshtmnew` are all NaN and 20 of the 32 coefficients come out
    # NaN - the interface admittance `Ar`, `Ai` (through the G1..B3 sums) and the whole 3x3 D block (through
    # `Ysernew + Yshtmnew`). The twelve MB and C coefficients survive because they read `Ysernew` alone. Either way
    # `Line_MT(ModelType = 1)` is unusable as shipped (F-97 a), which is why this port's own Test passes the
    # six Norton admittances of `IEEE4_MonoTri`. Reproduced, not guarded against.
    nanv = MT_FiniteImpedance(diagrow(y), Z18, Z18)
    @test count(isnan, nanv) == 20
    @test all(isnan, nanv[[1, 2]])            # Ar, Ai
    @test all(isnan, nanv[15:32])             # the nine D coefficients
    @test !any(isnan, nanv[3:14])             # MB1..MB3 and C1..C3

    # (d) `Line_MT(ModelType = 0)` with a decoupled Yser, between a positive-sequence source and a balanced wye
    # load, reproduces the positive-sequence `PwLine` of batch 2 phase by phase. Note the bases: the hybrid line
    # has `p` in per unit of S_b and A/B/C in per unit of S_p = S_b/3, so the three-phase load carries a third of
    # the watts of the positive-sequence one and the pin currents are equal 1x (the correction of PLAN-09).
    P0, Q0 = 30e6, 10e6
    @named msrc = InfiniteBus(; v_0 = 1.0, angle_0 = 0.0)
    @named mb1 = Bus()
    @named mline = PwLine(; R, X, G = 0.0, B = 0.0)
    @named mb2 = Bus()
    @named mload = PQ(; P_0 = P0, Q_0 = Q0)
    @named mrig = System(Equation[connect(msrc.p, mb1.p), connect(mb1.p, mline.p), connect(mline.n, mb2.p),
            connect(mb2.p, mload.p)], t, [], []; systems = [msrc, mb1, mline, mb2, mload])
    msys = mtkcompile(mrig)
    mi = init(ODEProblem(msys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)

    @named hsrc = InfiniteBus(; v_0 = 1.0, angle_0 = 0.0)
    @named hb1 = Bus()
    @named hline = Line_MT(; ModelType = 0, Gseraa = real(y), Bseraa = imag(y), Gserbb = real(y),
        Bserbb = imag(y), Gsercc = real(y), Bsercc = imag(y))
    @named hb2 = Bus_3Ph()
    @named hload = WyeLoad_3Ph(; P_a = P0 / 3, Q_a = Q0 / 3, P_b = P0 / 3, Q_b = Q0 / 3,
        P_c = P0 / 3, Q_c = Q0 / 3)
    @named hrig = System(Equation[connect(hsrc.p, hb1.p), connect(hline.p, hb1.p),
            connect(hline.A, hb2.p1), connect(hline.B, hb2.p2), connect(hline.C, hb2.p3),
            connect(hb2.p1, hload.A), connect(hb2.p2, hload.B), connect(hb2.p3, hload.C)], t, [], [];
        systems = [hsrc, hb1, hline, hb2, hload])
    hsys = mtkcompile(hrig)
    hi = init(ODEProblem(hsys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
    @test hi[hsys.hb2.Va] ≈ mi[msys.mb2.v] atol = 1e-9
    @test hi[hsys.hload.A.ir] ≈ mi[msys.mload.p.ir] atol = 1e-9
    @test hi[hsys.hload.A.ii] ≈ mi[msys.mload.p.ii] atol = 1e-9
    # the three phases are balanced and the positive-sequence pin carries the whole current
    @test hi[hsys.hb2.Vb] ≈ hi[hsys.hb2.Va] atol = 1e-9
    @test hi[hsys.hb2.Vc] ≈ hi[hsys.hb2.Va] atol = 1e-9
    @test hi[hsys.hline.p.ir] ≈ mi[msys.mline.p.ir] atol = 1e-9
    @test hi[hsys.hline.p.ii] ≈ mi[msys.mline.p.ii] atol = 1e-9
end
