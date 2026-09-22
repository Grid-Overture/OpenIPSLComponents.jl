# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# The ten BaseClasses.GGOV1 partial models (PLAN-05 phase 4). None has an OpenIPSL Test of its own: the Tests of
# GGOV1 and GGOV1DU exercise them assembled, and these hand tests check each one in isolation.
#
# The four selectors are one equation each, with the branch decided by an Integer/Real parameter (F-22, point 1).
@testset "GGOV1 selectors" begin
    @named f1 = Flag(; Flag = 1)
    @named f0 = Flag(; Flag = 0)
    @named d1 = Dm_select(; Dm = 0.0)          # Dm >= 0: y = speed + 1
    @named d2 = Dm_select(; Dm = -2.0)         # Dm < 0: y = (speed + 1)^Dm
    @named r1 = R_select(; Rselect = 1)
    @named r2 = R_select(; Rselect = -1)
    @named r3 = R_select(; Rselect = -2)
    @named r0 = R_select(; Rselect = 0)
    @named ms = Min_select(; nu = 3, frs0 = 0.0)
    sel = [r1, r2, r3, r0]
    eqs = Equation[f1.speed ~ 0.25, f0.speed ~ 0.25, d1.speed ~ 0.25, d2.speed ~ 0.25,
        ms.u[1] ~ 0.9, ms.u[2] ~ 0.4, ms.u[3] ~ 0.6]
    for r in sel
        append!(eqs, Equation[r.Pelect ~ 0.7, r.ValveStroke ~ 0.3, r.GovernorOutput ~ -0.2])
    end
    @named rig = System(eqs, t, [], []; systems = [f1, f0, d1, d2, ms, sel...])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ[sys.f1.y] ≈ 1.25 atol = 1e-12
    @test integ[sys.f0.y] ≈ 1.0 atol = 1e-12
    @test integ[sys.d1.y] ≈ 1.25 atol = 1e-12
    @test integ[sys.d2.y] ≈ 1.25^(-2) atol = 1e-12
    @test integ[sys.r1.y] ≈ 0.7 atol = 1e-12
    @test integ[sys.r2.y] ≈ 0.3 atol = 1e-12
    @test integ[sys.r3.y] ≈ -0.2 atol = 1e-12
    @test integ[sys.r0.y] ≈ 0.0 atol = 1e-12
    @test integ[sys.ms.yMin] ≈ 0.4 atol = 1e-12
end

# AccelerationLimiter, LoadLimiter, LoadLimiterDU and the two PID governors at the operating point GGOV1 gives them:
# PELEC = 0.4, Dm = 0, Kturb = 1.5, Wfnl = 0.2, so fsr0 = (0.4 + 0)/1.5 + 0.2 = 0.4666666666666667.
#   AccelerationLimiter: SPEED = 0 makes s8 (a Derivative with InitialOutput y_start = 0) output 0, so
#     FSRA = Ka*DELT*(ASET - 0) + FSR = 10*0.005*0.1 + fsr0 = 0.005 + fsr0.
#   LoadLimiter: s6 starts at fsr0; with LDREF = 1, tlim.y = Wfnl + LDREF/Kturb = 0.8666666666666667, so the PI is
#     at rest only when TEXM has that value, and then FSRT = min(1, fsr0) = fsr0. (Inside GGOV1 TEXM is fsr0
#     instead, the PI ramps up and the load limiter is simply not the binding branch of min_select.)
#   PIDGovernor: with Rselect = 1, s0.y = Pe0 = 0.4, r.y = R*0.4; the speed error is zero when
#     P_REF = R*Pe0 = 0.016, which is exactly the `Pref` GGOV1 computes, and then FSRN = s20 = fsr0.
@testset "GGOV1 limiters and governors at rest" begin
    Pe, fsr0 = 0.4, 0.4 / 1.5 + 0.2
    @named acc = AccelerationLimiter(; Ka = 10, Ta = 0.1, DELT = 0.005)
    @named ll = LoadLimiter(; Kturb = 1.5, Kpload = 2, Kiload = 0.67, Dm = 0, Wfnl = 0.2)
    @named lldu = LoadLimiterDU(; Kturb = 1.5, Kpload = 2, Kiload = 0.67, Dm = 0, Wfnl = 0.2, Vmax = 1, Vmin = 0.15)
    @named pid = PIDGovernor(; Rselect = 1, R = 0.04, T_pelec = 1, Kpgov = 10, Kigov = 2, Kturb = 1.5, Wfnl = 0.2)
    @named piddu = PIDGovernorDU(; Rselect = 1, R = 0.04, T_pelec = 1, Kpgov = 10, Kigov = 2, Kturb = 1.5, Wfnl = 0.2)
    texm = 0.2 + 1 / 1.5
    eqs = Equation[
        acc.SPEED ~ 0, acc.ASET ~ 0.1, acc.FSR ~ fsr0,
        ll.PELEC ~ Pe, ll.LDREF ~ 1, ll.TEXM ~ texm,
        lldu.PELEC ~ Pe, lldu.LDREF ~ 1, lldu.TEXM ~ texm,
        pid.PELEC ~ Pe, pid.PMW_SET ~ Pe, pid.P_REF ~ 0.04 * Pe, pid.SPEED ~ 0, pid.VSTROKE ~ fsr0,
        pid.GOVOUT1 ~ fsr0,
        piddu.PELEC ~ Pe, piddu.PMW_SET ~ Pe, piddu.P_REF ~ 0.04 * Pe, piddu.SPEED ~ 0, piddu.VSTROKE ~ fsr0,
        piddu.GOVOUT1 ~ fsr0,
    ]
    @named rig = System(eqs, t, [], []; systems = [acc, ll, lldu, pid, piddu])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ[sys.acc.FSRA] ≈ 0.005 + fsr0 atol = 1e-9
    @test integ[sys.ll.FSRT] ≈ fsr0 atol = 1e-9
    @test integ[sys.lldu.FSRT] ≈ fsr0 atol = 1e-9
    @test integ[sys.pid.FSRN] ≈ fsr0 atol = 1e-9
    @test integ[sys.piddu.FSRN] ≈ fsr0 atol = 1e-9
    for v in unknowns(sys)
        @test abs(initial_derivative(integ, sys, v)) < 1e-9
    end
