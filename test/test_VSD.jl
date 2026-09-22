# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Electrical.VSD.Generic (PLAN-07, batch 7): the volts/hertz controller and the phasor converter. Neither has an
# upstream Test; the only case that instantiates them is `Examples.Microgrids.IEEEMicrogrid`, which OpenModelica
# cannot initialize (F-63), so this file is their whole numeric validation.

# VoltsHertzController at equilibrium. With `motor_speed = W_ref = w` held, the speed error `add.y = W_ref -
# Speed_Sensor.y` decays to zero with the sensor's own time constant Tr, and `we = limiter(Speed_Sensor.y +
# Kp*add.y + integrator.y)` settles at `w + integrator.y(inf)`.
# **The integrator keeps the start-up transient.** The sensor starts at `0.1*1.9*pi*fn` (sic), not at `w`, so the
# error is `(w - sensor0)*exp(-t/Tr)` and the integrator accumulates
#     integrator.y(inf) = Ki * integral of that = Ki*Tr*(w - sensor0),
# which nothing ever unwinds: the loop has no path that drives the integrator back once the error is zero. That is
# the .mo as written, and the closed form is what this test checks -- it pins Ki, Tr, the sensor start value and
# the whole PI path at once.
# fn = 60 -> Kf = 1/(120*pi) = 2.6525823848649224e-3; f_min = 0, f_max = 80 -> we in [0, 160*pi], never binding.
#   sensor0 = 0.1*1.9*pi*60 = 35.81418746...;  Ki*Tr = 0.2*0.01 = 0.002
#   w = 2*pi*50 = 314.15926535.. -> we = w + 0.002*(w - sensor0) = 314.71595557..,  m = Kf*we = 0.834810
@testset "Electrical.VSD.Generic.VoltsHertzController equilibrium" begin
    w = 2 * pi * 50
    @named vhz = VoltsHertzController(; S_b = 100e6, V_b = 400.0, fn = 60, f_max = 80, f_min = 0,
        m0 = 0.095, Kp = 0.5, Ki = 0.2)
    @named rig = System(Equation[vhz.motor_speed ~ w, vhz.W_ref ~ w, vhz.Vc ~ 500.0], t, [], []; systems = [vhz])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.0; idxs = sys.vhz.Kf) ≈ 1 / (2 * pi * 60) atol = 1e-15
    @test sol(0.0; idxs = sys.vhz.Speed_Sensor.y) ≈ 0.1 * 1.9 * pi * 60 atol = 1e-9   # the .mo's 1.9*pi
    @test sol(0.0; idxs = sys.vhz.m) ≈ 0.095 atol = 1e-9                              # firstOrder(y_start = m0)
    sensor0 = 0.1 * 1.9 * pi * 60
    we_eq = w + 0.2 * 0.01 * (w - sensor0)
    @test sol(1.0; idxs = sys.vhz.we) ≈ we_eq atol = 1e-6
    @test sol(1.0; idxs = sys.vhz.integrator.y) ≈ 0.2 * 0.01 * (w - sensor0) atol = 1e-6
    @test sol(1.0; idxs = sys.vhz.add.y) ≈ 0.0 atol = 1e-6          # the error is gone
    @test sol(1.0; idxs = sys.vhz.m) ≈ we_eq / (2 * pi * 60) atol = 1e-6
    # gain2's output feeds nothing, but the block is there and reads Vc (sic)
    @test sol(1.0; idxs = sys.vhz.gain2.y) ≈ 500.0 / 400.0 atol = 1e-9
end

# The `limiter1` saturation: with `we > 2*pi*fn` the product `Kf*we` exceeds 1 and the modulation index clamps at 1.
# w = 2*pi*70 with fn = 60 -> we = w + 0.002*(w - sensor0) = 440.63098913..,  Kf*we = 1.16833.. > 1 -> m -> 1.
@testset "Electrical.VSD.Generic.VoltsHertzController saturation" begin
    w = 2 * pi * 70
    @named vhz = VoltsHertzController(; S_b = 100e6, V_b = 400.0, fn = 60, f_max = 80, f_min = 0,
        m0 = 0.095, Kp = 0.5, Ki = 0.2)
    @named rig = System(Equation[vhz.motor_speed ~ w, vhz.W_ref ~ w, vhz.Vc ~ 500.0], t, [], []; systems = [vhz])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
    @test sol.retcode == ReturnCode.Success
    sensor0 = 0.1 * 1.9 * pi * 60
    we_eq = w + 0.2 * 0.01 * (w - sensor0)
    @test sol(1.0; idxs = sys.vhz.we) ≈ we_eq atol = 1e-6
    @test sol(1.0; idxs = sys.vhz.product1.y) ≈ we_eq / (2 * pi * 60) atol = 1e-6
    @test sol(1.0; idxs = sys.vhz.product1.y) > 1.0
    @test sol(1.0; idxs = sys.vhz.limiter1.y) ≈ 1.0 atol = 1e-9
    @test sol(1.0; idxs = sys.vhz.m) ≈ 1.0 atol = 1e-6
