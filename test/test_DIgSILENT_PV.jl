# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Solar.PowerFactory.DIgSILENT (PLAN-08, batch 8): PVModule, PVArray, DCBusBar, the three Auxiliary blocks,
# CurrentLimiter, DIgSILENT_Controller. None has an upstream Test of its own; PV_Plant is exercised by
# Tests.Solar.PowerFactory.DIgSILENT_PV against its oracle (231 variables).

# PVModule with the STC data of the .mo (U0 43.8, Umpp 35, Impp 4.58, Isc 5) at theta_STC (tempCorr = 1).
# (a) use_input_E = true, E = 1000: by construction of c2 = log(1 - Impp/Isc)/(Umpp - U0) the curve passes through
#     (Umpp_stc, Impp_stc): U = 35 -> I = 4.58; U = U0 = 43.8 -> I = 0; U = 20 -> I = 5 (1 - e^{c2 (20 - 43.8)}) =
#     4.993839237922533 with c2 = 0.28147028183395734; E = 0.5 (<= 1): Isc = U0 = Umpp = 0 -> I = 0, no NaN.
# (b) use_input_E = false, P_init = 300000/(140 20) = 107.142857 W (the DIgSILENT_PV Test's module): the irradiance
#     that closes Impp(E) Umpp(E) = P_init is E0 = 704.1455638474104 W/m2 (bisection on the same expressions),
#     Umpp(E0) = 35 ln(E0)/ln(1000) = 33.22272855477973 (= the oracle's pv_array.module.Umpp), Impp(E0) =
#     3.2249866824211395; at U = Umpp(E0) the module gives I = Impp(E0).
# PVArray(P_init = 300000, 20 x 140, Tr = 0.01) at Uarray = 20 Umpp(E0) = 664.4545710955946 (the oracle's Vmpp_array):
#     Iarray = 140 Impp(E0) = 451.4981355389596, Vmpp_array = 664.4545710955946 (the oracle's row 0).
@testset "Solar.PowerFactory.DIgSILENT PVModule + PVArray" begin
    for (U, Iexp) in ((35.0, 4.58), (43.8, 0.0), (20.0, 4.993839237922533))
        @named pv = PVModule(; use_input_E = true)
        @named rig = System(Equation[pv.E ~ 1000, pv.U ~ U], t, [], []; systems = [pv])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
        @test integ[sys.pv.I] ≈ Iexp atol = 1e-9
        @test integ[sys.pv.Umpp] ≈ 35.0 atol = 1e-9
        @test integ[sys.pv.tempCorrU] ≈ 1.0 atol = 1e-12
    end
    @named pvd = PVModule(; use_input_E = true)
    @named rigd = System(Equation[pvd.E ~ 0.5, pvd.U ~ 20], t, [], []; systems = [pvd])
    sysd = mtkcompile(rigd)
    integd = init(ODEProblem(sysd, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integd[sysd.pvd.I] ≈ 0.0 atol = 1e-12
    @test integd[sysd.pvd.Umpp] ≈ 0.0 atol = 1e-12
    @test !isnan(integd[sysd.pvd.c2])

    E0 = 704.1455638474104
    @named pvp = PVModule(; P_init = 300000 / (140 * 20))
    @named rigp = System(Equation[pvp.U ~ 35 * log(E0) / log(1000)], t, [], []; systems = [pvp])
    sysp = mtkcompile(rigp)
    integp = init(ODEProblem(sysp, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integp[sysp.pvp.local_E] ≈ E0 atol = 1e-6
    @test integp[sysp.pvp.Umpp] ≈ 33.22272855477973 atol = 1e-8
    @test integp[sysp.pvp.Impp] ≈ 3.2249866824211395 atol = 1e-8
    @test integp[sysp.pvp.I] ≈ 3.2249866824211395 atol = 1e-8
    @test integp[sysp.pvp.P] ≈ 300000 / 2800 atol = 1e-8

    @named arr = PVArray(; P_init = 300000.0, n_series = 20, n_parallel = 140, Tr = 0.01)
    @named riga = System(Equation[arr.Uarray ~ 664.4545710955946], t, [], []; systems = [arr])
    sysa = mtkcompile(riga)
    intega = init(ODEProblem(sysa, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test intega[sysa.arr.Iarray] ≈ 451.4981355389596 atol = 1e-6
    @test intega[sysa.arr.Vmpp_array] ≈ 664.4545710955946 atol = 1e-6
    @test intega[sysa.arr.module_.U] ≈ 33.22272855477973 atol = 1e-8
end

# DCBusBar(C = 1.5e-3) with I_pv = 451.4981355389596 A and P_conv = 300000 W: the SteadyState integrator solves
# I_pv - P_conv/Udc = 0 -> Udc = 664.4545710955946 V. The .mo's guess is eps = 1e-15, from which Newton needs ~50
# doublings: the parent hands a better guess to `integrator.y` (600 V here; Udc0 in PV_Plant), which is also the
# mechanism the plant relies on. der(Udc) = 0 at t = 0 and Udc stays put over 1 s.
# SLDWindV(Deadband = 0.1, K_FRT = 2): diq = K_FRT (|duac| - Deadband) duac/max(|duac|, Deadband):
#   duac = 0.2 -> 0.2; -0.2 -> -0.2; 0.05 (inside the deadband) -> 2 (0.05 - 0.1) 0.05/0.1 = -0.05 (sic, non-zero);
#   -0.05 -> +0.05 (the oracle's diq after the -5 % voltage step).
@testset "Solar.PowerFactory.DIgSILENT DCBusBar + SLDWindV" begin
    @named bb = DCBusBar(; C = 1.5e-3)
    @named rig = System(Equation[bb.I_pv ~ 451.4981355389596, bb.P_conv ~ 300000], t, [], []; systems = [bb],
        guesses = Dict(bb.integrator.y => 600.0))
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 1.0))
    integ = init(prob, Rodas5P(); initializealg = INIT)
    @test integ[sys.bb.Udc] ≈ 664.4545710955946 atol = 1e-6
    @test abs(initial_derivative(integ, sys, sys.bb.integrator.y)) < 1e-6
    sol = solve(prob, Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
    @test sol(1.0; idxs = sys.bb.Udc) ≈ 664.4545710955946 atol = 1e-5

    for (d, diq) in ((0.2, 0.2), (-0.2, -0.2), (0.05, -0.05), (-0.05, 0.05))
        @named sw = SLDWindV(; Deadband = 0.1, K_FRT = 2)
        @named rigs = System(Equation[sw.duac ~ d], t, [], []; systems = [sw])
        syss = mtkcompile(rigs)
        integs = init(ODEProblem(syss, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
        @test integs[syss.sw.diq] ≈ diq atol = 1e-9
    end
end

# ReactivePowerSupport(iq_max = 1, iq_min = -1, Deadband = 0.1, K_FRT = 2, i0 = 0) with duac: 0 -> -0.05 (Step at
# 0.5). `greaterEqualThreshold(threshold = 0)` on |deadZone(duac)| = 0 is always true, so picdro.trip = 1 from
# 1e-8 s on (the oracle). i_EEG = false selects the SLDWindV branch (switch1; sic, the selector names are crossed):
# iq(1) = i0 + diq(-0.05) = 0.05, the oracle's iq_ref after the voltage step; i_EEG = true selects gain(deadZone),
# 0 inside the deadband: iq(1) = 0. Both give iq = 0 before the step.
# ActivePowerController(K = 0.005, T = 0.03, yo_min = 0, yo_max = 1, id0 = 0.6): yi = 0, pred = 1 -> I.y = x = 0.6,
# yo1 = 0.6, yo = yo1 = 0.6, tracker.y = 0.6 (its input is 0); pred = 0.5 -> tracker.u = feedback = yo1 - tracker.y
# = 0, product = 0.6 0.5 = 0.3 = yo2 -> yo = min(yo1, yo2) = 0.3. With yi = 0.1 constant (pred = 1): x = 0.6 +
# (K/T) 0.1 t, P.y = 0.0005, yo(1) = 0.6 + 0.0005 + 0.1/6 = 0.6171666666666666.
@testset "Solar.PowerFactory.DIgSILENT ReactivePowerSupport + ActivePowerController" begin
    for (flag, iq1) in ((false, 0.05), (true, 0.0))
        @named st = Step(; height = -0.05, offset = 0, startTime = 0.5)
        @named rps = ReactivePowerSupport(; iq_max = 1, iq_min = -1, i_EEG = flag, Deadband = 0.1, K_FRT = 2, i0 = 0)
        @variables x(t) = 0.0   # a rig with no continuous state cannot carry Picdro's continuous events
        @named rig = System(Equation[rps.duac ~ st.y, D_nounits(x) ~ rps.iq], t, [x], []; systems = [st, rps])
        sys = mtkcompile(rig)
        prob = ODEProblem(sys, [], (0.0, 1.0))
        own = prob.kwargs[:tstops]
        own = own isa AbstractVector ? own : own(prob.p, prob.tspan)
        sol = solve(prob, Rodas5P(); abstol = 1e-9, reltol = 1e-9, tstops = own, initializealg = INIT)
        @test sol.retcode == ReturnCode.Success
        @test sol(0.001; idxs = sys.rps.picdro.trip) ≈ 1 atol = 1e-12
        @test sol(0.3; idxs = sys.rps.iq) ≈ 0.0 atol = 1e-9
        @test sol(1.0; idxs = sys.rps.iq) ≈ iq1 atol = 1e-9
    end

    @named apc = ActivePowerController(; K = 0.005, T = 0.03, yo_min = 0, yo_max = 1, id0 = 0.6)
    @named rig1 = System(Equation[apc.yi ~ 0, apc.pred ~ 1], t, [], []; systems = [apc])
    sys1 = mtkcompile(rig1)
    integ1 = init(ODEProblem(sys1, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ1[sys1.apc.x] ≈ 0.6 atol = 1e-9
    @test integ1[sys1.apc.yo1] ≈ 0.6 atol = 1e-9
    @test integ1[sys1.apc.yo] ≈ 0.6 atol = 1e-9
    @test integ1[sys1.apc.tracker.y] ≈ 0.6 atol = 1e-9
    @test abs(initial_derivative(integ1, sys1, sys1.apc.tracker.y)) < 1e-12
    @named apc2 = ActivePowerController(; K = 0.005, T = 0.03, yo_min = 0, yo_max = 1, id0 = 0.6)
    @named rig2 = System(Equation[apc2.yi ~ 0, apc2.pred ~ 0.5], t, [], []; systems = [apc2])
    sys2 = mtkcompile(rig2)
    integ2 = init(ODEProblem(sys2, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ2[sys2.apc2.yo2] ≈ 0.3 atol = 1e-9
    @test integ2[sys2.apc2.yo] ≈ 0.3 atol = 1e-9
    @named apc3 = ActivePowerController(; K = 0.005, T = 0.03, yo_min = 0, yo_max = 1, id0 = 0.6)
    @named rig3 = System(Equation[apc3.yi ~ 0.1, apc3.pred ~ 1], t, [], []; systems = [apc3])
    sys3 = mtkcompile(rig3)
    sol3 = solve(ODEProblem(sys3, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sol3(1.0; idxs = sys3.apc3.yo) ≈ 0.6171666666666666 atol = 1e-8
end

# CurrentLimiter(maxAbsCur = 1, maxIq = 1, Deadband = 0.1, i_EEG = false). Normal mode (duac = 0, trip = 0):
# idout = clamp(idin, +-1) -> idin = 1.3 gives 1; iqout = clamp(iqin, +-min(maxIq, sqrt(maxAbsCur^2 - iqin^2)))
# (sic, the limit is computed from iqin itself): iqin = 0.6 -> limit 0.8 -> 0.6; iqin = 0.9 -> limit sqrt(0.19) =
# 0.4358898943540674 -> 0.4358898943540674. FRT mode (duac = -0.3 from 0.5 s: |deadZone| = 0.2 >= Deadband, trip
# from 1e-8 after the step): idout = clamp(idin, |duac| - 1, 1 - |duac|) = 0.7 for idin = 0.9, iqout = clamp(iqin,
# +-1) = 0.9 for iqin = 0.9.
# DIgSILENT_Controller at its equilibrium (the DIgSILENT_PV Test's point: id0 = 0.6, iq0 = 0, uac0 = 1, defaults):
# vdcref = vdcin = 664.4545710955946, uac = 1, pred = 1 -> id_ref = 0.6, iq_ref = 0 (trip = 1 after 1e-8, diq(0) =
# 0), the three lags at rest (derivatives 0).
@testset "Solar.PowerFactory.DIgSILENT CurrentLimiter + Controller" begin
    for (idin, iqin, ido, iqo) in ((1.3, 0.6, 1.0, 0.6), (0.9, 0.9, 0.9, 0.4358898943540674))
        @named cl = CurrentLimiter(; maxAbsCur = 1, maxIq = 1, Deadband = 0.1, i_EEG = false)
        @variables x(t) = 0.0
        @named rig = System(Equation[cl.idin ~ idin, cl.iqin ~ iqin, cl.duac ~ 0, D_nounits(x) ~ cl.idout], t, [x], []; systems = [cl])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
        @test integ[sys.cl.idout] ≈ ido atol = 1e-9
        @test integ[sys.cl.iqout] ≈ iqo atol = 1e-9
        @test integ[sys.cl.picdro.trip] ≈ 0 atol = 1e-12
    end
    @named st = Step(; height = -0.3, offset = 0, startTime = 0.5)
    @named clf = CurrentLimiter(; maxAbsCur = 1, maxIq = 1, Deadband = 0.1, i_EEG = false)
    @variables xf(t) = 0.0
    @named rigf = System(Equation[clf.idin ~ 0.9, clf.iqin ~ 0.9, clf.duac ~ st.y, D_nounits(xf) ~ clf.idout], t, [xf], []; systems = [st, clf])
    sysf = mtkcompile(rigf)
    probf = ODEProblem(sysf, [], (0.0, 1.0))
    ownf = probf.kwargs[:tstops]
    ownf = ownf isa AbstractVector ? ownf : ownf(probf.p, probf.tspan)
    solf = solve(probf, Rodas5P(); abstol = 1e-9, reltol = 1e-9, tstops = ownf, initializealg = INIT)
    @test solf.retcode == ReturnCode.Success
    @test solf(0.3; idxs = sysf.clf.idout) ≈ 0.9 atol = 1e-9
    @test solf(0.3; idxs = sysf.clf.iqout) ≈ 0.4358898943540674 atol = 1e-9
    @test solf(1.0; idxs = sysf.clf.picdro.trip) ≈ 1 atol = 1e-12
    @test solf(1.0; idxs = sysf.clf.idout) ≈ 0.7 atol = 1e-9
    @test solf(1.0; idxs = sysf.clf.iqout) ≈ 0.9 atol = 1e-9

    @named ctl = DIgSILENT_Controller(; id0 = 0.6, iq0 = 0.0, uac0 = 1.0)
    @named rigc = System(Equation[ctl.vdcref ~ 664.4545710955946, ctl.vdcin ~ 664.4545710955946, ctl.uac ~ 1.0, ctl.pred ~ 1.0],
        t, [], []; systems = [ctl])
    sysc = mtkcompile(rigc)
    probc = ODEProblem(sysc, [], (0.0, 1.0))
    integc = init(probc, Rodas5P(); initializealg = INIT)
    @test integc[sysc.ctl.id_ref] ≈ 0.6 atol = 1e-9
    @test integc[sysc.ctl.iq_ref] ≈ 0.0 atol = 1e-9
    @test abs(initial_derivative(integc, sysc, sysc.ctl.MPP_delay.y)) < 1e-9
    @test abs(initial_derivative(integc, sysc, sysc.ctl.filter.y)) < 1e-9
    @test abs(initial_derivative(integc, sysc, sysc.ctl.voltage_measurement_delay.y)) < 1e-9
    solc = solve(probc, Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
    @test solc.retcode == ReturnCode.Success
    @test solc(1.0; idxs = sysc.ctl.id_ref) ≈ 0.6 atol = 1e-8
    @test solc(1.0; idxs = sysc.ctl.iq_ref) ≈ 0.0 atol = 1e-8
    @test solc(1.0; idxs = sysc.ctl.reactivePowerSupport.picdro.trip) ≈ 1 atol = 1e-12
end
