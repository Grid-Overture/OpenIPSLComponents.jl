# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# ThreePhase loads (PLAN-09 steps 3.1 and 3.2). `Tests.ThreePhase.IEEE13` instantiates all four of them but its
# powers are watts over a 33.3 MVA base (F-79), so its load currents are ~1e-9 pu and lie under the 1e-4 absolute
# floor of the oracle threshold: the family is exercised here at real currents.
# The convention is S = V*conj(I) with S = P + jQ, because the .mo writes Pa = vr*ir + vi*ii and Qa = vi*ir - vr*ii;
# a constant-power phase therefore draws I = conj(S)/conj(V), and a delta branch I_ab = conj(S_ab)/conj(V_A - V_B).
@testset "ThreePhase loads" begin
    S_p = 100e6 / 3
    function feed(load, pins, volts; extra = eqs -> Equation[])
        srcs = [FixedVoltageSource(; name = Symbol(:s, i), vr = real(v), vi = imag(v)) for (i, v) in enumerate(volts)]
        eqs = [connect(s.p, getproperty(load, p)) for (s, p) in zip(srcs, pins)]
        @named rig = System(Equation[eqs...; extra(load)...], t, [], []; systems = [srcs; load])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
        integ, getproperty(sys, nameof(load))
    end
    cur(integ, l, pin) = integ[getproperty(l, pin).ir] + im * integ[getproperty(l, pin).ii]

    # WyeLoad_3Ph, constant power (ModelType = 0), at the IEEE4 powers and 1 pu per phase
    Pw, Qw = (1.275e6, 1.8e6, 2.375e6), (0.79e6, 0.872e6, 0.781e6)
    V3 = [1.0 * cis(0.0), 1.0 * cis(-2pi / 3), 1.0 * cis(2pi / 3)]
    @named wye3 = WyeLoad_3Ph(; ModelType = 0, P_a = Pw[1], Q_a = Qw[1], P_b = Pw[2], Q_b = Qw[2],
        P_c = Pw[3], Q_c = Qw[3])
    i3, W3 = feed(wye3, (:A, :B, :C), V3)
    for (k, pin) in enumerate((:A, :B, :C))
        S = (Pw[k] + im * Qw[k]) / S_p
        @test cur(i3, W3, pin) ≈ conj(S) / conj(V3[k]) atol = 1e-9
    end
    @test i3[W3.Pa] ≈ Pw[1] / S_p atol = 1e-12
    @test i3[W3.Qc] ≈ Qw[3] / S_p atol = 1e-12

    # WyeLoad_1Ph, the ZIP model at 0.9 pu: A_pa = 100 keeps the power, B_pa = 100 scales it by Va, C_pa by Va^2
    for (kw, factor) in (((; A_pa = 100), 1.0), ((; B_pa = 100), 0.9), ((; C_pa = 100), 0.81))
        @named wye1 = WyeLoad_1Ph(; ModelType = 1, P_a = 1.2e6, Q_a = 0.4e6, kw...)
        i1, W1 = feed(wye1, (:A,), [0.9 * cis(0.2)])
        @test i1[W1.Pa] ≈ factor * 1.2e6 / S_p atol = 1e-12
        @test i1[W1.Qa] ≈ factor * 0.4e6 / S_p atol = 1e-12
        @test cur(i1, W1, :A) ≈ conj(factor * (1.2e6 + 0.4e6im) / S_p) / conj(0.9 * cis(0.2)) atol = 1e-9
    end
    # ModelType = 0 ignores the percentages, ModelType = 1 with all of them at 0 is a load of zero
    @named wye1z = WyeLoad_1Ph(; ModelType = 1, P_a = 1.2e6, Q_a = 0.4e6)
    i1z, W1z = feed(wye1z, (:A,), [0.9 + 0.0im])
    @test abs(cur(i1z, W1z, :A)) ≈ 0 atol = 1e-12

    # DeltaLoad_2Ph: B draws exactly the opposite current of A and the ZIP voltage is the line voltage over sqrt(3)
    VA2, VB2 = 1.0 * cis(0.0), 1.0 * cis(-2pi / 3)
    @named d2 = DeltaLoad_2Ph(; ModelType = 0, P_ab = 0.17e6, Q_ab = 0.151e6)
    i2, D2 = feed(d2, (:A, :B), [VA2, VB2])
    Sab = (0.17e6 + 0.151e6im) / S_p
    @test cur(i2, D2, :A) ≈ conj(Sab) / conj(VA2 - VB2) atol = 1e-9
    @test cur(i2, D2, :B) ≈ -cur(i2, D2, :A) atol = 1e-12
    @test i2[D2.Vab] ≈ abs(VA2 - VB2) / sqrt(3) atol = 1e-9   # = 1 pu for a balanced pair
    # ZIP: B_ab = 100 scales by Vab, C_ab = 100 by Vab^2 (the two shapes IEEE13 uses)
    for (kw, factor) in (((; B_ab = 100), abs(VA2 - VB2) / sqrt(3)),
                         ((; C_ab = 100), (abs(VA2 - VB2) / sqrt(3))^2))
        @named d2z = DeltaLoad_2Ph(; ModelType = 1, P_ab = 0.17e6, Q_ab = 0.151e6, kw...)
        i2z, D2z = feed(d2z, (:A, :B), [VA2, VB2])
        @test i2z[D2z.Pab] ≈ factor * 0.17e6 / S_p atol = 1e-12
    end

    # DeltaLoad_3Ph: the three branch currents close on themselves, so the pin currents sum to zero
    Vd = [1.0 * cis(0.0), 0.98 * cis(-2pi / 3), 1.01 * cis(2pi / 3)]
    Pd, Qd = (0.385e6, 0.4e6, 0.36e6), (0.22e6, 0.2e6, 0.21e6)
    @named d3 = DeltaLoad_3Ph(; ModelType = 0, P_ab = Pd[1], Q_ab = Qd[1], P_bc = Pd[2], Q_bc = Qd[2],
        P_ca = Pd[3], Q_ca = Qd[3])
    i3d, D3 = feed(d3, (:A, :B, :C), Vd)
    Iab = conj((Pd[1] + im * Qd[1]) / S_p) / conj(Vd[1] - Vd[2])
    Ibc = conj((Pd[2] + im * Qd[2]) / S_p) / conj(Vd[2] - Vd[3])
    Ica = conj((Pd[3] + im * Qd[3]) / S_p) / conj(Vd[3] - Vd[1])
    @test cur(i3d, D3, :A) ≈ Iab - Ica atol = 1e-9
    @test cur(i3d, D3, :B) ≈ Ibc - Iab atol = 1e-9
    @test cur(i3d, D3, :C) ≈ Ica - Ibc atol = 1e-9
    @test abs(cur(i3d, D3, :A) + cur(i3d, D3, :B) + cur(i3d, D3, :C)) ≈ 0 atol = 1e-12

    # Cross-check with batch 0/2: with a THIRD of the mono load in watts on each phase, the per-phase per-unit
    # problem is the mono one, so phase a carries the same current as the PwLine and the three-phase source
    # supplies the same total watts as the PSAT infinite bus (not three times: the phase base is S_b/3, so each
    # phase reports a third of the watts - the "3x" of the PLAN-09 decision table, corrected here).
    R, X, P0, Q0 = 0.02, 0.2, 30e6, 10e6
    Gd, Bd = R / (R^2 + X^2), -X / (R^2 + X^2)
    @named msrc = InfiniteBus(; v_0 = 1.0, angle_0 = 0.0)
    @named mb1 = Bus()
    @named mline = PwLine(; R, X, G = 0.0, B = 0.0)
    @named mb2 = Bus()
    @named mload = PQ(; P_0 = P0, Q_0 = Q0)
    @named mrig = System(Equation[connect(msrc.p, mb1.p), connect(mb1.p, mline.p), connect(mline.n, mb2.p),
            connect(mb2.p, mload.p)], t, [], []; systems = [msrc, mb1, mline, mb2, mload])
    msys = mtkcompile(mrig)
    mi = init(ODEProblem(msys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)

    @named tsrc = ThreePhase_InfiniteBus()
    @named tb1 = Bus_3Ph()
    @named tline = Line_3Ph(; Gseraa = Gd, Bseraa = Bd, Gserbb = Gd, Bserbb = Bd, Gsercc = Gd, Bsercc = Bd)
    @named tb2 = Bus_3Ph()
    @named tload = WyeLoad_3Ph(; P_a = P0 / 3, Q_a = Q0 / 3, P_b = P0 / 3, Q_b = Q0 / 3, P_c = P0 / 3, Q_c = Q0 / 3)
    @named trig = System(Equation[connect(tsrc.p1, tb1.p1), connect(tsrc.p2, tb1.p2), connect(tsrc.p3, tb1.p3),
            connect(tb1.p1, tline.Ain), connect(tb1.p2, tline.Bin), connect(tb1.p3, tline.Cin),
            connect(tline.Aout, tb2.p1), connect(tline.Bout, tb2.p2), connect(tline.Cout, tb2.p3),
            connect(tb2.p1, tload.A), connect(tb2.p2, tload.B), connect(tb2.p3, tload.C)], t, [], [];
        systems = [tsrc, tb1, tline, tb2, tload])
    tsys = mtkcompile(trig)
    ti = init(ODEProblem(tsys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
    @test ti[tsys.tb2.Va] ≈ mi[msys.mb2.v] atol = 1e-9
    @test ti[tsys.tload.A.ir] ≈ mi[msys.mload.p.ir] atol = 1e-9
    @test ti[tsys.tload.A.ii] ≈ mi[msys.mload.p.ii] atol = 1e-9
    @test ti[tsys.tsrc.P] ≈ mi[msys.msrc.P] rtol = 1e-9
    @test ti[tsys.tsrc.Pa] ≈ mi[msys.msrc.P] / 3 rtol = 1e-9

    # ---------------------------------------------------------------- batch 13 (PLAN-13 steps 2.2 and 2.3)
    # The eight loads of batch 13 are validated against this port's own OpenModelica Tests
    # (PortTests.ThreePhase.*); what those oracles cannot see is here. The five Dyn_wye_* have no branch their
    # oracle misses, and WyeDynLoad_3Ph(ModelType = 0) is the load of the MeasurementBus Test, so only the two ZIP
    # loads with a curve and the static two-phase one need anything.

    # WyeLoad_2Ph, constant power (ModelType = 0) at 1 pu: the pair of phases of WyeLoad_1Ph, at real currents
    # (IEEE13 never instantiates this class, which is why it was left out of batch 9).
    P2, Q2 = (0.17e6, 0.23e6), (0.125e6, 0.132e6)
    V2 = [1.0 * cis(-2pi / 3), 1.0 * cis(2pi / 3)]
    @named w2 = WyeLoad_2Ph(; ModelType = 0, P_a = P2[1], Q_a = Q2[1], P_b = P2[2], Q_b = Q2[2],
        VA = 1.0, AngA = -2pi / 3, VB = 1.0, AngB = 2pi / 3)
    i2p, W2 = feed(w2, (:A, :B), V2)
    for (k, pin) in enumerate((:A, :B))
        S = (P2[k] + im * Q2[k]) / S_p
        @test cur(i2p, W2, pin) ≈ conj(S) / conj(V2[k]) atol = 1e-9
    end
    @test i2p[W2.Pa] ≈ P2[1] / S_p atol = 1e-12
    @test i2p[W2.Qb] ≈ Q2[2] / S_p atol = 1e-12
    # the three ZIP factors at 0.9 pu: A_pa keeps the power, B_pa scales it by Va, C_pa by Va^2
    for (kw, factor) in (((; A_pa = 100), 1.0), ((; B_pa = 100), 0.9), ((; C_pa = 100), 0.81))
        @named w2z = WyeLoad_2Ph(; ModelType = 1, P_a = P2[1], Q_a = Q2[1], P_b = P2[2], Q_b = Q2[2], kw...)
        i2z, W2z = feed(w2z, (:A, :B), [0.9 + 0.0im, 0.9 * cis(-2pi / 3)])
        @test i2z[W2z.Pa] ≈ factor * P2[1] / S_p atol = 1e-12
        @test i2z[W2z.Qa] ≈ factor * Q2[1] / S_p atol = 1e-12
        @test i2z[W2z.Pb] ≈ 0 atol = 1e-12          # phase b has all its percentages at 0
    end

    # DeltaDynLoad_3Ph, constant power (ModelType = 0) with the load curve at 1.2: the branch currents are the
    # real ones, and the pin current is the difference of the two branches that meet at it - the same relation as
    # DeltaLoad_3Ph, because the model's division of both the branch voltage and the pin current by sqrt(3)
    # cancels out. The rig drives `DynFact` with an equation, as the Test drives it with a `Ramp`.
    Vdd = [1.0 * cis(0.0), 0.98 * cis(-2pi / 3), 1.01 * cis(2pi / 3)]
    Pdd, Qdd = (0.255e6, 0.36e6, 0.475e6), (0.158e6, 0.1744e6, 0.1562e6)
    DF = 1.2
    curve(l) = Equation[l.DynFact ~ DF]
    @named dd0 = DeltaDynLoad_3Ph(; ModelType = 0, P_ab = Pdd[1], Q_ab = Qdd[1], P_bc = Pdd[2], Q_bc = Qdd[2],
        P_ca = Pdd[3], Q_ca = Qdd[3])
    idd, DD0 = feed(dd0, (:A, :B, :C), Vdd; extra = curve)
    # `Pca` is the dead branch (see below), so the CA branch carries reactive power only
    Sab = DF * (Pdd[1] + im * Qdd[1]) / S_p
    Sbc = DF * (Pdd[2] + im * Qdd[2]) / S_p
    Sca = DF * (0.0 + im * Qdd[3]) / S_p
    @test cur(idd, DD0, :A) ≈ conj(Sab) / conj(Vdd[1] - Vdd[2]) - conj(Sca) / conj(Vdd[3] - Vdd[1]) atol = 1e-9
    @test cur(idd, DD0, :B) ≈ conj(Sbc) / conj(Vdd[2] - Vdd[3]) - conj(Sab) / conj(Vdd[1] - Vdd[2]) atol = 1e-9
    @test cur(idd, DD0, :C) ≈ conj(Sca) / conj(Vdd[3] - Vdd[1]) - conj(Sbc) / conj(Vdd[2] - Vdd[3]) atol = 1e-9
    @test abs(cur(idd, DD0, :A) + cur(idd, DD0, :B) + cur(idd, DD0, :C)) ≈ 0 atol = 1e-12
    @test idd[DD0.Pab] ≈ DF * Pdd[1] / S_p atol = 1e-12
    @test idd[DD0.Vab] ≈ abs(Vdd[1] - Vdd[2]) / sqrt(3) atol = 1e-9

    # The dead `P_ca` of the .mo (F-97 c), in BOTH ModelTypes: the power vector reads `Pca`, the model's own
    # output, where the parameter `P_ca` was meant, so `Pca = Pca/S_p*DynFact*CoefC` has the single solution
    # `Pca = 0` and 475 kW of declared active power on branch CA never flow. `Qca` is unaffected.
    for MT in (0, 1)
        @named ddz = DeltaDynLoad_3Ph(; ModelType = MT, P_ab = Pdd[1], Q_ab = Qdd[1], P_bc = Pdd[2],
            Q_bc = Qdd[2], P_ca = Pdd[3], Q_ca = Qdd[3], A_ab = 50, B_ab = 30, C_ab = 20, A_ca = 100)
        iz, DDz = feed(ddz, (:A, :B, :C), Vdd; extra = curve)
        @test iz[DDz.Pca] ≈ 0 atol = 1e-12                                   # 475 kW declared, 0 delivered
        @test iz[DDz.Qca] ≈ DF * Qdd[3] / S_p * iz[DDz.Coef_C] atol = 1e-12  # the reactive branch is normal
        @test iz[DDz.Coef_C] ≈ 1.0 atol = 1e-12   # A_ca = 100: the ZIP coefficient of CA is 1 in both branches
        # the CA branch current is purely the reactive one
        @test iz[DDz.Icar] + im * iz[DDz.Icai] ≈
              conj(DF * im * Qdd[3] / S_p) / conj((Vdd[3] - Vdd[1]) / sqrt(3)) atol = 1e-9
    end
end