end

# AC2DCandDC2AC driven from an ideal grid voltage into a motor that draws current.
# `Vd0 = 3*sqrt(6)*|V|*V_b/pi` with |V| = 1 and V_b = 400 -> 3*sqrt(6)*400/pi = 935.60967... V, and
# `Vc0 = 2*sqrt(2)*(3*sqrt(3)/(2*pi))*V_b` (m0 cancels) is the **same** number, because
# 2*sqrt(2)*3*sqrt(3)/(2*pi) = 3*sqrt(6)/pi.
# `CurrentInjection(ir = I)` imposes `conv.n.ir = I`, so `Pmotor = -(n.vr*n.ir + n.vi*n.ii) = -I*n.vr`:
# a **negative** `I` is a motor drawing power and a positive one is a motor braking. Both are per unit on S_b, and
# `Ii = Pmotor*S_b/Vc` turns them into amperes, so the injection has to be of the size a real drive has: the
# `IEEEMicrogrid` motors are 20 kW on `S_b = 100 MVA`, i.e. 2e-4 pu, and with `n.vr ~ 0.0786` pu that is
# `n.ir ~ 2.5e-3` pu. An injection of 1 pu here would be 100 MW and the link would run away.
# In steady state the inductor current is constant and the capacitor is no longer charging, so
#   Resistor.i = Ii.y = Pmotor*S_b/Vc     and     Vc = Vd0 - (Rdc + Ron)*Resistor.i,
# the whole DC link in two closed relations. `Q = 0` always (the .mo's own equation), and with the grid pin at
# (1, 0) the AC currents are `p.ir = P`, `p.ii = 0`.
@testset "Electrical.VSD.Generic.AC2DCandDC2AC steady state" begin
    V_b, S_b, Rdc, Ron = 400.0, 100e6, 0.01, 1e-5
    @named src = FixedVoltageSource(; vr = 1.0, vi = 0.0)
    @named conv = AC2DCandDC2AC(; S_b, V_b, fn = 60, Rdc, Ldc = 1e-3, Cdc = 0.02, m0 = 0.095)
    @named load = CurrentInjection(; ir = -2.5e-3, ii = 0.0)   # a ~20 kW motor drawing power
    @named rig = System(Equation[connect(src.p, conv.p), connect(load.p, conv.n),
        conv.m_input ~ 0.095], t, [], []; systems = [src, conv, load])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [sys.conv.Inductor.i => 0.0], (0.0, 3.0)), Rodas5P();
        abstol = 1e-10, reltol = 1e-10, initializealg = INIT)
    @test sol.retcode == ReturnCode.Success
    vd0 = 3 * sqrt(6) * 1.0 * V_b / pi
    @test sol(0.0; idxs = sys.conv.Vd0.y) ≈ vd0 atol = 1e-9
    @test sol(0.0; idxs = sys.conv.Capacitor.v) ≈ vd0 atol = 1e-9     # Vc0 = Vd0 for |V| = 1 (see the comment)
    @test sol(0.0; idxs = sys.conv.Vc) ≈ vd0 atol = 1e-9
    # the motor is drawing: Pmotor > 0, the link carries current and the switch stays closed
    e = 3.0
    @test sol(e; idxs = sys.conv.Pmotor.y) > 0.0
    @test sol(e; idxs = sys.conv.switch.off) ≈ 0.0 atol = 1e-12
    @test sol(e; idxs = sys.conv.open_circuit_condition.y) ≈ 0.0 atol = 1e-12
    # the two closed relations of the DC link at rest
    ir = sol(e; idxs = sys.conv.Resistor.i)
    @test ir ≈ sol(e; idxs = sys.conv.Ii.y) rtol = 1e-6
    @test sol(e; idxs = sys.conv.Capacitor.v) ≈ vd0 - (Rdc + Ron) * ir rtol = 1e-7
    @test sol(e; idxs = sys.conv.Ii.y) ≈
          sol(e; idxs = sys.conv.Pmotor.y) * S_b / sol(e; idxs = sys.conv.Capacitor.v) rtol = 1e-12
    # the AC side: Pdc = Vd0*i, P*S_b = Pdc, Q = 0, and the currents solved for (the header's deviation)
    @test sol(e; idxs = sys.conv.Pdc) ≈ vd0 * ir rtol = 1e-12
    @test sol(e; idxs = sys.conv.P) ≈ vd0 * ir / S_b atol = 1e-12
    @test sol(e; idxs = sys.conv.Q) ≈ 0.0 atol = 1e-12
    @test sol(e; idxs = sys.conv.S) ≈ abs(vd0 * ir / S_b) atol = 1e-12
    @test sol(e; idxs = sys.conv.p.ir) ≈ vd0 * ir / S_b atol = 1e-12
    @test sol(e; idxs = sys.conv.p.ii) ≈ 0.0 atol = 1e-15
    # the motor terminal voltage follows the modulation index: Vmotor = Vc*m/(2*sqrt(2)*V_b)
    @test sol(e; idxs = sys.conv.n.vr) ≈
          sol(e; idxs = sys.conv.Capacitor.v) * 0.095 / (2 * sqrt(2) * V_b) atol = 1e-9
    @test sol(e; idxs = sys.conv.n.vi) ≈ 0.0 atol = 1e-12             # sin(0), literal
