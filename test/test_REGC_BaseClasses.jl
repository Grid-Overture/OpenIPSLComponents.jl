# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Renewables.PSSE.InverterInterface (PLAN-07, batch 7): LVPL, LVACM and REGCA1.
# `LVPL` and `LVACM` have no upstream Test of their own; `REGCA1` is exercised by the three `Renewable.PSSE` Tests
# against their OpenModelica oracle, and here at `t = 0` on a minimal network, where the arithmetic is closed.

# LVPL: y = 0 below Zerox, Lvpl1 above Brkpt, and the line (V - Zerox)*Lvpl1/(Brkpt - Zerox) in between.
# Zerox = 0.5, Brkpt = 0.9, Lvpl1 = 1.22 -> slope 1.22/0.4 = 3.05:
#   V = 0.4 -> 0;  V = 0.5 -> 0;  V = 0.7 -> 0.2*3.05 = 0.61;  V = 0.9 -> 1.22;  V = 1.1 -> 1.22.
# LVACM: y = 0 at or below lvpnt0, 1 at or above lvpnt1, and (Vt - lvpnt0)/(lvpnt1 - lvpnt0) in between.
# lvpnt0 = 0.4, lvpnt1 = 0.8 -> Vt = 0.3 -> 0;  0.4 -> 0;  0.6 -> 0.5;  0.8 -> 1;  1.0 -> 1.
@testset "Renewables.PSSE.InverterInterface LVPL / LVACM" begin
    vs = [0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1]
    lvpl_expected = [0.0, 0.0, 0.0, 0.305, 0.61, 0.915, 1.22, 1.22, 1.22]
    lvacm_expected = [0.0, 0.0, 0.25, 0.5, 0.75, 1.0, 1.0, 1.0, 1.0]
    for (k, v) in enumerate(vs)
        @named lvpl = LVPL(; Brkpt = 0.9, Lvpl1 = 1.22, Zerox = 0.5)
        @named lvacm = LVACM(; lvpnt0 = 0.4, lvpnt1 = 0.8)
        @named rig = System(Equation[lvpl.V ~ v, lvacm.Vt ~ v], t, [], []; systems = [lvpl, lvacm])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
        @test integ[sys.lvpl.y] ≈ lvpl_expected[k] atol = 1e-9
        @test integ[sys.lvacm.y] ≈ lvacm_expected[k] atol = 1e-9
    end
end

