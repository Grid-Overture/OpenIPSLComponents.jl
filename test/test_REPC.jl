# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Renewables.PSSE.PlantController (PLAN-07, batch 7): REPCA1 and its PI with no variable limiter.
# `REPCA1` is exercised by the three `Renewable.PSSE` Tests against their OpenModelica oracle; here it is checked at
# `t = 0` on a closed operating point, where every channel of the controller has a hand-computable value.
#
# Operating point (the PVPlant Test's): P_0 = 1.5e6, Q_0 = -5.6658e6 on M_b = S_b = 100e6 (CoB = 1), v_0 = 1,
# angle_0 = 0.02574992, so p0 = 0.015 and q0 = -0.056658. The branch current is the one that carries exactly that
# power at that voltage, i.e. `ir0`, `ii0` of `regc_init`:
#   pbranch = vr*ir + vi*ii = p0,   qbranch = vi*ir - vr*ii = q0,   vreg = sqrt(vr^2 + vi^2) = v_0.
# With `Qref = q0`, `Plant_pref = p0` and `Freq = Freq_ref = fn` the controller is at rest and must hold
# `Qext = q00 = q0` and `Pref = p00 = p0`, whichever way the three flags are set.
#   - `fflag = false`: Pref = FREQ_FLAG.u3 = p0 straight through.
#   - `fflag = true`:  the active channel closes on itself -- add3_1 = Plant_pref - simpleLag(pbranch) + add1 = 0,
#                      KIG holds p00, so simpleLag1.y = p00.
#   - `refflag = false`: add4 = Qref - simpleLag2(qbranch) = 0 -> deadZone -> PI at q00 -> leadLag -> Qext = q00.
#   - `refflag = true` with Rc = Xc = 0: voltage_diff = vreg = v_0 = Vref, so add5 = VREF - simpleLag3 = 0 and the
#                      reactive channel is at rest as well; this is the leg that exercises VCFLAG and simpleLag3.
# `Voltage_dip` is 0 throughout (Vfrz = 0, vreg = 1) and both anti-windup channels are open (`or1.u2 = 0`, F-44/F-62).
@testset "Renewables.PSSE.PlantController REPCA1" begin
    P_0, Q_0, v_0, angle_0, M_b, fn = 1.5e6, -5.6658e6, 1.0, 0.02574992, 100e6, 60.0
    n = OpenIPSLComponents.regc_init(P_0, Q_0, v_0, angle_0, M_b, 100e6)
    inputs(c) = Equation[
        c.regulate_vr ~ n.vr0, c.regulate_vi ~ n.vi0,
        c.branch_ir ~ n.ir0, c.branch_ii ~ n.ii0,
        c.Freq ~ fn, c.Freq_ref ~ fn,
        c.Qref ~ n.q0, c.Plant_pref ~ n.p0,
        c.p0 ~ n.p0, c.q0 ~ n.q0, c.v0 ~ v_0,
    ]
    for (fflag, refflag, Rc, Xc) in ((false, false, 0.0025, 0.0025), (true, false, 0.0025, 0.0025),
                                     (false, true, 0.0, 0.0), (true, true, 0.0, 0.0))
        @named repc = REPCA1(; S_b = 100e6, M_b, fn, P_0, Q_0, v_0, angle_0, vcflag = true, refflag, fflag, Rc, Xc)
        @named rig = System(inputs(repc), t, [], []; systems = [repc])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
        # the three `fixed = false` parameters, resolved from the inputs (F-33)
        @test integ.ps[sys.repc.p00] ≈ n.p0 atol = 1e-12
        @test integ.ps[sys.repc.q00] ≈ n.q0 atol = 1e-12
        @test integ.ps[sys.repc.V0] ≈ v_0 atol = 1e-12
        # the measured quantities
        @test integ[sys.repc.pbranch] ≈ n.p0 atol = 1e-12
        @test integ[sys.repc.qbranch] ≈ n.q0 atol = 1e-12
        @test integ[sys.repc.vreg] ≈ v_0 atol = 1e-12
        @test integ[sys.repc.Voltage_dip] ≈ 0.0 atol = 1e-12
        # the two outputs at their power-flow values, and the states at rest
        @test integ[sys.repc.Pref] ≈ n.p0 atol = 1e-9
        @test integ[sys.repc.Qext] ≈ n.q0 atol = 1e-9
        @test integ[sys.repc.pI_No_Windup_notVariable.integral.y] ≈ n.q0 atol = 1e-9
        @test abs(initial_derivative(integ, sys, sys.repc.pI_No_Windup_notVariable.integral.y)) < 1e-9
        @test abs(initial_derivative(integ, sys, sys.repc.KIG.y)) < 1e-9
        # the anti-windup channel is open (F-44, F-62): or1.u2 = 0 and the freeze input is 0 too
        @test integ[sys.repc.pI_No_Windup_notVariable.or1.u2] ≈ 0.0 atol = 1e-12
        @test integ[sys.repc.pI_No_Windup_notVariable.or1.y] ≈ 0.0 atol = 1e-12
        @test integ[sys.repc.pI_No_Windup_notVariable.reset_switch.u2] ≈ 0.0 atol = 1e-12
    end
