# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# NonElectrical.Continuous (PLAN-01): closed-form responses, checked to 1e-6 (algebraic values to 1e-9).
# SimpleLag(K = 2, T = 0.5, y_start = 0) on u = 1: y = 2(1 - e^{-2t}). With T = 0: y = K u = 2 (T_mod = 1000 keeps the state slow).
# SimpleLead(K = 2, T = 0.5, y_start) on u = sin(t)... the block differentiates its input: with u = t (ramp), T*1 = K y - t
#   -> y = (t + 0.5)/2 -> y(1) = 0.75.
# LeadLag(K = 2, T1 = 0.1, T2 = 0.5, y_start = 2) on u = 1 from an equilibrium: y stays 2; with T1 = T2: y = K u = 2.
# DerivativeLag(K = 3, T = 0.2, y_start = 0) on u = 1 (step at t = 0 from the InitialOutput y = 0): TF = K s/(1 + T s):
#   the InitialOutput y(0) = 0 -> x_scaled(0) = 0 and y(t) = (K/T) e^{-t/T}... y(0) = 0 requires u(0) = 0, so the
#   response to a ramp u = t: y = K (1 - e^{-t/T}) -> y(1) = 3(1 - e^-5). With T = 0: y = u.
# SimpleLagLim(K = 20, T = 0.2, y_start = 1.902077693650219, outMax = 5, outMin = -5): the AVRTypeII amplifier of
#   test_AVRTypeII.jl, input u = (vref - vm) - vr2 = 0.0951.. at equilibrium (y_start/K); a step u = 0.6 for t in [0.5, 1.0)
#   winds the state above 5 while y = 5, and the reset at the recovery drops it to 5 (F-14).
# SimpleLagLimVar(K = 20, T = 0.2, y_start = 1.9) with limits outMax = 5, outMin = -5: the output clamps but the state is
#   never reset (OpenModelica never executes its `when`, F-40): while y = 5, der(state) = (K u - 5)/T exactly.
# IntegratorLimVar(K = 1, y_start = 0.5) with outMax = 1, outMin = 0 on u = 1: y = 0.5 + t until 1 (t = 0.5) then held.
# LeadLagLim(K = 1, T1 = 0.1, T2 = 0.5, outMax = 1.5, outMin = -1.5, y_start = 1) on u = 1 (equilibrium): y stays 1.
# PI_No_Windup(K_P = 1, K_I = 2, V_RMAX = 10, V_RMIN = -10, y_start_int = 0) on u = 1: y = 1 + 2t -> 3 at t = 1.
# PID_No_Windup(... K_D = 0.5, T_D = 0.1) on u = 1: adds a derivative channel that starts at K_D*kd*u = 5 and decays
#   with time constant T_D: y(0+) = 1 + 5 = 6, y(1) ≈ 1 + 2 + 5 e^{-10} = 3.000227.
# RampTrackingFilter(T_1 = 0.5, T_2 = 0.1, M = 1, N = 1, y_start = 1) on u = 1: NoInit states start at x_start = 0,
#   TF2 outputs 1 + 4 e^{-10t} and TF1 (1/(1 + 0.1 s), y(0) = 0) 1 - e^{-10t} + 40 t e^{-10t}: 0 at t = 0, ~1 at t = 1;
#   M = 0: y = u.
@testset "NonElectrical.Continuous" begin
    @named sl = SimpleLag(; K = 2, T = 0.5, y_start = 0)
    @named sl0 = SimpleLag(; K = 2, T = 0, y_start = 0)
    @named sld = SimpleLead(; K = 2, T = 0.5, y_start = 0.25)
    @named ll = LeadLag(; K = 2, T1 = 0.1, T2 = 0.5, y_start = 2)
    @named lle = LeadLag(; K = 2, T1 = 0.5, T2 = 0.5, y_start = 2)
    @named dl = DerivativeLag(; K = 3, T = 0.2, y_start = 0)
    @named dl0 = DerivativeLag(; K = 3, T = 0, y_start = 0)
    @named ilv = IntegratorLimVar(; K = 1, y_start = 0.5)
    @named lll = LeadLagLim(; K = 1, T1 = 0.1, T2 = 0.5, outMax = 1.5, outMin = -1.5, y_start = 1)
    @named pinw = PI_No_Windup(; K_P = 1, K_I = 2, V_RMAX = 10, V_RMIN = -10, y_start_int = 0)
    @named pid = PID_No_Windup(; K_P = 1, K_I = 2, V_RMAX = 10, V_RMIN = -10, y_start_int = 0, K_D = 0.5, T_D = 0.1)
    @named rtf = RampTrackingFilter(; T_1 = 0.5, T_2 = 0.1, M = 1, N = 1, y_start = 1)
    @named rtf0 = RampTrackingFilter(; T_1 = 0.5, T_2 = 0.1, M = 0, N = 1, y_start = 1)
    @named rig = System(Equation[sl.u ~ 1, sl0.u ~ 1, sld.u ~ t, ll.u ~ 1, lle.u ~ 1, dl.u ~ t, dl0.u ~ t,
            ilv.u ~ 1, ilv.outMax ~ 1, ilv.outMin ~ 0, lll.u ~ 1, pinw.u ~ 1, pid.u ~ 1, rtf.u ~ 1, rtf0.u ~ 1],
        t, [], []; systems = [sl, sl0, sld, ll, lle, dl, dl0, ilv, lll, pinw, pid, rtf, rtf0])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(1.0; idxs = sys.sl.y) ≈ 2 * (1 - exp(-2)) atol = 1e-6
    @test sol(0.3; idxs = sys.sl0.y) ≈ 2 atol = 1e-9
    @test sol(1.0; idxs = sys.sld.y) ≈ 0.75 atol = 1e-6
    @test sol(1.0; idxs = sys.ll.y) ≈ 2 atol = 1e-6
    @test sol(0.7; idxs = sys.lle.y) ≈ 2 atol = 1e-9
    @test sol(1.0; idxs = sys.dl.y) ≈ 3 * (1 - exp(-5)) atol = 1e-6
    @test sol(0.7; idxs = sys.dl0.y) ≈ 0.7 atol = 1e-9
    @test sol(0.25; idxs = sys.ilv.y) ≈ 0.75 atol = 1e-6
    @test sol(1.0; idxs = sys.ilv.y) ≈ 1 atol = 1e-6
    @test sol(1.0; idxs = sys.lll.y) ≈ 1 atol = 1e-6
    @test sol(1.0; idxs = sys.pinw.y) ≈ 3 atol = 1e-6
    @test sol(1.0; idxs = sys.pid.y) ≈ 3 + 5 * exp(-10) atol = 1e-5
    @test sol(0.0; idxs = sys.rtf.y) ≈ 0 atol = 1e-9          # TF1's state starts at x_start = 0 (NoInit)
    @test abs(sol(1.0; idxs = sys.rtf.y) - 1) < 5e-3          # 39 e^-10 residue of the chain's transient
    @test sol(0.5; idxs = sys.rtf0.y) ≈ 1 atol = 1e-9

    # the anti-windup lag: a smooth input u = 0.1 + 0.25(1 - cos(pi t)) (0.1 -> 0.6 -> 0.1 over [0, 2], K u up to 12)
    # winds the state above outMax = 5 while the output is clamped, and the reset at the sign change of K*u - state
    # (a smooth crossing on the way down) pulls it back to outMax (F-14); same for the variable-limit version.
    # (The crossing must not coincide with an input discontinuity: the AVRTypeII test crosses 1 ms after the jump.)
    @named sll = SimpleLagLim(; K = 20, T = 0.2, y_start = 2, outMax = 5, outMin = -5)
    @named sllv = SimpleLagLimVar(; K = 20, T = 0.2, y_start = 2)
    u_in = 0.1 + 0.25 * (1 - cos(pi * t))
    @named rig2 = System(Equation[sll.u ~ u_in, sllv.u ~ u_in, sllv.outMax ~ 5, sllv.outMin ~ -5], t, [], []; systems = [sll, sllv])
    sys2 = mtkcompile(rig2)
    sol2 = solve(ODEProblem(sys2, [], (0.0, 2.5)), Rodas5P(); abstol = 1e-8, reltol = 1e-8)
    @test sol2.retcode == ReturnCode.Success
    @test sol2(0.0; idxs = sys2.sll.y) ≈ 2 atol = 1e-9
    @test maximum(sol2(0.5:0.01:1.5; idxs = sys2.sll.state).u) > 8          # wound up well above the limit
    @test maximum(sol2(0.0:0.01:2.5; idxs = sys2.sll.y).u) ≈ 5 atol = 1e-9   # output clamped at outMax
    @test sol2(2.5; idxs = sys2.sll.state) <= 5 + 1e-6                       # reset to outMax at the crossing, then decaying
    @test sol2(2.5; idxs = sys2.sll.state) > 2                               # ... not decayed from 12 as it would without the reset (12 e^-5 = 0.08 above 2)
    # the variable-limit version has no reset (F-40): the state keeps integrating (K u - 5)/T while the output is
    # clamped, so state(2.5) - state(1.5) = ∫ (10 - 25 cos(pi t)) dt over [1.5, 2.5] = 10 - 50/pi (state > 5 throughout)
    @test sol2(0.0; idxs = sys2.sllv.y) ≈ 2 atol = 1e-9
    @test maximum(sol2(0.0:0.01:2.5; idxs = sys2.sllv.y).u) ≈ 5 atol = 1e-9
    @test minimum(sol2(1.5:0.01:2.5; idxs = sys2.sllv.state).u) > 5
    @test sol2(2.5; idxs = sys2.sllv.state) - sol2(1.5; idxs = sys2.sllv.state) ≈ 10 - 50 / pi atol = 1e-5
end
