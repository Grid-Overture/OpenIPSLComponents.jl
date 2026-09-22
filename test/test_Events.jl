# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PwFaultPQ and Breaker (PLAN-02). Rigs carry a dummy state x' = 1 so that the integrator has something to step.
# PwFaultPQ(R = 0.1, X = 0.5, t1 = 0.3, t2 = 0.6) on a fixed voltage (1, 0): outside the window the currents are 0;
#   inside, p.ii = (R*0 - X*1)/(X^2 + R^2) = -0.5/0.26, p.ir = (0 - R*p.ii)/X = 0.1*0.5/0.26/0.5 = 0.1/0.26,
#   P = 1*p.ir = 0.1/0.26, Q = -1*p.ii = 0.5/0.26.
# Breaker (time control, t_o = 0.5, rc_enabled, t_rc = 0.7) between a fixed voltage (1, 0) and Shunt(G = 0.1, B = 0.5):
#   closed: shunt current 0.1 + 0.5j, breaker.r.ir = -0.1, breaker.s.ir = 0.1, shunt voltage 1; open (0.5 <= t < 0.7):
#   every current 0 and the shunt voltage 0; closed again at 0.9.
# Breaker (trigger control) with Trigger = 1 from t = 0.4 (a tstop): closed at 0.3, open at 0.6.
@testset "Events" begin
    @variables x(t) = 0.0
    @named src = FixedVoltageSource(; vr = 1.0, vi = 0.0)
    @named f = PwFaultPQ(; R = 0.1, X = 0.5, t1 = 0.3, t2 = 0.6)
    @named rig = System(Equation[connect(src.p, f.p), D_nounits(x) ~ 1], t, [x], []; systems = [src, f])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.2; idxs = sys.f.p.ir) ≈ 0 atol = 1e-9
    @test sol(0.45; idxs = sys.f.p.ii) ≈ -0.5 / 0.26 atol = 1e-8
    @test sol(0.45; idxs = sys.f.p.ir) ≈ 0.1 / 0.26 atol = 1e-8
    @test sol(0.45; idxs = sys.f.P) ≈ 0.1 / 0.26 atol = 1e-8
    @test sol(0.45; idxs = sys.f.Q) ≈ 0.5 / 0.26 atol = 1e-8
    @test sol(0.8; idxs = sys.f.P) ≈ 0 atol = 1e-9

    @named br = Breaker(; t_o = 0.5, rc_enabled = true, t_rc = 0.7)
    @named sh = Shunt(; G = 0.1, B = 0.5)
    @named rig2 = System(Equation[connect(src.p, br.s), connect(br.r, sh.p), D_nounits(x) ~ 1], t, [x], [];
        systems = [src, br, sh])
    sys2 = mtkcompile(rig2)
    sol2 = solve(ODEProblem(sys2, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol2.retcode == ReturnCode.Success
    @test sol2(0.3; idxs = sys2.sh.p.ir) ≈ 0.1 atol = 1e-9
    @test sol2(0.3; idxs = sys2.br.s.ir) ≈ 0.1 atol = 1e-9
    @test sol2(0.3; idxs = sys2.br.r.ii) ≈ -0.5 atol = 1e-9
    @test sol2(0.6; idxs = sys2.sh.p.ir) ≈ 0 atol = 1e-9
    @test sol2(0.6; idxs = sys2.br.s.ii) ≈ 0 atol = 1e-9
    @test sol2(0.6; idxs = sys2.sh.v) ≈ 0 atol = 1e-9
    @test sol2(0.9; idxs = sys2.sh.p.ii) ≈ 0.5 atol = 1e-9
    @test sol2(0.9; idxs = sys2.sh.v) ≈ 1 atol = 1e-9

    @named brt = Breaker(; enableTrigger = true)
    @named rig3 = System(Equation[connect(src.p, brt.s), connect(brt.r, sh.p), brt.Trigger ~ ifelse(t >= 0.4, 1, 0),
            D_nounits(x) ~ 1], t, [x], []; systems = [src, brt, sh], tstops = [0.4])
    sys3 = mtkcompile(rig3)
    sol3 = solve(ODEProblem(sys3, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol3.retcode == ReturnCode.Success
    @test sol3(0.3; idxs = sys3.sh.p.ir) ≈ 0.1 atol = 1e-9
    @test sol3(0.6; idxs = sys3.sh.p.ir) ≈ 0 atol = 1e-9
    @test sol3(0.6; idxs = sys3.brt.Open) ≈ 1 atol = 1e-9
end
