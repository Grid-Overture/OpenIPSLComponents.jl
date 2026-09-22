# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Solar.PowerFactory.WECC.PVD1 (PLAN-08, batch 8): GenerationTripping, PQPriority, PVD1_Controller. None has an
# upstream Test of its own; PlantPVD1 is exercised by Tests.Solar.PowerFactory.PVD1 against its oracle.

# GenerationTripping(Lv0 = 0.88, Lv1 = 0.9, Lv2 = 1.1, Lv3 = 1.2, recov = 0.5, Tfilter = 0.01) on
# u = 1 - 0.11 (Step at 1) + 0.11 (Step at 2) - 0.15 (Step at 3) + 0.15 (Step at 4):
#   t = 0.5: u = 1 >= Lv1, umin = Lv1 -> TrpLow = 1, TrpHigh = 1 (u <= Lv2, umax = Lv2).
#   t = 1.5: u = 0.89 in (Lv0, Lv1); umin has followed it (tau = 0.01 s): TrpLow = (umin - Lv0)/(Lv1 - Lv0) = 0.5.
#   t = 2.5: u = 1 again, umin stays 0.89 < Lv1: TrpLow = (0.89 - 0.88 + 0.5 (0.9 - 0.89))/0.02 = 0.75.
#   t = 3.5: u = 0.85 < Lv0: TrpLow = 0; umin only follows while umin > Lv0, so it stops at Lv0 (within a step of
#            the tracker) instead of reaching 0.85.
# The mirror curve: u = 1 + 0.15 (Step at 1) - 0.15 (Step at 2): TrpHigh(1.5) = (Lv3 - umax)/(Lv3 - Lv2) = 0.5 with
# umax = 1.15, TrpHigh(2.5) = (1.2 - 1.15 + 0.5 (1.15 - 1.1))/0.1 = 0.75; TrpLow = 1 throughout.
@testset "Solar.PowerFactory.WECC.PVD1 GenerationTripping" begin
    @named s1 = Step(; height = -0.11, offset = 1, startTime = 1)
    @named s2 = Step(; height = 0.11, startTime = 2)
    @named s3 = Step(; height = -0.15, startTime = 3)
    @named s4 = Step(; height = 0.15, startTime = 4)
    @named gtr = GenerationTripping(; Lv0 = 0.88, Lv1 = 0.9, Lv2 = 1.1, Lv3 = 1.2, recov = 0.5)
    @named rig = System(Equation[gtr.u ~ s1.y + s2.y + s3.y + s4.y], t, [], []; systems = [s1, s2, s3, s4, gtr])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 5.0))
    own = prob.kwargs[:tstops]
    own = own isa AbstractVector ? own : own(prob.p, prob.tspan)
    sol = solve(prob, Rodas5P(); abstol = 1e-9, reltol = 1e-9, tstops = own, initializealg = INIT)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.5; idxs = sys.gtr.TrpLow) ≈ 1.0 atol = 1e-9
    @test sol(0.5; idxs = sys.gtr.TrpHigh) ≈ 1.0 atol = 1e-9
    @test sol(1.5; idxs = sys.gtr.umin) ≈ 0.89 atol = 1e-7
    @test sol(1.5; idxs = sys.gtr.TrpLow) ≈ 0.5 atol = 1e-5
    @test sol(2.5; idxs = sys.gtr.umin) ≈ 0.89 atol = 1e-7
    @test sol(2.5; idxs = sys.gtr.TrpLow) ≈ 0.75 atol = 1e-5
    @test sol(3.5; idxs = sys.gtr.TrpLow) ≈ 0.0 atol = 1e-9
    @test 0.86 < sol(3.5; idxs = sys.gtr.umin) <= 0.88 + 1e-9
    @test sol(4.5; idxs = sys.gtr.TrpHigh) ≈ 1.0 atol = 1e-9
    @test sol(4.5; idxs = sys.gtr.umax) ≈ 1.1 atol = 1e-9

    @named h1 = Step(; height = 0.15, offset = 1, startTime = 1)
    @named h2 = Step(; height = -0.15, startTime = 2)
    @named gtr2 = GenerationTripping(; Lv0 = 0.88, Lv1 = 0.9, Lv2 = 1.1, Lv3 = 1.2, recov = 0.5)
    @named rig2 = System(Equation[gtr2.u ~ h1.y + h2.y], t, [], []; systems = [h1, h2, gtr2])
    sys2 = mtkcompile(rig2)
    prob2 = ODEProblem(sys2, [], (0.0, 3.0))
    own2 = prob2.kwargs[:tstops]
    own2 = own2 isa AbstractVector ? own2 : own2(prob2.p, prob2.tspan)
    sol2 = solve(prob2, Rodas5P(); abstol = 1e-9, reltol = 1e-9, tstops = own2, initializealg = INIT)
    @test sol2.retcode == ReturnCode.Success
    @test sol2(1.5; idxs = sys2.gtr2.umax) ≈ 1.15 atol = 1e-7
    @test sol2(1.5; idxs = sys2.gtr2.TrpHigh) ≈ 0.5 atol = 1e-5
    @test sol2(2.5; idxs = sys2.gtr2.TrpHigh) ≈ 0.75 atol = 1e-5
    @test sol2(2.5; idxs = sys2.gtr2.TrpLow) ≈ 1.0 atol = 1e-9
