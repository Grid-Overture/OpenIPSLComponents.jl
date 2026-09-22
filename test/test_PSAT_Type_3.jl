# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Electrical.Wind.PSAT.PSAT_Type_3 (PLAN-08, batch 8): WindBlk, MechaBlk, PitchControl, ElecBlk, ElecDynBlk, PSAT_WT.
# Tests.Wind.PSAT.WT_Test has no OpenModelica oracle (F-69: its data, `Pnom = 10` VA on 100 MVA, make the
# initialization singular), so the family is validated by hand: the blocks on the closed arithmetic of the
# **model's defaults** (Pnom = 1e7: omega_m0 = 0.58, Rs = 0.1, Xs = 1, Rr = 0.1, Xr = 0.8, Xm = 30, Hm = 0.3, x1 = 31,
# x2 = 30.8, iqr_min = -0.10333, idr_min = -0.10678, idr_max = 0.03789, iqr_max = 0) and PSAT_WT on the Test's network.

# WindBlk with the Test's data (vw_base = 15, ngb = 1/89, l = 75, wbase = 2 pi 50/2, Sbase = 1e8) at omega_m = 1,
# theta_p = 0: vw = 0.537631527453836 pu -> lambda = 16.41402710687871, lambdai = 38.57503632015179, cp =
# -0.31708235341046676, Pw = Tm = -0.0180002496233362 (a negative power at the Test's low wind, sic); vw = 25/15 (the
# peak of the Mexican hat) -> cp = 0.41303552404270955, Pw = 0.6985313858518634.
@testset "Wind.PSAT.PSAT_Type_3 WindBlk" begin
    for (vw, lam, lami, cp, pw) in ((0.537631527453836, 16.41402710687871, 38.57503632015179, -0.31708235341046676, -0.0180002496233362),
                                    (25 / 15, 5.294819079083921, 6.499251755992964, 0.41303552404270955, 0.6985313858518634))
        @named wb = WindBlk(; vw_base = 15, ngb = 1 / 89, l = 75, wbase = 2 * pi * 50 / 2, Sbase = 1e8)
        @named rig = System(Equation[wb.vw ~ vw, wb.theta_p ~ 0, wb.omega_m ~ 1], t, [], []; systems = [wb])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
        @test integ[sys.wb.lambda] ≈ lam atol = 1e-9
        @test integ[sys.wb.lambdai] ≈ lami atol = 1e-9
        @test integ[sys.wb.cp] ≈ cp atol = 1e-9
        @test integ[sys.wb.Pw] ≈ pw atol = 1e-9
        @test integ[sys.wb.Tm] ≈ pw atol = 1e-9
    end
end

# MechaBlk(Sbase = 1e8, Pnom = 1e7, Hm = 0.3): the initial `if` on Pc: Pc = 0.016 (0 < Pc < Pnom/Sbase = 0.1) ->
# omega_m(0) = 0.5 0.016 10 + 0.5 = 0.58; Pc = 0.2 (Pc Sbase >= Pnom) -> 1; Pc = 0 -> 0.5. With Tm = 0.1 and Tel =
# 0.1 + 0.06 (Step at 0.5) the second initial equation Tel = Tm holds at t = 0 and der(omega_m) = -0.06/0.6 = -0.1 from
# 0.5 s: omega_m(1.5) = omega_m0 - 0.1.
@testset "Wind.PSAT.PSAT_Type_3 MechaBlk" begin
    for (pc, w0) in ((0.016, 0.58), (0.2, 1.0), (0.0, 0.5))
        @named st = Step(; height = 0.06, offset = 0.1, startTime = 0.5)
        @named mb = MechaBlk(; Sbase = 1e8, Pnom = 1e7, Hm = 0.3, Pc = pc)
        @named rig = System(Equation[mb.Tm ~ 0.1, mb.Tel ~ st.y], t, [], []; systems = [st, mb])
        sys = mtkcompile(rig)
        prob = ODEProblem(sys, [], (0.0, 1.5))
        own = prob.kwargs[:tstops]
        own = own isa AbstractVector ? own : own(prob.p, prob.tspan)
        sol = solve(prob, Rodas5P(); abstol = 1e-9, reltol = 1e-9, tstops = own, initializealg = INIT)
        @test sol.retcode == ReturnCode.Success
        @test sol(0.0; idxs = sys.mb.omega_m) ≈ w0 atol = 1e-12
        @test sol(0.4; idxs = sys.mb.omega_m) ≈ w0 atol = 1e-9
        @test sol(1.5; idxs = sys.mb.omega_m) ≈ w0 - 0.1 atol = 1e-7
    end
end