# REGCA1 in a minimal network: an ideal voltage source at the power-flow point, and the two current commands held at
# the initial values the base computes. The inverter must then sit exactly at its power-flow point.
# Power flow (the PVPlant Test's): P_0 = 1.5e6, Q_0 = -5.6658e6 on M_b = S_b = 100e6, v_0 = 1, angle_0 = 0.02574992.
#   p0 = 0.015, q0 = -0.056658, and with CoB = 1 the pin currents are ir0, ii0 of BaseREGC.
# Checks at t = 0: Pgen = p0, Qgen = q0, V_t = v_0, the five initialization outputs, and both integrator
# derivatives below 1e-9 (the point is an equilibrium). Then the active-current channel is stepped, once below and
# once above the `rrpwr` limit.
@testset "Renewables.PSSE.InverterInterface REGCA1" begin
    P_0, Q_0, v_0, angle_0, M_b = 1.5e6, -5.6658e6, 1.0, 0.02574992, 100e6
    n = OpenIPSLComponents.regc_init(P_0, Q_0, v_0, angle_0, M_b, 100e6)
    @named src = FixedVoltageSource(; vr = v_0 * cos(angle_0), vi = v_0 * sin(angle_0))
    @named regc = REGCA1(; S_b = 100e6, M_b, P_0, Q_0, v_0, angle_0)
    @named rig = System(Equation[connect(src.p, regc.p), regc.Ipcmd ~ n.Ip0, regc.Iqcmd ~ -n.Iq0],
        t, [], []; systems = [src, regc])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 1.0))
    integ = init(prob, Rodas5P(); initializealg = INIT)
    @test integ[sys.regc.V_t] ≈ v_0 atol = 1e-9
    @test integ[sys.regc.Pgen] ≈ n.p0 atol = 1e-9
    @test integ[sys.regc.Qgen] ≈ n.q0 atol = 1e-9
    @test integ[sys.regc.IP0] ≈ n.Ip0 atol = 1e-12
    @test integ[sys.regc.IQ0] ≈ n.Iq0 atol = 1e-12
    @test integ[sys.regc.V_0] ≈ v_0 atol = 1e-12
    @test integ[sys.regc.p_0] ≈ n.p0 atol = 1e-12
    @test integ[sys.regc.q_0] ≈ n.q0 atol = 1e-12
    # `delta` is an alias of the bus voltage angle, not a rotor angle (sic)
    @test integ[sys.regc.delta] ≈ angle_0 atol = 1e-9
    # the two converter integrators start at Ip0 / Iq0 and stay there: this is the equilibrium
    @test integ[sys.regc.integrator1.y] ≈ n.Ip0 atol = 1e-9
    @test integ[sys.regc.integrator.y] ≈ n.Iq0 atol = 1e-9
    @test abs(initial_derivative(integ, sys, sys.regc.integrator1.y)) < 1e-9
    @test abs(initial_derivative(integ, sys, sys.regc.integrator.y)) < 1e-9
    # the low-voltage logic is inert at v = 1: LVACM = 1 (v > lvpnt1 = 0.8), LVPL = Lvpl1 (v > Brkpt = 0.9)
    @test integ[sys.regc.LVACM.y] ≈ 1.0 atol = 1e-9
    @test integ[sys.regc.LVPL.y] ≈ 1.22 atol = 1e-9

    # The active-current channel is `add2 = Ipcmd - Ip` -> `limiter4(uMax = rrpwr)` -> `integrator1(k = 1/Tg)`,
    # i.e. a first-order lag of time constant Tg whose *rate* saturates at rrpwr/Tg.
    # (a) a small step does not reach the limit: Ipcmd steps by 1 with rrpwr = 10, so limiter4 never saturates and
    #     Ip - Ip0 = 1 - exp(-t/Tg). At t = 0.05 with Tg = 0.02: 1 - e^-2.5 = 0.9179150013753544,
    #     and limiter4.y(0.02) = e^-1 = 0.36787944117144233.
    @named regc2 = REGCA1(; S_b = 100e6, M_b, P_0, Q_0, v_0, angle_0, rrpwr = 10.0, Tg = 0.02)
    @named rig2 = System(Equation[connect(src.p, regc2.p), regc2.Ipcmd ~ n.Ip0 + 1.0, regc2.Iqcmd ~ -n.Iq0],
        t, [], []; systems = [src, regc2])
    sys2 = mtkcompile(rig2)
    sol = solve(ODEProblem(sys2, [], (0.0, 0.05)), Rodas5P(); abstol = 1e-10, reltol = 1e-10,
        initializealg = INIT)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.05; idxs = sys2.regc2.integrator1.y) - n.Ip0 ≈ 0.9179150013753544 atol = 1e-7
    @test sol(0.02; idxs = sys2.regc2.limiter4.y) ≈ 0.36787944117144233 atol = 1e-7
    # (b) a step of 20 does saturate it: limiter4 sits at rrpwr = 10 while Ipcmd - Ip > 10, so Ip rises at
    #     rrpwr/Tg = 500 per second. At t = 0.01: Ip - Ip0 = 5 exactly, and limiter4.y is still 10.
    @named regc3 = REGCA1(; S_b = 100e6, M_b, P_0, Q_0, v_0, angle_0, rrpwr = 10.0, Tg = 0.02)
    @named rig3 = System(Equation[connect(src.p, regc3.p), regc3.Ipcmd ~ n.Ip0 + 20.0, regc3.Iqcmd ~ -n.Iq0],
        t, [], []; systems = [src, regc3])
    sys3 = mtkcompile(rig3)
    sol3 = solve(ODEProblem(sys3, [], (0.0, 0.01)), Rodas5P(); abstol = 1e-10, reltol = 1e-10,
        initializealg = INIT)
    @test sol3.retcode == ReturnCode.Success
    @test sol3(0.005; idxs = sys3.regc3.limiter4.y) ≈ 10.0 atol = 1e-9
    @test sol3(0.01; idxs = sys3.regc3.integrator1.y) - n.Ip0 ≈ 5.0 atol = 1e-6
end