end

# PQPriority(Imax = 1.1). P priority (PqFlag = true): Ipmax = Imax, Iqmax = Imax^2 - Ipcmd^2 (sic, no root):
#   (Ip, Iq) = (0.6, 0.2) -> (0.6, 0.2), Iqmax_.y = 1.21 - 0.36 = 0.85; (0.6, 1.0) -> (0.6, 0.85);
#   (1.5, 0.2) -> Ipcmd = 1.1, Iqmax = 1.21 - 1.21 = 0 -> Iqcmd = 0.
# Q priority (PqFlag = false): Iqmax = Imax, Ipmax = Imax^2 - Iqcmd^2: (1.5, 0.5) -> Iqcmd = 0.5, Ipcmd = 1.21 - 0.25
#   = 0.96; (-0.3, 0.5) -> Ipcmd = 0 (the lower limit of IpLimiter is `zero`).
@testset "Solar.PowerFactory.WECC.PVD1 PQPriority" begin
    cases = [(true, 0.6, 0.2, 0.6, 0.2), (true, 0.6, 1.0, 0.6, 0.85), (true, 1.5, 0.2, 1.1, 0.0),
             (false, 1.5, 0.5, 0.96, 0.5), (false, -0.3, 0.5, 0.0, 0.5)]
    for (flag, ip, iq, ipc, iqc) in cases
        @named pq = PQPriority(; PqFlag = flag, Imax = 1.1)
        @named rig = System(Equation[pq.Ip ~ ip, pq.Iq ~ iq], t, [], []; systems = [pq])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
        @test integ[sys.pq.Ipcmd] ≈ ipc atol = 1e-9
        @test integ[sys.pq.Iqcmd] ≈ iqc atol = 1e-9
    end
    @named pq1 = PQPriority(; PqFlag = true, Imax = 1.1)
    @named rig1 = System(Equation[pq1.Ip ~ 0.6, pq1.Iq ~ 0.2], t, [], []; systems = [pq1])
    sys1 = mtkcompile(rig1)
    integ1 = init(ODEProblem(sys1, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ1[sys1.pq1.Iqmax_.y] ≈ 0.85 atol = 1e-9
    @test integ1[sys1.pq1.Ipmax_.y] ≈ 1.1 atol = 1e-9
    @test integ1[sys1.pq1.IqLimiter.limit2] ≈ -0.85 atol = 1e-9
end

# PVD1_Controller (the PVD1 Test's data: Pref = 0.6, Qref = 0.2, u_0 = 1, PqFlag = true, defaults otherwise) fed with
# Vt = 1, It = 0.632, freq = 1: the equilibrium Ip = Pref/u_0 = 0.6, Iq = -Qref/u_0 = -0.2 (QCurrentController has
# k = -1, sic), the frequency loop identically 0 (fdbd = -99, Ddn = 0: deadZone.y = frequency_droop.y = 0), the
# tripping product product3 = 1 and both current-controller derivatives 0. With freq = 0.985 < Ft0 = 0.99 from
# t = 0 the frequency tripping is immediate (TrpLow = 0 below Lv0) and Ip decays from 0.6 with Tg = 0.02:
# Ip(0.1) = 0.6 e^{-5} = 0.004042768199451279.
@testset "Solar.PowerFactory.WECC.PVD1 PVD1_Controller" begin
    @named ctl = PVD1_Controller(; PqFlag = true, Qref = 0.2, Pref = 0.6, u_0 = 1.0)
    @named rig = System(Equation[ctl.Vt ~ 1.0, ctl.It ~ 0.632, ctl.freq ~ 1.0], t, [], []; systems = [ctl])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ[sys.ctl.Ip] ≈ 0.6 atol = 1e-9
    @test integ[sys.ctl.Iq] ≈ -0.2 atol = 1e-9
    @test integ[sys.ctl.deadZone.y] ≈ 0.0 atol = 1e-12
    @test integ[sys.ctl.frequency_droop.y] ≈ 0.0 atol = 1e-12
    @test integ[sys.ctl.product3.y] ≈ 1.0 atol = 1e-12
    @test integ[sys.ctl.qppriority.Ipcmd] ≈ 0.6 atol = 1e-9
    @test integ[sys.ctl.qppriority.Iqcmd] ≈ 0.2 atol = 1e-9
    @test abs(initial_derivative(integ, sys, sys.ctl.PCurrentController.y)) < 1e-9
    @test abs(initial_derivative(integ, sys, sys.ctl.QCurrentController.y)) < 1e-9

    @named ctl2 = PVD1_Controller(; PqFlag = true, Qref = 0.2, Pref = 0.6, u_0 = 1.0)
    @named rig2 = System(Equation[ctl2.Vt ~ 1.0, ctl2.It ~ 0.632, ctl2.freq ~ 0.985], t, [], []; systems = [ctl2])
    sys2 = mtkcompile(rig2)
    sol2 = solve(ODEProblem(sys2, [], (0.0, 0.1)), Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sol2.retcode == ReturnCode.Success
    @test sol2(0.05; idxs = sys2.ctl2.frequency_tripping.TrpLow) ≈ 0.0 atol = 1e-12
    @test sol2(0.1; idxs = sys2.ctl2.Ip) ≈ 0.6 * exp(-5) atol = 1e-7
end