# PitchControl(Kp = 10, Tp = 3, theta_p_min = 0, theta_p_max = 0.78539816339) on omega_m = 1 + 0.5 sin(pi t/20):
# phi = ceil(0.5 floor(2000 (omega_m - 1)))/1000 is the 0.001 quantizer of the speed error: phi(0) = 0 (so the
# initial equation gives theta_pI(0) = Kp phi = 0), phi(5) = ceil(0.5 floor(707.1))/1000 = 0.354. The state follows
# Kp phi (up to 5) through the 3 s lag and the output saturates at theta_p_max: theta_p(15) = 0.78539816339 with
# theta_pI(15) > 1 (wound up). The speed error comes back under 0.0785 at t = 20 asin(0.157)/pi = 19.0 s: there
# der(theta_pI) turns negative with theta_pI > theta_p_max and the `when` resets it to theta_p_max (F-14), so
# theta_pI(19.5) <= theta_p_max and theta_p(19.5) < theta_p_max (already decaying).
@testset "Wind.PSAT.PSAT_Type_3 PitchControl" begin
    @named pc = PitchControl(; Kp = 10, Tp = 3, theta_p_min = 0, theta_p_max = 0.78539816339)
    @named rig = System(Equation[pc.omega_m ~ 1 + 0.5 * sin(pi * t / 20)], t, [], []; systems = [pc])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 20.0))
    integ = init(prob, Rodas5P(); initializealg = INIT)
    @test integ[sys.pc.theta_pI] ≈ 0.0 atol = 1e-12
    @test integ[sys.pc.theta_p] ≈ 0.0 atol = 1e-12
    sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8, initializealg = INIT)
    @test sol.retcode == ReturnCode.Success
    @test sol(5.0; idxs = sys.pc.phi) ≈ 0.354 atol = 1e-12
    @test sol(15.0; idxs = sys.pc.theta_p) ≈ 0.78539816339 atol = 1e-9
    @test sol(15.0; idxs = sys.pc.theta_pI) > 1.0
    @test sol(19.5; idxs = sys.pc.theta_pI) <= 0.78539816339 + 1e-9
    @test sol(19.5; idxs = sys.pc.theta_p) < 0.78539816339
    @test sol(19.5; idxs = sys.pc.theta_p) > 0.7
end

