# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Examples.OpenCPS (PLAN-10, phase 3): the resynchronization bench of OpenCPS. None of its nine classes has an
# upstream Test, so everything here is hand-computed; the system's initial point is OpenModelica's row 0 of
# `om_opencps.csv` (DASSL tol 1e-6, `--tearingMethod=noTearing`, F-85).
# Part 1: the breaker, LimitCheck and FREQ_CALC.  Part 2: VOLT_CTRL, ACT_UNIT and RESYNCH_UNIT.
# Part 3: OpenCPS_Network at t = 0.

# `OpenCPS_Breaker` (F-84). Rig: an ideal source at `n` (1 + j0), a second one at 1.05 + j0.02 feeding `p` through
# a lossless-shunt line, and a `BooleanStep` closing the breaker at t = 0.5 s.
#   open   (t < 0.5): p.i = n.i = 0, so the line carries nothing and p.v is the far source's 1.05 + j0.02;
#   closed (t > 0.5): p.v = n.v = 1 + j0 and `p.i = n.i` -- the .mo's `ir = is`, the two pin currents entering the
#                     branch with the same sign (F-84), and not `is = -ir` as `Electrical.Events.Breaker` writes.
#   The line then carries (1.05 + j0.02 - 1)/(0.01 + j0.1) = 0.567326... - j0.474257... pu into `p`.
@testset "Examples.OpenCPS breaker, LimitCheck and FREQ_CALC" begin
    @named brk = OpenCPS_Breaker()
    @named far = FixedVoltageSource(; vr = 1.05, vi = 0.02)
    @named near = FixedVoltageSource(; vr = 1.0, vi = 0.0)
    @named line = PwLine(; R = 0.01, X = 0.1, G = 0, B = 0)
    @named bs = BooleanStep(; startTime = 0.5)
    @variables xb(t) = 0.0
    @named rig = System([connect(far.p, line.p), connect(line.n, brk.p), connect(near.p, brk.n),
            brk.TRIGGER ~ bs.y, D_nounits(xb) ~ 0], t, [xb], []; systems = [brk, far, near, line, bs])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.25; idxs = sys.brk.p.ir) ≈ 0 atol = 1e-9
    @test sol(0.25; idxs = sys.brk.p.ii) ≈ 0 atol = 1e-9
    @test sol(0.25; idxs = sys.brk.n.ir) ≈ 0 atol = 1e-9
    @test sol(0.25; idxs = sys.brk.n.ii) ≈ 0 atol = 1e-9
    @test sol(0.25; idxs = sys.brk.p.vr) ≈ 1.05 atol = 1e-9
    @test sol(0.25; idxs = sys.brk.p.vi) ≈ 0.02 atol = 1e-9
    i = (0.05 + 0.02im) / (0.01 + 0.1im)
    @test sol(0.75; idxs = sys.brk.p.vr) ≈ 1.0 atol = 1e-9
    @test sol(0.75; idxs = sys.brk.p.vi) ≈ 0.0 atol = 1e-9
    @test sol(0.75; idxs = sys.brk.p.ir) ≈ real(i) atol = 1e-8
    @test sol(0.75; idxs = sys.brk.p.ii) ≈ imag(i) atol = 1e-8
    @test sol(0.75; idxs = sys.brk.n.ir) ≈ sol(0.75; idxs = sys.brk.p.ir) atol = 1e-9   # ir = is (F-84)
    @test sol(0.75; idxs = sys.brk.n.ii) ≈ sol(0.75; idxs = sys.brk.p.ii) atol = 1e-9

    # LimitCheck(upperLim = 1, lowerLim = -1, dt = 1) on u = 3 - t over [0, 6]: the band [-1, 1] is entered at
    # t = 2 and left at t = 4, so START is 1 over (3, 4) and 0 elsewhere.
    @named lc = LimitCheck(; upperLim = 1, lowerLim = -1, dt = 1)
    @variables xl(t) = 0.0
    @named rigl = System([lc.u ~ 3 - t, D_nounits(xl) ~ lc.START], t, [xl], []; systems = [lc])
    sysl = mtkcompile(rigl)
    soll = solve(ODEProblem(sysl, [], (0.0, 6.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test soll.retcode == ReturnCode.Success
    @test soll(1.0; idxs = sysl.lc.START) ≈ 0 atol = 1e-12
    @test soll(2.5; idxs = sysl.lc.START) ≈ 0 atol = 1e-12   # in band, but not yet for dt = 1 s
    @test soll(3.5; idxs = sysl.lc.START) ≈ 1 atol = 1e-12
    @test soll(5.0; idxs = sysl.lc.START) ≈ 0 atol = 1e-12   # out of the band again
    @test soll(6.0; idxs = sysl.xl) ≈ 1.0 atol = 1e-4        # START is 1 for exactly one second

    # FREQ_CALC(T_w = 0.05, T_f = 0.01, fi_0 = 0.2) on the ramp ANGLE = 0.2 + 2 t: the washed-out derivative
    # settles at 2 rad/s (both states are `:NoInit` in the .mo, so the rig gives them their own u0).
    @named fc = FREQ_CALC(; T_w = 0.05, T_f = 0.01, fi_0 = 0.2)
    @variables xf(t) = 0.0
    @named rigf = System([fc.ANGLE ~ 0.2 + 2t, D_nounits(xf) ~ 0], t, [xf], []; systems = [fc])
    sysf = mtkcompile(rigf)
    solf = solve(ODEProblem(sysf, [sysf.fc.derivative.x => 0.0, sysf.fc.firstOrder.y => 0.0], (0.0, 2.0)),
        Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test solf.retcode == ReturnCode.Success
    @test solf(0.0; idxs = sysf.fc.d_FREQ) ≈ 0 atol = 1e-9
    @test solf(2.0; idxs = sysf.fc.d_FREQ) ≈ 2 atol = 1e-6
end

# Part 2: the three control blocks that carry the logic.
@testset "Examples.OpenCPS VOLT_CTRL, ACT_UNIT and RESYNCH_UNIT" begin
    # VOLT_CTRL is inert before t = 2 s (the switch passes const1.y = 0 and the integrator does not move) and is a
    # PI with kp = 1, ki = 2 afterwards: on the constant error u1 - u2 = 0.1, y = 0.1 + 2*0.1*(t - 2).
    @named vc = VOLT_CTRL()
    @named rigv = System([vc.u1 ~ 1.1, vc.u2 ~ 1.0], t, [], []; systems = [vc])
    sysv = mtkcompile(rigv)
    solv = solve(ODEProblem(sysv, [], (0.0, 4.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test solv.retcode == ReturnCode.Success
    @test solv(1.0; idxs = sysv.vc.y) ≈ 0 atol = 1e-9
    @test solv(1.9; idxs = sysv.vc.y) ≈ 0 atol = 1e-9
    @test solv(3.0; idxs = sysv.vc.y) ≈ 0.1 + 2 * 0.1 * 1.0 atol = 1e-6
    @test solv(4.0; idxs = sysv.vc.y) ≈ 0.1 + 2 * 0.1 * 2.0 atol = 1e-6

    # ACT_UNIT with the three inputs inside their bands from t = 0: the three `LimitCheck` (dt = 5 s) raise their
    # flags at t = 5 and the RS flip-flop latches TRIGGER, which stays 1 when FI_DIFF leaves its band at t = 6.
    # The `Pre` of each `LimitCheck` lets the timers start at the first step rather than exactly at t = 0, so the
    # instants are read a fifth of a second either side of 5 s.
    @named au = ACT_UNIT()
    @named riga = System([au.VOLT_DIFF ~ 0.0, au.SPEED ~ 0.0, au.FI_DIFF ~ ifelse(t < 6, 0.0, 5.0)], t, [], [];
        systems = [au])
    sysa = mtkcompile(riga)
    sola = solve(ODEProblem(sysa, [], (0.0, 8.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sola.retcode == ReturnCode.Success
    @test sola(4.8; idxs = sysa.au.TRIGGER) ≈ 0 atol = 1e-12
    @test sola(5.2; idxs = sysa.au.TRIGGER) ≈ 1 atol = 1e-12
    @test sola(5.2; idxs = sysa.au.START_FREQ) ≈ 1 atol = 1e-12
    @test sola(5.2; idxs = sysa.au.START_FI) ≈ 1 atol = 1e-12
    @test sola(8.0; idxs = sysa.au.TRIGGER) ≈ 1 atol = 1e-12   # the flip-flop never resets (R is false)

    # RESYNCH_UNIT at rest: both voltages and both angles equal, SPEED = 0, PMECH0 = 0.5. The voltage control is
    # still off (t < 2), the angle and frequency gates are `xor`s of two false signals, so P_CTRL = PMECH0 and
    # V_CTRL = 0. `fREQ_CALC`'s two states are free in the .mo and get their u0 here.
    @named ru = RESYNCH_UNIT()
    @named rigr = System([ru.SPEED ~ 0.0, ru.PMECH0 ~ 0.5, ru.V_IB ~ 1.0, ru.V_DN ~ 1.0, ru.fi_IB ~ 0.0,
            ru.fi_DN ~ 0.0], t, [], []; systems = [ru])
    sysr = mtkcompile(rigr)
    solr = solve(ODEProblem(sysr, [sysr.ru.freq_ctrl.fREQ_CALC.derivative.x => 0.0,
            sysr.ru.freq_ctrl.fREQ_CALC.firstOrder.y => 0.0], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test solr.retcode == ReturnCode.Success
    @test solr(1.0; idxs = sysr.ru.P_CTRL) ≈ 0.5 atol = 1e-9
    @test solr(1.0; idxs = sysr.ru.V_CTRL) ≈ 0 atol = 1e-9
    @test solr(1.0; idxs = sysr.ru.TRIGGER) ≈ 0 atol = 1e-12
end

# Part 3: the system at t = 0 against OpenModelica's row 0. The breaker is open, so the island B4-T2-B5-G2 sits
# 0.0107 pu below the infinite-bus side, and the resynchronization unit is at rest (V_CTRL = 0, P_CTRL = PMECH0).
const OM_OPENCPS_T0 = (; BG1 = 1.000009116188779, B1 = 0.9937346025436312, B2 = 0.9939629828145736,
    B3 = 1.000003993042314, B4 = 0.9893407510437301, B5 = 0.9999999816509774,
    delta1 = 0.731817255746378, delta2 = 0.1475557468177803,
    EFD1 = 1.36389314040084, EFD2 = 1.358805520239806,
    PMECH1 = 0.4, PMECH2 = 0.1001022)

@testset "Examples.OpenCPS.Network" begin
    @named sys0 = OpenCPS_Network()
    sys = mtkcompile(sys0)
    integ = init(ODEProblem(sys, [], (0.0, 10.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    for b in (:BG1, :B1, :B2, :B3, :B4, :B5)
        @test integ[getproperty(sys, b).v] ≈ getproperty(OM_OPENCPS_T0, b) atol = 1e-6
    end
    @test integ[sys.V_IB] ≈ OM_OPENCPS_T0.B3 atol = 1e-6
    @test integ[sys.V_DN] ≈ OM_OPENCPS_T0.B4 atol = 1e-6
    @test integ[sys.G1.gen.delta] ≈ OM_OPENCPS_T0.delta1 atol = 1e-6
    @test integ[sys.G2.gen.delta] ≈ OM_OPENCPS_T0.delta2 atol = 1e-6
    @test integ[sys.G1.gen.w] ≈ 0 atol = 1e-9
    @test integ[sys.G2.gen.w] ≈ 0 atol = 1e-9
    @test integ[sys.G1.sEXS.EFD] ≈ OM_OPENCPS_T0.EFD1 atol = 1e-6
    @test integ[sys.G2.sEXS.EFD] ≈ OM_OPENCPS_T0.EFD2 atol = 1e-6
    @test integ[sys.G1.hYGOV.PMECH] ≈ OM_OPENCPS_T0.PMECH1 atol = 1e-6
    @test integ[sys.G2.iEESGO.PMECH] ≈ OM_OPENCPS_T0.PMECH2 atol = 1e-6
    # the breaker is open and the unit at rest
    @test integ[sys.breaker1.TRIGGER] ≈ 0 atol = 1e-12
    @test integ[sys.breaker1.p.ir] ≈ 0 atol = 1e-12
    @test integ[sys.breaker1.p.ii] ≈ 0 atol = 1e-12
    @test integ[sys.G2.central_Unit.V_CTRL] ≈ 0 atol = 1e-9
    @test integ[sys.G2.central_Unit.P_CTRL] ≈ OM_OPENCPS_T0.PMECH2 atol = 1e-6
end