end

# Turbine at the same operating point: SPEED = 0, PELEC = 0.4, FSR = fsr0, and `Flag = 0` as the Tests of GGOV1 and
# GGOV1DU set it. `flag10.y` is then 1 (with Flag = 1 it would be `Dw2w.y + 1 = 2`, since the .mo feeds the selector
# the already-offset speed `1 + SPEED`, and the `fsr0 = (Pmech0 + Dm)/Kturb + Wfnl` of the .mo would not be the
# operating point). Then VSTROKE = s30 = fsr0,
# add8.y = FSR - VSTROKE = 0 (the actuator integrator is at rest), product.y = 1*fsr0, add4.y = fsr0 - Wfnl,
# gain1.y = Kturb*(fsr0 - Wfnl) = 0.4 = Pmech0, the delay passes it and s4 (y_start = s40 = Pmech0) is already
# there, so PMECH = Pmech0 = PELEC and TEXM = s50 = fsr0. Once with Teng = 0 (the delay is y = u) and once with
# Teng = 0.2 through the Padé fallback, which must leave the same operating point (F-51).
#
# The *temperature* path is not at rest, in OpenIPSL as written: `product1.u2` is `dm_select.y`, which with SPEED = 0
# is (1 + SPEED) + 1 = 2 (the .mo feeds the selector the already-offset speed), so `s9.u = 2*fsr0` while the .mo sets
# `s90 = fsr0`. `s9` therefore starts with `TF.x[1] = -1.4` and TEXM drifts upwards from fsr0. OpenModelica does
# exactly the same (`gGOV1.gGOV1_Turb.s9.TF.x[1] = -1.400074` at t = 0 in the Test CSV, TEXM 0.4667 -> 0.8005 at
# 10 s), and it is harmless because the load limiter is never the binding branch of `min_select`. The derivative
# check therefore covers everything but that one state.
@testset "GGOV1 Turbine at rest" begin
    Pe, fsr0 = 0.4, 0.4 / 1.5 + 0.2
    for (label, kw) in (("Teng = 0", (; Teng = 0.0)), ("Teng = 0.2 (pade)", (; Teng = 0.2, pade = 4)))
        @named turb = GGOV1_Turbine(; Tact = 0.5, Kturb = 1.5, Tb = 0.1, Tc = 0, Tfload = 3, Dm = 0, Vmax = 1, Vmin = 0.15,
            Tsa = 4, Tsb = 5, DELT = 0.005, Flag = 0, Wfnl = 0.2, kw...)
        @named rig = System(Equation[turb.SPEED ~ 0, turb.PELEC ~ Pe, turb.FSR ~ fsr0], t, [], []; systems = [turb])
        sys = mtkcompile(rig)
        @test !ModelingToolkit.is_dde(sys)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
        @test integ[sys.turb.PMECH] ≈ Pe atol = 1e-9
        @test integ[sys.turb.VSTROKE] ≈ fsr0 atol = 1e-9
        @test integ[sys.turb.TEXM] ≈ fsr0 atol = 1e-9
        @test integ[sys.turb.s9.TF.x[1]] ≈ -1.4 atol = 1e-9      # not at rest, as in OpenModelica
        for v in unknowns(sys)
            occursin("s9₊TF₊x", string(v)) && continue   # the temperature path, see above
            @test abs(initial_derivative(integ, sys, v)) < 1e-9
        end
    end
end
