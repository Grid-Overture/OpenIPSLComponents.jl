# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Solar.PowerFactory.General (PLAN-08, batch 8): ElmGenstat, ElmVac, StaVmea, Picdro. None has an upstream Test of
# its own; they are exercised by the two PowerFactory Tests (DIgSILENT_PV, PVD1) against their oracles, and here
# on the closed arithmetic.

# ElmGenstat on an ElmVac at 1 pu / 0 rad (v = 1, f0 = 1 constant), M_b = 0.5e6 on S_b = 100e6 (M_b/S_b = 0.005),
# id_ref = 0.6, iq_ref = -0.2 (the PVD1 Test's point): sinu = 0, cosu = 1,
#   p.ir = -0.005*(0.6*1 - (-0.2)*0) = -0.003,  p.ii = -0.005*(0.6*0 + (-0.2)*1) = 0.001,
#   P = -(vr ir + vi ii) = 0.003,  Q = -(vi ir - vr ii) = 0.001 (both in S_b),  i = sqrt(0.003^2 + 0.001^2)*200 =
#   0.6324555320336759 (in M_b), v = 1, angle_v = 0, angle_i = atan2(0.001, -0.003) = 2.819842099193151.
# The ElmVac then absorbs P = -0.003, Q = -0.001 (its own sign convention).
@testset "Solar.PowerFactory.General ElmGenstat + ElmVac" begin
    @named vs = ElmVac(; angle_0 = 0, v_0 = 1, S_b = 100e6, fn = 50)
    @named gen = ElmGenstat(; M_b = 0.5e6, angle_0 = 0, v_0 = 1, S_b = 100e6, fn = 50)
    @named rig = System(Equation[connect(gen.p, vs.p), vs.v ~ 1, vs.f0 ~ 1, gen.id_ref ~ 0.6, gen.iq_ref ~ -0.2],
        t, [], []; systems = [vs, gen])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ[sys.gen.p.ir] ≈ -0.003 atol = 1e-12
    @test integ[sys.gen.p.ii] ≈ 0.001 atol = 1e-12
    @test integ[sys.gen.P] ≈ 0.003 atol = 1e-12
    @test integ[sys.gen.Q] ≈ 0.001 atol = 1e-12
    @test integ[sys.gen.i] ≈ 0.6324555320336759 atol = 1e-9
    @test integ[sys.gen.v] ≈ 1.0 atol = 1e-12
    @test integ[sys.gen.angle_v] ≈ 0.0 atol = 1e-12
    @test integ[sys.gen.angle_i] ≈ 2.819842099193151 atol = 1e-9
    @test integ[sys.gen.sinu] ≈ 0.0 atol = 1e-12
    @test integ[sys.gen.cosu] ≈ 1.0 atol = 1e-12
    @test integ[sys.vs.P] ≈ -0.003 atol = 1e-12
    @test integ[sys.vs.Q] ≈ -0.001 atol = 1e-12
    @test integ[sys.vs.phiu] ≈ 0.0 atol = 1e-12
end

# ElmVac with the two Steps of the PVD1 Test (v: 1 -> 0.95 at 0.5 s; f0: 1 -> 0.95 at 1 s) and no load (a StaVmea
# only): der(phiu) = 2 pi fn (f0 - fn/50) = 2 pi 50 (-0.05) = -5 pi rad/s from 1 s -> phiu(2) = -5 pi =
# -15.707963267948966, phiu(1.5) = -2.5 pi -> p.vr(1.5) = 0.95 cos(-2.5 pi) = 0, p.vi(1.5) = 0.95 sin(-2.5 pi) = -0.95;
# u = |v| = 0.95 from 0.5 s. StaVmea: df = f0 - 1 after the frequency step, filtered by Tfe = 0.06 into
# fe = 1 - 0.05 (1 - e^{-(t-1)/0.06}): fe(1.05) = 0.9717299190439563, fe(2) = 0.95 (to 3e-8); fe = 1 before 1 s;
# local_df_internal(0) = 0 (what OpenModelica fixes); cosphi(0) = 1, sinphi(0) = 0.
@testset "Solar.PowerFactory.General ElmVac + StaVmea with the PVD1 steps" begin
    @named voltage = Step(; height = -0.05, offset = 1, startTime = 0.5)
    @named frequency = Step(; height = -0.05, offset = 1, startTime = 1)
    @named vs = ElmVac(; angle_0 = 0, v_0 = 1, S_b = 100e6, fn = 50)
    @named sta = StaVmea(; fn = 50, angle_0 = 0)
    @named rig = System(Equation[connect(sta.p, vs.p), voltage.y ~ vs.v, frequency.y ~ vs.f0], t, [], [];
        systems = [voltage, frequency, vs, sta])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 2.0))
    own = prob.kwargs[:tstops]
    own = own isa AbstractVector ? own : own(prob.p, prob.tspan)
    integ = init(prob, Rodas5P(); initializealg = INIT)
    @test integ[sys.sta.local_df_internal] ≈ 0.0 atol = 1e-12
    @test integ[sys.sta.cosphi] ≈ 1.0 atol = 1e-12
    @test integ[sys.sta.sinphi] ≈ 0.0 atol = 1e-12
    sol = solve(prob, Rodas5P(); abstol = 1e-9, reltol = 1e-9, tstops = own, initializealg = INIT)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.9; idxs = sys.sta.fe) ≈ 1.0 atol = 1e-9
    @test sol(0.6; idxs = sys.sta.u) ≈ 0.95 atol = 1e-9
    @test sol(1.5; idxs = sys.sta.df) ≈ -0.05 atol = 1e-7
    @test sol(1.05; idxs = sys.sta.fe) ≈ 0.9717299190439563 atol = 1e-6
    @test sol(2.0; idxs = sys.sta.fe) ≈ 0.95 atol = 1e-6
    @test sol(2.0; idxs = sys.vs.phiu) ≈ -15.707963267948966 atol = 1e-6
    @test sol(1.5; idxs = sys.vs.p.vr) ≈ 0.0 atol = 1e-6
    @test sol(1.5; idxs = sys.vs.p.vi) ≈ -0.95 atol = 1e-6
