# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# ThreePhase buses (PLAN-09 steps 1.2 and 1.3). `Tests.ThreePhase.IEEE13` is the only Test that instantiates
# Bus_1Ph and Bus_2Ph and it runs at ~1e-9 pu (F-79), so the three buses are exercised here at real voltages.
# Each bus is a node: with its pins held at a fixed voltage it reports magnitude and angle in closed form and draws
# no current. The start values are guesses only: Bus_3Ph is run again with IEEE4's radian angles (-30, -150, 90)
# and lands on the same point.
@testset "ThreePhase buses" begin
    # Bus_1Ph at 0.95 angle 0.1
    @named s1 = FixedVoltageSource(; vr = 0.95 * cos(0.1), vi = 0.95 * sin(0.1))
    @named B1 = Bus_1Ph()
    @named rig1 = System(Equation[connect(s1.p, B1.p1)], t, [], []; systems = [s1, B1])
    sys1 = mtkcompile(rig1)
    i1 = init(ODEProblem(sys1, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-8, reltol = 1e-8)
    @test i1[sys1.B1.V1] ≈ 0.95 atol = 1e-9
    @test i1[sys1.B1.angle1] ≈ 0.1 atol = 1e-9
    @test i1[sys1.B1.p1.ir] ≈ 0 atol = 1e-9
    @test i1[sys1.B1.p1.ii] ≈ 0 atol = 1e-9

    # Bus_2Ph: phase 1 at 1.02 angle 0, phase 2 at 0.98 angle -2pi/3
    @named s21 = FixedVoltageSource(; vr = 1.02, vi = 0.0)
    @named s22 = FixedVoltageSource(; vr = 0.98 * cos(-2pi / 3), vi = 0.98 * sin(-2pi / 3))
    @named B2 = Bus_2Ph()
    @named rig2 = System(Equation[connect(s21.p, B2.p1), connect(s22.p, B2.p2)], t, [], []; systems = [s21, s22, B2])
    sys2 = mtkcompile(rig2)
    i2 = init(ODEProblem(sys2, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-8, reltol = 1e-8)
    @test i2[sys2.B2.V1] ≈ 1.02 atol = 1e-9
    @test i2[sys2.B2.angle1] ≈ 0.0 atol = 1e-9
    @test i2[sys2.B2.V2] ≈ 0.98 atol = 1e-9
    @test i2[sys2.B2.angle2] ≈ -2pi / 3 atol = 1e-9
    @test i2[sys2.B2.p2.ir] ≈ 0 atol = 1e-9

    # Bus_3Ph, unbalanced, twice: with the default start values and with IEEE4's -30/-150/90 radians (F-79)
    VA, VB, VC = 1.0625, 1.05, 1.0687
    aA, aB, aC = 0.0, -2pi / 3, 2pi / 3
    function bus3(; kwargs...)
        @named t1 = FixedVoltageSource(; vr = VA * cos(aA), vi = VA * sin(aA))
        @named t2 = FixedVoltageSource(; vr = VB * cos(aB), vi = VB * sin(aB))
        @named t3 = FixedVoltageSource(; vr = VC * cos(aC), vi = VC * sin(aC))
        @named B = Bus_3Ph(; kwargs...)
        @named rig = System(Equation[connect(t1.p, B.p1), connect(t2.p, B.p2), connect(t3.p, B.p3)], t, [], [];
            systems = [t1, t2, t3, B])
        sys = mtkcompile(rig)
        sys, init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-8, reltol = 1e-8)
    end
    for kw in ((;), (; angle_A = -30, angle_B = -150, angle_C = 90))
        sys3, i3 = bus3(; kw...)
        @test i3[sys3.B.Va] ≈ VA atol = 1e-9
        @test i3[sys3.B.Vb] ≈ VB atol = 1e-9
        @test i3[sys3.B.Vc] ≈ VC atol = 1e-9
        @test i3[sys3.B.angle_a] ≈ aA atol = 1e-9
        @test i3[sys3.B.angle_b] ≈ aB atol = 1e-9
        @test i3[sys3.B.angle_c] ≈ aC atol = 1e-9
        @test i3[sys3.B.p1.ir] ≈ 0 atol = 1e-9
        @test i3[sys3.B.p3.ii] ≈ 0 atol = 1e-9
    end

    # ThreePhase_InfiniteBus: the three pin voltages are imposed and P/Q are reported in W/var over S_p = S_b/3.
    # Injecting i = 0.5 - 0.2j into phase a at 1 angle 0: Pa = -(1*0.5 + 0*(-0.2))*S_p, Qa = -(1*(-0.2) - 0)*S_p.
    S_p = 100e6 / 3
    @named ia = CurrentInjection(; ir = 0.5, ii = -0.2)     # IB.p1.ir = 0.5, IB.p1.ii = -0.2
    @named ib_ = CurrentInjection(; ir = 0.1, ii = 0.0)
    @named ic = CurrentInjection(; ir = 0.0, ii = 0.0)
    @named IB = ThreePhase_InfiniteBus(; V_A = 1.0, angle_A = 0.0, V_B = 1.0, V_C = 1.0)
    @named rig4 = System(Equation[connect(ia.p, IB.p1), connect(ib_.p, IB.p2), connect(ic.p, IB.p3)], t, [], [];
        systems = [ia, ib_, ic, IB])
    sys4 = mtkcompile(rig4)
    i4 = init(ODEProblem(sys4, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-8, reltol = 1e-8)
    @test i4[sys4.IB.p1.vr] ≈ 1.0 atol = 1e-9
    @test i4[sys4.IB.p2.vr] ≈ cos(-2pi / 3) atol = 1e-9
    @test i4[sys4.IB.p3.vi] ≈ sin(2pi / 3) atol = 1e-9
    @test i4[sys4.IB.Pa] ≈ -0.5 * S_p atol = 1e-3
    @test i4[sys4.IB.Qa] ≈ 0.2 * S_p atol = 1e-3
    # phase b at 1 angle -2pi/3 with i = 0.1 + 0j: Pb = -(cos*0.1)*S_p, Qb = -(-sin(-2pi/3)*0.1)*S_p
    @test i4[sys4.IB.Pb] ≈ -cos(-2pi / 3) * 0.1 * S_p atol = 1e-3
    @test i4[sys4.IB.Qb] ≈ sin(-2pi / 3) * 0.1 * S_p atol = 1e-3
    @test i4[sys4.IB.Pc] ≈ 0 atol = 1e-6
    @test i4[sys4.IB.P] ≈ i4[sys4.IB.Pa] + i4[sys4.IB.Pb] + i4[sys4.IB.Pc] atol = 1e-6
    @test i4[sys4.IB.Q] ≈ i4[sys4.IB.Qa] + i4[sys4.IB.Qb] + i4[sys4.IB.Qc] atol = 1e-6
end
