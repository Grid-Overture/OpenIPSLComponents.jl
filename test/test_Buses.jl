# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# InfiniteBus and BusExt (PLAN-02). An unconnected pin gets `flow ~ 0` from expand_connections (Modelica semantics),
# so currents are injected through the test component `CurrentInjection` of runtests.jl connected to the pin.
# InfiniteBus(v_0 = 1.05, angle_0 = 0.1, S_b = 1e8) with 0.5 - 0.2j pu injected into p:
#   p.vr = 1.05 cos 0.1, p.vi = 1.05 sin 0.1; P = -(vr*0.5 + vi*(-0.2))*S_b, Q = -(vi*0.5 - vr*(-0.2))*S_b.
# BusExt(np = 2, nn = 1) with p_1 on a fixed voltage (1, 0), 0.3 + 0.1j injected into p_2 and 0.2 - 0.4j into n_1:
#   all pins share the voltage; the bus's own connect(p_1, p_2), connect(p_1, n_1) (outer connectors) give
#   p_1.ir = -(0.3 + 0.2) = -0.5, p_1.ii = -(0.1 - 0.4) = 0.3, so the source pin carries src.p.ir = 0.5, src.p.ii = -0.3;
#   v = 1, angle = 0.
@testset "Buses" begin
    vr0, vi0 = 1.05 * cos(0.1), 1.05 * sin(0.1)
    @named ib = InfiniteBus(; v_0 = 1.05, angle_0 = 0.1, S_b = 1e8)
    @named inj = CurrentInjection(; ir = 0.5, ii = -0.2)
    @named rig = System(Equation[connect(ib.p, inj.p)], t, [], []; systems = [ib, inj])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.ib.p.vr] ≈ vr0 atol = 1e-9
    @test integ[sys.ib.p.vi] ≈ vi0 atol = 1e-9
    @test integ[sys.ib.p.ir] ≈ 0.5 atol = 1e-9
    @test integ[sys.ib.P] ≈ -(vr0 * 0.5 + vi0 * (-0.2)) * 1e8 atol = 1e-9 * 1e8
    @test integ[sys.ib.Q] ≈ -(vi0 * 0.5 - vr0 * (-0.2)) * 1e8 atol = 1e-9 * 1e8

    @named bus = BusExt(; np = 2, nn = 1)
    @named src = FixedVoltageSource(; vr = 1.0, vi = 0.0)
    @named inj2 = CurrentInjection(; ir = 0.3, ii = 0.1)
    @named inj3 = CurrentInjection(; ir = 0.2, ii = -0.4)
    @named rig2 = System(Equation[connect(src.p, bus.p_1), connect(inj2.p, bus.p_2), connect(inj3.p, bus.n_1)], t, [], [];
        systems = [bus, src, inj2, inj3])
    sys2 = mtkcompile(rig2)
    integ2 = init(ODEProblem(sys2, [], (0.0, 1.0)), Rodas5P())
    @test integ2[sys2.bus.p_2.ir] ≈ 0.3 atol = 1e-9
    @test integ2[sys2.bus.p_1.ir] ≈ -0.5 atol = 1e-9
    @test integ2[sys2.src.p.ir] ≈ 0.5 atol = 1e-9
    @test integ2[sys2.src.p.ii] ≈ -0.3 atol = 1e-9
    @test integ2[sys2.bus.n_1.vr] ≈ 1.0 atol = 1e-9
    @test integ2[sys2.bus.p_2.vi] ≈ 0.0 atol = 1e-9
    @test integ2[sys2.bus.v] ≈ 1.0 atol = 1e-9
    @test integ2[sys2.bus.angle] ≈ 0.0 atol = 1e-9
end
