# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PSSE loads (PLAN-02): baseLoad (PSSE), Load, Load_variation on a fixed voltage. Rigs carry a dummy state x' = 1.
# With the defaults a = 1, b = j the PSS/E conversion makes P constant-current and Q constant-admittance:
#   S_P = ((1 - 1 - 0) P_0, (1 - 0 - 1) Q_0)/S_b = 0, S_I = (P_0/v_0, 0)/S_b, S_Y = (0, Q_0/v_0^2)/S_b, so at
#   v = 1.05 (angle 0.1), P_0 = 50e6, Q_0 = 10e6, S_b = 1e8, v_0 = 1: P = 0.5*1.05, Q = 0.1*1.05^2 (kP = kI = 1 at
#   v > PQBRAK); ir = (P vr + Q vi)/v^2, ii = (P vi - Q vr)/v^2.
# characteristic = 2 with a = 0.4 + 0.3j, b = 0.2 + 0.5j at v = 0.6: kP = a0 + a1 cos(0.6 wp) + b1 sin(0.6 wp)
#   (v < PQBRAK), kI = 1 (v >= 0.5); P = kI S_I.re v + S_Y.re v^2 + kP S_P.re with S_P = (0.4 P_0, 0.2 Q_0)/S_b,
#   S_I = (0.4 P_0, 0.3 Q_0)/S_b, S_Y = (0.2 P_0, 0.5 Q_0)/S_b (v_0 = 1); Q likewise with the imaginary parts.
# characteristic = 1 at v = 0.6 (PQBRAK/2 < v < PQBRAK), same a, b: kP = 1 - 2((0.6 - 0.7)/0.7)^2, kI = 1.
# Load_variation(d_P = 0.1, t1 = 0.3, d_t = 0.3), defaults a, b, v = 1: PF = p0/q0 = 5, d_Q = (0.5 + 0.1)/5 - 0.1 = 0.02;
#   P = 0.5 outside the window and 0.6 inside, Q = 0.1 and 0.12. With d_t = 0 there is no window (P = 0.5 always).
@testset "PSSE loads" begin
    @variables x(t) = 0.0
    vr, vi = 1.05 * cos(0.1), 1.05 * sin(0.1)
    @named src = FixedVoltageSource(; vr, vi)
    @named ld = Load(; S_b = 1e8, P_0 = 50e6, Q_0 = 10e6)
    @named rig = System(Equation[connect(src.p, ld.p), D_nounits(x) ~ 1], t, [x], []; systems = [src, ld])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    P, Q = 0.5 * 1.05, 0.1 * 1.05^2
    @test integ[sys.ld.P] ≈ P atol = 1e-9
    @test integ[sys.ld.Q] ≈ Q atol = 1e-9
    @test integ[sys.ld.kP] ≈ 1 atol = 1e-9
    @test integ[sys.ld.p.ir] ≈ (P * vr + Q * vi) / 1.05^2 atol = 1e-9
    @test integ[sys.ld.p.ii] ≈ (P * vi - Q * vr) / 1.05^2 atol = 1e-9
    @test integ[sys.ld.v] ≈ 1.05 atol = 1e-9
    @test integ[sys.ld.angle] ≈ 0.1 atol = 1e-9

    a, b = complex(0.4, 0.3), complex(0.2, 0.5)
    S_P, S_I, S_Y = complex(0.4 * 0.5, 0.2 * 0.1), complex(0.4 * 0.5, 0.3 * 0.1), complex(0.2 * 0.5, 0.5 * 0.1)
    a2, b2, a0, a1, b1, wp = 1.502, 1.769, 0.4881, -0.4999, 0.1389, 3.964
    @named src6 = FixedVoltageSource(; vr = 0.6, vi = 0.0)
    @named ld2 = Load(; S_b = 1e8, P_0 = 50e6, Q_0 = 10e6, a, b, characteristic = 2)
    @named ld1 = Load(; S_b = 1e8, P_0 = 50e6, Q_0 = 10e6, a, b, characteristic = 1)
    @named rig2 = System(Equation[connect(src6.p, ld2.p), connect(src6.p, ld1.p), D_nounits(x) ~ 1], t, [x], [];
        systems = [src6, ld2, ld1])
    sys2 = mtkcompile(rig2)
    integ2 = init(ODEProblem(sys2, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    kP2 = a0 + a1 * cos(0.6 * wp) + b1 * sin(0.6 * wp)
    @test integ2[sys2.ld2.kP] ≈ kP2 atol = 1e-9
    @test integ2[sys2.ld2.kI] ≈ 1 atol = 1e-9
    @test integ2[sys2.ld2.P] ≈ real(S_I) * 0.6 + real(S_Y) * 0.36 + kP2 * real(S_P) atol = 1e-9
    @test integ2[sys2.ld2.Q] ≈ imag(S_I) * 0.6 + imag(S_Y) * 0.36 + kP2 * imag(S_P) atol = 1e-9
    kP1 = 1 - 2 * ((0.6 - 0.7) / 0.7)^2
    @test integ2[sys2.ld1.kP] ≈ kP1 atol = 1e-9
    @test integ2[sys2.ld1.P] ≈ real(S_I) * 0.6 + real(S_Y) * 0.36 + kP1 * real(S_P) atol = 1e-9

    @named src1 = FixedVoltageSource(; vr = 1.0, vi = 0.0)
    @named lv = Load_variation(; S_b = 1e8, P_0 = 50e6, Q_0 = 10e6, d_P = 0.1, t1 = 0.3, d_t = 0.3)
    @named rig3 = System(Equation[connect(src1.p, lv.p), D_nounits(x) ~ 1], t, [x], []; systems = [src1, lv])
    sys3 = mtkcompile(rig3)
    sol3 = solve(ODEProblem(sys3, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
    @test sol3.retcode == ReturnCode.Success
    @test sol3(0.2; idxs = sys3.lv.P) ≈ 0.5 atol = 1e-9
    @test sol3(0.45; idxs = sys3.lv.P) ≈ 0.6 atol = 1e-9
    @test sol3(0.45; idxs = sys3.lv.Q) ≈ 0.12 atol = 1e-9
    @test sol3(0.8; idxs = sys3.lv.P) ≈ 0.5 atol = 1e-9
    @test sol3(0.8; idxs = sys3.lv.Q) ≈ 0.1 atol = 1e-9

    @named lv0 = Load_variation(; S_b = 1e8, P_0 = 50e6, Q_0 = 10e6, d_P = 0.1, t1 = 0.3, d_t = 0)
    @named rig4 = System(Equation[connect(src1.p, lv0.p), D_nounits(x) ~ 1], t, [x], []; systems = [src1, lv0])
    sys4 = mtkcompile(rig4)
    sol4 = solve(ODEProblem(sys4, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
    @test sol4(0.45; idxs = sys4.lv0.P) ≈ 0.5 atol = 1e-9
end