end

# Braking: a motor that *delivers* power charges the capacitor, drives the link current negative and must open the
# switch, which is the whole point of the block (F-61). `CurrentInjection(ir = +2.5e-3)` makes `Pmotor < 0`.
# The inductor current is handed in as `1e-3` rather than the model's `Il0 = 0`: its `start` is a guess
# (`fixed = false`), so the case supplies it (F-28), and a link current of exactly zero puts the switch's root
# function exactly on its root at `t = 0`, where a crossing cannot be detected (`sign(0)` is neither side). The
# real case starts with the converter feeding the motors, i.e. with a positive link current, so this is the
# physical start, not a fudge.
# The horizon is 20 ms, not the 200 ms of the motoring case: with the switch **open** the inductor current is held
# near zero through `Goff = 1e-5`, whose time constant `L*Goff = 1e-8 s` the solver has to resolve, so the open
# mode costs about a million steps per second of simulated time. That stiffness is the `.mo`'s own (an ideal
# opening switch in series with a DC-link inductor) and is the reason `IEEEMicrogrid`'s two converters are the
# expensive part of that case.
@testset "Electrical.VSD.Generic.AC2DCandDC2AC braking opens the switch" begin
    V_b, S_b = 400.0, 100e6
    @named src = FixedVoltageSource(; vr = 1.0, vi = 0.0)
    @named conv = AC2DCandDC2AC(; S_b, V_b, fn = 60, Rdc = 0.01, Ldc = 1e-3, Cdc = 0.02, m0 = 0.095)
    @named load = CurrentInjection(; ir = 2.5e-3, ii = 0.0)    # the same motor braking
    @named rig = System(Equation[connect(src.p, conv.p), connect(load.p, conv.n),
        conv.m_input ~ 0.095], t, [], []; systems = [src, conv, load])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [sys.conv.Inductor.i => 1e-3], (0.0, 0.02)), Rodas5P();
        abstol = 1e-8, reltol = 1e-8, initializealg = INIT, maxiters = 2_000_000)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.01; idxs = sys.conv.Pmotor.y) < 0.0                   # the motor is delivering
    @test sol(0.01; idxs = sys.conv.switch.off) ≈ 1.0 atol = 1e-12    # the switch has opened
    @test sol(0.01; idxs = sys.conv.open_circuit_condition.y) ≈ 1.0 atol = 1e-12
    @test sol(0.02; idxs = sys.conv.Capacitor.v) > sol(0.0; idxs = sys.conv.Capacitor.v)  # and the link charges
    # with the switch open the link carries only the leakage Goff*(p.v - n.v) of the switch
    @test abs(sol(0.02; idxs = sys.conv.Resistor.i)) < 1e-2
end