end

# Picdro (Tpick = 0, Tdrop = 0.5 as its two DIgSILENT users), Boolean signals as 0/1. (a) condition = 1 on (1, 3)
# from a smooth crossing: trip arms 1e-8 s after the rising edge (0 at 0.9, 1 at 1.001 and 3.4) and disarms 0.5 s
# after the falling edge (1 at 3.499, 0 at 3.501); its integral over [0, 5] is 2.5. (b) Tdrop = 0: disarms at
# 3 + 1e-8 (0 at 3.001). (c) the edges produced inside another event (F-41): condition = Step(1) - Step(3), same
# instants, integral 2.5. (d) condition = 1 from t = 0 (the ReactivePowerSupport chain: GreaterEqualThreshold(0)
# on |deadZone(u)| = 0, an identically-zero root function): trip = 0 at t = 0 and 1 from 1e-8 on; integral over
# [0, 10] = 10 to 1e-6.
@testset "Solar.PowerFactory.General Picdro" begin
    @named gt = GreaterThreshold(; threshold = 0)
    @named pic = Picdro(; Tpick = 0, Tdrop = 0.5)
    @variables x(t) = 0.0
    @named rig = System(Equation[gt.u ~ -cos(pi * t / 2), pic.condition ~ gt.y, D_nounits(x) ~ pic.trip], t, [x], [];
        systems = [gt, pic])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 5.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    for (tk, v) in ((0.9, 0), (1.001, 1), (2.0, 1), (3.4, 1), (3.499, 1), (3.501, 0), (4.0, 0))
        @test sol(tk; idxs = sys.pic.trip) ≈ v atol = 1e-12
    end
    @test sol(5.0; idxs = sys.x) ≈ 2.5 atol = 1e-6

    @named pic0 = Picdro(; Tpick = 0, Tdrop = 0)
    @named rig0 = System(Equation[gt.u ~ -cos(pi * t / 2), pic0.condition ~ gt.y, D_nounits(x) ~ pic0.trip], t, [x], [];
        systems = [gt, pic0])
    sys0 = mtkcompile(rig0)
    sol0 = solve(ODEProblem(sys0, [], (0.0, 5.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol0.retcode == ReturnCode.Success
    @test sol0(2.999; idxs = sys0.pic0.trip) ≈ 1 atol = 1e-12
    @test sol0(3.001; idxs = sys0.pic0.trip) ≈ 0 atol = 1e-12
    @test sol0(5.0; idxs = sys0.x) ≈ 2.0 atol = 1e-6

    @named st1 = Step(; height = 1, offset = 0, startTime = 1)
    @named st3 = Step(; height = 1, offset = 0, startTime = 3)
    @named picb = Picdro(; Tpick = 0, Tdrop = 0.5)
    @named rigb = System(Equation[picb.condition ~ st1.y - st3.y, D_nounits(x) ~ picb.trip], t, [x], []; systems = [st1, st3, picb])
    sysb = mtkcompile(rigb)
    probb = ODEProblem(sysb, [], (0.0, 5.0))
    ownb = probb.kwargs[:tstops]
    ownb = ownb isa AbstractVector ? ownb : ownb(probb.p, probb.tspan)
    solb = solve(probb, Rodas5P(); abstol = 1e-9, reltol = 1e-9, tstops = ownb)
    @test solb.retcode == ReturnCode.Success
    for (tk, v) in ((0.9, 0), (1.001, 1), (2.0, 1), (3.4, 1), (3.499, 1), (3.501, 0), (4.0, 0))
        @test solb(tk; idxs = sysb.picb.trip) ≈ v atol = 1e-12
    end
    @test solb(5.0; idxs = sysb.x) ≈ 2.5 atol = 1e-6

    @named ge = GreaterEqualThreshold(; threshold = 0)
    @named absb = Abs()
    @named dz = DeadZone(; uMax = 0.1, uMin = -0.1)
    @named picd = Picdro(; Tpick = 0, Tdrop = 0.5)
    @named st = Step(; height = -0.05, offset = 0, startTime = 0.5)
    @named rigd = System(Equation[dz.u ~ st.y, absb.u ~ dz.y, ge.u ~ absb.y, picd.condition ~ ge.y, D_nounits(x) ~ picd.trip],
        t, [x], []; systems = [ge, absb, dz, picd, st])
    sysd = mtkcompile(rigd)
    probd = ODEProblem(sysd, [], (0.0, 10.0))
    ownd = probd.kwargs[:tstops]
    ownd = ownd isa AbstractVector ? ownd : ownd(probd.p, probd.tspan)
    sold = solve(probd, Rodas5P(); abstol = 1e-9, reltol = 1e-9, tstops = ownd)
    @test sold.retcode == ReturnCode.Success
    @test sold(0.0; idxs = sysd.picd.trip) ≈ 0 atol = 1e-12
    @test sold(0.001; idxs = sysd.picd.trip) ≈ 1 atol = 1e-12
    @test sold(10.0; idxs = sysd.picd.trip) ≈ 1 atol = 1e-12
    @test sold(10.0; idxs = sysd.x) ≈ 10.0 atol = 1e-6
end