end

# PIwithNoVariableLimiter / PIwithVariableLimiter in isolation.
# K_P = 2, K_I = 3, y_start = 0.5, u = 0.1 held: y = integral + K_P*u = 0.5 + 0.2 = 0.7 at t = 0, and the
# integrator rises at K_I*u = 0.3 per second, so y(1 s) = 0.5 + 0.3 + 0.2 = 1.0, clamped by V_RMAX = 0.9.
# With `voltage_dip = 1` the reset switch selects `realExpression.y = 0`, the integrator is frozen at 0.5 and
# y stays 0.7 for the whole run: that freeze is the one input of the .mo's `or1` that OpenModelica does execute.
@testset "Renewables.PSSE.ElectricalController PI blocks" begin
    for dip in (0.0, 1.0)
        @named pino = PIwithNoVariableLimiter(; K_P = 2.0, K_I = 3.0, V_RMAX = 0.9, V_RMIN = -0.9, y_start = 0.5)
        @named piv = PIwithVariableLimiter(; K_P = 2.0, K_I = 3.0, y_start = 0.5)
        @named rig = System(Equation[
                pino.u ~ 0.1, pino.voltage_dip ~ dip,
                piv.u ~ 0.1, piv.voltage_dip ~ dip, piv.limit1 ~ 0.9, piv.limit2 ~ -0.9,
            ], t, [], []; systems = [pino, piv])
        sys = mtkcompile(rig)
        sol = solve(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-12, reltol = 1e-12)
        @test sol.retcode == ReturnCode.Success
        for b in (sys.pino, sys.piv)
            @test sol(0.0; idxs = b.integral.y) ≈ 0.5 atol = 1e-9
            @test sol(0.0; idxs = b.y) ≈ 0.7 atol = 1e-9
            @test sol(0.0; idxs = b.or1.u2) ≈ 0.0 atol = 1e-12       # the reset relation, never true (F-44)
            @test sol(0.0; idxs = b.or1.y) ≈ dip atol = 1e-12        # only the voltage_dip freeze reaches it
            if dip > 0.5
                @test sol(1.0; idxs = b.integral.y) ≈ 0.5 atol = 1e-8    # frozen
                @test sol(1.0; idxs = b.y) ≈ 0.7 atol = 1e-8
            else
                @test sol(0.5; idxs = b.integral.y) ≈ 0.65 atol = 1e-8   # 0.5 + 3*0.1*0.5
                @test sol(0.5; idxs = b.y) ≈ 0.85 atol = 1e-8
                @test sol(1.0; idxs = b.y) ≈ 0.9 atol = 1e-8             # clamped at V_RMAX / limit1
            end
        end
    end
end
