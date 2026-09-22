# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# ThreePhase capacitor banks (PLAN-09 step 3.3). `Tests.ThreePhase.IEEE13` instantiates both but its Q is in vars
# over a 33.3 MVA base (F-79), so the bank currents are ~1e-9 pu, under the 1e-4 floor of the oracle threshold.
# The .mo writes a constant admittance: 0 = vr*ir + vi*ii and Qa = (-vi*ir + vr*ii)/(vr^2 + vi^2), whose solution
# is ir = -Qa*vi, ii = Qa*vr, i.e. I = j*Qa*V. The absorbed reactive power vi*ir - vr*ii is then -Qa*|V|^2: the
# bank injects, it is capacitive.
@testset "ThreePhase capacitor banks" begin
    S_p = 100e6 / 3
    function feed(bank, pins, volts)
        srcs = [FixedVoltageSource(; name = Symbol(:s, i), vr = real(v), vi = imag(v)) for (i, v) in enumerate(volts)]
        eqs = [connect(s.p, getproperty(bank, p)) for (s, p) in zip(srcs, pins)]
        @named rig = System(Equation[eqs...], t, [], []; systems = [srcs; bank])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
        integ, getproperty(sys, nameof(bank))
    end
    cur(integ, b, pin) = integ[getproperty(b, pin).ir] + im * integ[getproperty(b, pin).ii]

    # CapacitorBank_1Ph at a real reactive power: I = j*(Q_a/S_p)*V and the absorbed Q is negative
    Qa = 5e6
    V = 0.97 * cis(0.15)
    @named cb1 = CapacitorBank_1Ph(; Q_a = Qa)
    i1, C1 = feed(cb1, (:A,), [V])
    @test cur(i1, C1, :A) ≈ im * (Qa / S_p) * V atol = 1e-12
    @test i1[C1.Pa] ≈ 0 atol = 1e-15
    @test i1[C1.Qa] ≈ Qa / S_p atol = 1e-15
    absorbed = imag(V) * real(cur(i1, C1, :A)) - real(V) * imag(cur(i1, C1, :A))
    @test absorbed ≈ -(Qa / S_p) * abs2(V) atol = 1e-12

    # CapacitorBank_3Ph, unbalanced, and the IEEE13 number: CapBank675(Q_a = Q_b = Q_c = 0.2 var) at 1.0625 pu
    # gives A.ii = 0.2/(100e6/3)*1.0625 = 6.375e-9, the value of the oracle row 0 (F-79).
    V3 = [1.0625 * cis(0.0), 1.05 * cis(-2pi / 3), 1.0687 * cis(2pi / 3)]
    @named cb3 = CapacitorBank_3Ph(; Q_a = 0.2, Q_b = 0.2, Q_c = 0.2)
    i3, C3 = feed(cb3, (:A, :B, :C), V3)
    @test i3[C3.A.ii] ≈ 6.375e-9 atol = 1e-15
    for (k, pin) in enumerate((:A, :B, :C))
        @test cur(i3, C3, pin) ≈ im * (0.2 / S_p) * V3[k] atol = 1e-15
    end

    @named cb3b = CapacitorBank_3Ph(; Q_a = 3e6, Q_b = 1e6, Q_c = 0.0)
    i3b, C3b = feed(cb3b, (:A, :B, :C), V3)
    @test cur(i3b, C3b, :A) ≈ im * (3e6 / S_p) * V3[1] atol = 1e-12
    @test cur(i3b, C3b, :B) ≈ im * (1e6 / S_p) * V3[2] atol = 1e-12
    @test abs(cur(i3b, C3b, :C)) ≈ 0 atol = 1e-15
end
