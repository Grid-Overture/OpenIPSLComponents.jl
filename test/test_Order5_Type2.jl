# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Order5_Type2 has no upstream Test: the machine of GroupBus1 of Examples.IEEE14.IEEE_14_Buses (615 MVA at bus 1),
# alone on a fixed source at its power-flow voltage, with vf = vf0 and pm = pm0.
# Two things are checked, both consequences of the .mo's `initial equation` (only der(e2q) = 0 and der(e2d) = 0;
# der(e1q) = 0 is commented out):
#  1. with e1q pinned to e1q0 the closed-form point is an exact equilibrium (every derivative < 1e-9) and vf0 = vf00;
#  2. without it the initialization is under-determined in e1q and ModelingToolkit says so, which is the F-28
#     situation the IEEE14 case resolves with an explicit u0 (OpenModelica fixes the first free start in declaration
#     order, e1q, and the .mo's own e1q0 is the value: der(e1q) = 0 at that point, checked in 1).
# The closed form: with xq0 = xq the rotor angle makes vd0 + ra*id0 - xq*iq0 = 0, so e2d0 = (xq - x2q)*iq0 and
# der(e2d) = 0; vf00 = V_MBtoSB*(K1*id0 + e1q0)/(1 - Taa/T1d0) gives (1 - Taa/T1d0)*vf_MB = K1*id0 + e1q0, so
# der(e1q) = 0; and e1q0 = -K1*(Taa/T1d0)*id0 + (1 - Taa/T1d0)*(e2q0 + K2*id0) makes der(e2q) = 0.
@testset "Order5_Type2" begin
    S_b = 100e6
    v_0, angle_0 = 1.06, -0.00751491652
    gen_kwargs = (; S_b, fn = 60, Sn = 615000000.0, Vn = 69000.0, V_b = 69000.0, v_0, angle_0,
        P_0 = 3.5203 * S_b, Q_0 = -0.281968 * S_b,
        ra = 0.0, xd = 0.8979, xq = 0.646, x1d = 0.2998, x2d = 0.23, x2q = 0.4, T1d0 = 7.4, T2d0 = 0.03,
        T2q0 = 0.033, M = 2 * 5.148, D = 2.0)
    @named src = FixedVoltageSource(; vr = v_0 * cos(angle_0), vi = v_0 * sin(angle_0))
    @named gen = Order5_Type2(; gen_kwargs...)
    @named rig = System(Equation[connect(src.p, gen.p), gen.vf ~ gen.vf0, gen.pm ~ gen.pm0], t, [], [];
        systems = [src, gen])
    sys = mtkcompile(rig)

    # 1. the closed-form point, with e1q fixed as OpenModelica fixes it
    prob = ODEProblem(sys, [sys.gen.e1q => sys.gen.e1q0], (0.0, 1.0))
    integ = init(prob, Rodas5P(); abstol = 1e-10, reltol = 1e-10,
        initializealg = OverrideInit(; nlsolve = NewtonRaphson()))
    e1q0 = integ.ps[sys.gen.e1q0]
    @test integ[sys.gen.e1q] ≈ e1q0 atol = 1e-12
    @test integ[sys.gen.e2q] ≈ integ.ps[sys.gen.e2q0] atol = 1e-9
    @test integ[sys.gen.e2d] ≈ integ.ps[sys.gen.e2d0] atol = 1e-9
    @test integ[sys.gen.e2d] ≈ (0.646 - 0.4) * integ.ps[sys.gen.iq0] atol = 1e-9   # (xq - x2q)*iq0
    @test integ[sys.gen.vf] ≈ integ.ps[sys.gen.vf00] atol = 1e-12
    @test integ[sys.gen.v] ≈ v_0 atol = 1e-9
    @test integ[sys.gen.P] ≈ 3.5203 atol = 1e-9
    @test integ[sys.gen.Q] ≈ -0.281968 atol = 1e-9
    for var in (sys.gen.delta, sys.gen.w, sys.gen.e1q, sys.gen.e2q, sys.gen.e2d)
        @test abs(initial_derivative(integ, sys, var)) < 1e-9
    end
    sol = solve(prob, Rodas5P(); abstol = 1e-10, reltol = 1e-10,
        initializealg = OverrideInit(; nlsolve = NewtonRaphson()))
    @test sol.retcode == ReturnCode.Success
    @test sol(1.0; idxs = sys.gen.e1q) ≈ e1q0 atol = 1e-8   # it stays at the equilibrium

    # 2. without that initial condition the initialization is one equation short (F-28): ModelingToolkit warns
    # "2 equations for 3 unknowns" and falls back to least squares, so `fully_determined = true` is what makes it
    # an error. OpenModelica takes the same system and fixes `e1q` at its `start`, which is e1q0 (checked in 1).
    @test_throws Exception ODEProblem(sys, [], (0.0, 1.0); fully_determined = true)
end
