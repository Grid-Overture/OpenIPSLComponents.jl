# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# ThreePhase lines (PLAN-09 step 2.1). `Tests.ThreePhase.IEEE13` is the only Test that instantiates Line_1Ph and
# Line_2Ph and it runs at ~1e-9 pu (F-79), so the family is exercised here at real currents, with both ends held at
# a fixed voltage. The pi model is  Iin = (Yser + Ysht)*Vin - Yser*Vout,  Iout = -Yser*Vin + (Yser + Ysht)*Vout
# with the complex entries Yser[j,k] = Gser_jk + j*Bser_jk and Ysht[j,k] = zero + j*Bsht_jk; the .jl writes it as
# the real 2x2-block matrices of the .mo, so the complex product below is an independent check of the embedding.
# With only the diagonal filled, a phase of Line_3Ph is one PwLine of the same admittance (cross-check with batch 0).
@testset "ThreePhase lines" begin
    # a rig of fixed sources on every pin of a line, in the order the model declares them
    function feed(line, pins, volts)
        srcs = [FixedVoltageSource(; name = Symbol(:s, i), vr = real(v), vi = imag(v)) for (i, v) in enumerate(volts)]
        eqs = [connect(s.p, getproperty(line, p)) for (s, p) in zip(srcs, pins)]
        @named rig = System(Equation[eqs...], t, [], []; systems = [srcs; line])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
        integ, getproperty(sys, nameof(line))
    end
    cur(integ, l, pin) = integ[getproperty(l, pin).ir] + im * integ[getproperty(l, pin).ii]

    Vin = [1.02 * cis(0.0), 1.0 * cis(-2pi / 3), 0.98 * cis(2pi / 3)]
    Vout = [0.97 * cis(-0.12), 0.95 * cis(-2pi / 3 - 0.1), 0.99 * cis(2pi / 3 - 0.08)]

    # Line_3Ph with couplings, against the complex 3x3 product
    g = [1.8794 -1.1096 -0.5004; -1.1096 2.0690 -0.7714; -0.5004 -0.7714 1.6050]
    b = [-3.9929 1.5824 1.0891; 1.5824 -4.1181 1.3055; 1.0891 1.3055 -3.8154]
    bs = [0.02 0.003 0.001; 0.003 0.025 0.002; 0.001 0.002 0.03]
    Yser = g .+ im .* b
    Ysht = LINE_ZERO .+ im .* bs
    @named line = Line_3Ph(; Gseraa = g[1, 1], Bseraa = b[1, 1], Gserab = g[1, 2], Bserab = b[1, 2],
        Gserac = g[1, 3], Bserac = b[1, 3], Gserbb = g[2, 2], Bserbb = b[2, 2], Gserbc = g[2, 3], Bserbc = b[2, 3],
        Gsercc = g[3, 3], Bsercc = b[3, 3], Bshtaa = bs[1, 1], Bshtab = bs[1, 2], Bshtac = bs[1, 3],
        Bshtbb = bs[2, 2], Bshtbc = bs[2, 3], Bshtcc = bs[3, 3])
    integ, L = feed(line, (:Ain, :Bin, :Cin, :Aout, :Bout, :Cout), [Vin; Vout])
    Iin = (Yser + Ysht) * Vin - Yser * Vout
    Iout = -Yser * Vin + (Yser + Ysht) * Vout
    for (k, pin) in enumerate((:Ain, :Bin, :Cin))
        @test cur(integ, L, pin) ≈ Iin[k] atol = 1e-9
    end
    for (k, pin) in enumerate((:Aout, :Bout, :Cout))
        @test cur(integ, L, pin) ≈ Iout[k] atol = 1e-9
    end

    # Line_3Ph with only the diagonal = three PwLine of the same series admittance and shunt half susceptance
    R, X, Bsh = 0.01, 0.1, 0.02
    G3, B3 = R / (R^2 + X^2), -X / (R^2 + X^2)
    @named dline = Line_3Ph(; Gseraa = G3, Bseraa = B3, Gserbb = G3, Bserbb = B3, Gsercc = G3, Bsercc = B3,
        Bshtaa = Bsh, Bshtbb = Bsh, Bshtcc = Bsh)
    dinteg, DL = feed(dline, (:Ain, :Bin, :Cin, :Aout, :Bout, :Cout), [Vin; Vout])
    for (k, (pin, vs, vr)) in enumerate(zip((:Ain, :Bin, :Cin), Vin, Vout))
        @named pw = PwLine(; R, X, G = 0.0, B = Bsh)
        @named ps = FixedVoltageSource(; vr = real(vs), vi = imag(vs))
        @named pr = FixedVoltageSource(; vr = real(vr), vi = imag(vr))
        @named prig = System(Equation[connect(ps.p, pw.p), connect(pr.p, pw.n)], t, [], []; systems = [ps, pr, pw])
        psys = mtkcompile(prig)
        pint = init(ODEProblem(psys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
        @test cur(dinteg, DL, pin) ≈ pint[psys.pw.p.ir] + im * pint[psys.pw.p.ii] atol = 1e-9
    end

    # Line_2Ph and Line_1Ph are the same pi model on 2 and 1 phases
    g2 = [0.7502 -0.25; -0.25 0.7450]
    b2 = [-0.69 0.1038; 0.1038 -0.6931]
    @named line2 = Line_2Ph(; Gseraa = g2[1, 1], Bseraa = b2[1, 1], Gserab = g2[1, 2], Bserab = b2[1, 2],
        Gserbb = g2[2, 2], Bserbb = b2[2, 2])
    i2, L2 = feed(line2, (:Ain, :Bin, :Aout, :Bout), [Vin[1:2]; Vout[1:2]])
    Y2 = g2 .+ im .* b2
    I2in = (Y2 .+ LINE_ZERO) * Vin[1:2] - Y2 * Vout[1:2]
    @test cur(i2, L2, :Ain) ≈ I2in[1] atol = 1e-9
    @test cur(i2, L2, :Bin) ≈ I2in[2] atol = 1e-9
    @test cur(i2, L2, :Aout) ≈ (-Y2 * Vin[1:2] + (Y2 .+ LINE_ZERO) * Vout[1:2])[1] atol = 1e-9

    @named line1 = Line_1Ph(; Gser = 0.7426, Bser = -0.2834, Bsht = 0.01)
    i1, L1 = feed(line1, (:Ain, :Aout), [Vin[1], Vout[1]])
    y1 = 0.7426 - 0.2834im
    @test cur(i1, L1, :Ain) ≈ (y1 + LINE_ZERO + 0.01im) * Vin[1] - y1 * Vout[1] atol = 1e-9
    @test cur(i1, L1, :Aout) ≈ -y1 * Vin[1] + (y1 + LINE_ZERO + 0.01im) * Vout[1] atol = 1e-9
end