# ElecBlk with the defaults' operating point (Pnom = 1e7, Vbus0 = 1, angle_0 = -0.00243, Pc = 0.016, Qc = 0.0305):
# the .mo's closed-form point is vds0 = 0.002429997608516206, vqs0 = 0.9999970475514528, iqr0 = -x1 Pnom (2
# omega_m0 - 1)/Vbus0/Xm/Sbase/omega_m0 = -0.028505747126449384, ids0 = 0.03059492952275325, iqs0 =
# 0.02776328723723461, idr0 = -0.06504053971601757, vdr0 = -0.012428871666989503, vqr0 = 0.4587188844923127. With the
# pin at (vqs0, -vds0), idr = idr0, iqr = iqr0, omega_m = 0.58 the block returns those currents and p = 0.01556980687094786,
# q = 0.029609124456361095, Tel = 0.0280082358562025 (the .mo's own formulas do not land exactly on Pc, Qc, sic).
# ElecDynBlk on the same point (Vbus = 1, omega_m = 0.58): idr(0) = idr0, iqr(0) = iqr0, Vref(0) = Vbus0 - (idr0 +
# Vbus0/Xm)/Kv = 1.0031707206382685, iqr_off(0) = 0 and both current states at rest. Then Vbus steps to 1.1 at 0.5 s:
# der(idrI) = Kv (1.1 - Vref) - 1.1/Xm - idr = 0.9967 > 0 winds idrI past idr_max = 0.0378888888888889 (idr saturates
# there, idr(0.9) = idr_max) and back to 1.0 at 1 s: der(idrI) = -0.0317 - 0.0333 - 0.0379 < 0 with idrI > idr_max
# -> the `when` resets idrI to idr_max (inside the Step's event, caught by the discrete callback, F-41), after which
# idrI' = -0.065 - idrI: idrI(1.5) = -0.06504 + (0.03789 + 0.06504) e^{-0.5} = -0.00261 (to 1e-3: the reset is one
# step late).
@testset "Wind.PSAT.PSAT_Type_3 ElecBlk + ElecDynBlk" begin
    kw = (; Sbase = 1e8, Vbus0 = 1, angle_0 = -0.00243, Pc = 0.0160000000000082, Qc = 0.030527374471207, Pnom = 1e7,
        Rs = 0.1, Xs = 1, Rr = 0.1, Xr = 0.8, Xm = 30, Hm = 0.3)
    vds0, vqs0 = 0.002429997608516206, 0.9999970475514528
    iqr0, ids0, iqs0, idr0 = -0.028505747126449384, 0.03059492952275325, 0.02776328723723461, -0.06504053971601757
    @named src = FixedVoltageSource(; vr = vqs0, vi = -vds0)
    @named eb = ElecBlk(; kw...)
    @named rig = System(Equation[connect(src.p, eb.pin), eb.idr ~ idr0, eb.iqr ~ iqr0, eb.omega_m ~ 0.58], t, [], []; systems = [src, eb])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ[sys.eb.ids] ≈ ids0 atol = 1e-9
    @test integ[sys.eb.iqs] ≈ iqs0 atol = 1e-9
    @test integ[sys.eb.vdr] ≈ -0.0148233544256131 atol = 1e-9
    @test integ[sys.eb.vqr] ≈ 0.46418228982850285 atol = 1e-9
    @test integ[sys.eb.p] ≈ 0.01556980687094786 atol = 1e-9
    @test integ[sys.eb.q] ≈ 0.029609124456361095 atol = 1e-9
    @test integ[sys.eb.Tel] ≈ 0.0280082358562025 atol = 1e-9
    @test integ[sys.eb.Vbus] ≈ 1.0 atol = 1e-12
    @test -(integ[sys.eb.pin.vr] * integ[sys.eb.pin.ir] + integ[sys.eb.pin.vi] * integ[sys.eb.pin.ii]) ≈ 0.01556980687094786 atol = 1e-9

    lim = (; iqr_max = 0.0, iqr_min = -0.10333333333333333, idr_min = -0.10677777777777779, idr_max = 0.0378888888888889)
    @named ed = ElecDynBlk(; kw..., lim..., Kv = 10, Te = 0.01)
    @named rig2 = System(Equation[ed.omega_m ~ 0.58, ed.Vbus ~ 1.0], t, [], []; systems = [ed])
    sys2 = mtkcompile(rig2)
    integ2 = init(ODEProblem(sys2, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ2[sys2.ed.idr] ≈ idr0 atol = 1e-9
    @test integ2[sys2.ed.iqr] ≈ iqr0 atol = 1e-9
    @test integ2[sys2.ed.Vref] ≈ 1.0031707206382685 atol = 1e-9
    @test integ2[sys2.ed.iqr_off] ≈ 0.0 atol = 1e-9
    @test abs(initial_derivative(integ2, sys2, sys2.ed.idrI)) < 1e-9
    @test abs(initial_derivative(integ2, sys2, sys2.ed.iqrI)) < 1e-9

    @named up = Step(; height = 0.1, offset = 1, startTime = 0.5)
    @named down = Step(; height = -0.1, startTime = 1)
    @named ed3 = ElecDynBlk(; kw..., lim..., Kv = 10, Te = 0.01)
    @named rig3 = System(Equation[ed3.omega_m ~ 0.58, ed3.Vbus ~ up.y + down.y], t, [], []; systems = [up, down, ed3])
    sys3 = mtkcompile(rig3)
    prob3 = ODEProblem(sys3, [], (0.0, 1.5))
    own3 = prob3.kwargs[:tstops]
    own3 = own3 isa AbstractVector ? own3 : own3(prob3.p, prob3.tspan)
    sol3 = solve(prob3, Rodas5P(); abstol = 1e-9, reltol = 1e-9, tstops = own3, initializealg = INIT)
    @test sol3.retcode == ReturnCode.Success
    @test sol3(0.9; idxs = sys3.ed3.idr) ≈ lim.idr_max atol = 1e-9
    @test sol3(0.9; idxs = sys3.ed3.idrI) > lim.idr_max + 0.1
    @test sol3(1.5; idxs = sys3.ed3.idrI) ≈ idr0 + (lim.idr_max - idr0) * exp(-0.5) atol = 1e-3
    @test sol3(1.5; idxs = sys3.ed3.idrI) < lim.idr_max
end

# PSAT_WT with the model's defaults on the network of Tests.Wind.PSAT.WT_Test (infiniteBus 1 at 0 rad - pwLine(R = 0.01,
# X = 0.1, B = 0.001) - dfig_Turbine.pin), the wind at the speed that balances the defaults' point, vw =
# 0.5375438838292883 pu (Pw = Tel0 omega_m0 = 0.01624477679659859; it is, to 1e-4, the Test's own v0 = 0.5376).
# What the model's initialization enforces on a network is `omega_m = omega_m0`, `Tel = Tm` and -- through the two
# initial equations of ElecDynBlk, which are one and the same when `Vbus = V_0` -- the terminal voltage `Vbus = V_0`;
# `Q_0` only seeds the start values, so on the Test's line (R = 0.01, X = 0.1 from a 1 pu source) the point is
# `Vbus = 1`, `omega_m = 0.58`, `Tel = Tm = 0.028008` with P = 0.01598 (P_0 = 0.016 up to the losses) and whatever Q
# closes the line (-0.0026, not the defaults' 0.0305). The machine sits there for 20 s; with the Test's Mexican hat (typ = 3, vmax = 25/15,
# tstart = 5, tstop = 15, sigma = 1) on top of that speed it rides through the gust and returns to the same point
# at 20 s (5 sigma after the peak) to 5e-3 in P. The literal Test (Pnom = 10) is not simulable in either tool (F-69):
# what ModelingToolkit does with it is recorded outside the suite, not asserted.
@testset "Wind.PSAT.PSAT_Type_3 PSAT_WT on the WT_Test network (model defaults, F-69)" begin
    vw = 0.5375438838292883
    function network(wg)
        @named infiniteBus = InfiniteBus(; angle_0 = 0, v_0 = 1, S_b = 100e6, fn = 50)
        @named pwLine = PwLine(; B = 0.001, G = 0.0, R = 0.01, X = 0.1, S_b = 100e6, fn = 50)
        @named dfig_Turbine = PSAT_WT()
        @named rig = System(Equation[connect(infiniteBus.p, pwLine.p), wg.Vw ~ dfig_Turbine.Wind_Speed,
                connect(pwLine.n, dfig_Turbine.pin)], t, [], []; systems = [infiniteBus, pwLine, dfig_Turbine, wg])
        rig
    end
    @named windGenerator1 = WindGenerator(; v0 = vw, typ = 1)
    sys = mtkcompile(network(windGenerator1))
    prob = ODEProblem(sys, [], (0.0, 20.0))
    integ = init(prob, Rodas5P(); initializealg = INIT)
    @test integ[sys.dfig_Turbine.mechaBlk1.omega_m] ≈ 0.58 atol = 1e-9
    @test integ[sys.dfig_Turbine.Vbus] ≈ 1.0 atol = 1e-9
    @test integ[sys.dfig_Turbine.mechaBlk1.Tel] ≈ 0.0280082358562025 atol = 1e-8
    @test integ[sys.dfig_Turbine.mechaBlk1.Tm] ≈ 0.0280082358562025 atol = 1e-8
    @test integ[sys.dfig_Turbine.P] ≈ 0.016 atol = 1e-3
    @test abs(initial_derivative(integ, sys, sys.dfig_Turbine.mechaBlk1.omega_m)) < 1e-6
    @test abs(initial_derivative(integ, sys, sys.dfig_Turbine.elecDyn.idrI)) < 1e-6
    @test abs(initial_derivative(integ, sys, sys.dfig_Turbine.elecDyn.iqrI)) < 1e-6
    println("  PSAT_WT (defaults) on the WT_Test network: P = ", integ[sys.dfig_Turbine.P], ", Q = ", integ[sys.dfig_Turbine.Q],
        ", idr = ", integ[sys.dfig_Turbine.elecDyn.idr], ", iqr = ", integ[sys.dfig_Turbine.elecDyn.iqr])
    sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8, initializealg = INIT)
    @test sol.retcode == ReturnCode.Success
    @test sol(20.0; idxs = sys.dfig_Turbine.P) ≈ sol(0.0; idxs = sys.dfig_Turbine.P) atol = 1e-6
    @test sol(20.0; idxs = sys.dfig_Turbine.mechaBlk1.omega_m) ≈ 0.58 atol = 1e-6

    @named windGenerator3 = WindGenerator(; v0 = vw, typ = 3, tstop = 15, sigma = 1, vmax = 25 / 15, wmag = -0.2)
    sys3 = mtkcompile(network(windGenerator3))
    prob3 = ODEProblem(sys3, [], (0.0, 20.0))
    sol3 = solve(prob3, Rodas5P(); abstol = 1e-8, reltol = 1e-8, initializealg = INIT)
    @test sol3.retcode == ReturnCode.Success
    @test sol3(10.0; idxs = sys3.dfig_Turbine.Wind_Speed) ≈ 25 / 15 atol = 1e-9
    @test sol3(10.0; idxs = sys3.dfig_Turbine.P) > sol3(0.0; idxs = sys3.dfig_Turbine.P)
    @test sol3(20.0; idxs = sys3.dfig_Turbine.P) ≈ sol3(0.0; idxs = sys3.dfig_Turbine.P) atol = 5e-3
end
