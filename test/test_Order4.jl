# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Gen1's machine alone on a fixed source at its power-flow voltage, with vf = vf0 and pm = pm0 (no AVR, no governor).
# The closed-form initialization must reproduce the OpenModelica row t = 0 (gen1 matches to machine precision, F-11),
# der(e1q) must vanish at t = 0, and e1d must decay as e1d0*exp(-t/T1q0) because xq != x1q selects the pure-decay
# branch of Order4.mo (F-04).
@testset "Order4" begin
    S_b = 100e6
    v_0, angle_0 = 1.025, 0.161966652912444
    om = OM_T0["gen1"]
    @named src = FixedVoltageSource(; vr = v_0 * cos(angle_0), vi = v_0 * sin(angle_0))
    @named gen = Order4(; S_b = S_b, fn = 60, Sn = 100000000, Vn = 18000, V_b = 18000, v_0 = v_0, angle_0 = angle_0,
        P_0 = 1.629999999999999 * S_b, Q_0 = 0.066536560198189 * S_b,
        ra = 0, xd = 0.8958, xq = 0.8645, x1d = 0.1198, x1q = 0.1969, T1d0 = 6, T1q0 = 0.5350, M = 12.8, D = 0)
    @named rig = System(Equation[connect(src.p, gen.p), gen.vf ~ gen.vf0, gen.pm ~ gen.pm0], t, [], [];
        systems = [src, gen])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 0.5))
    integ = init(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)   # runs the DAE initialization

    # closed-form parameters vs OpenModelica
    @test integ.ps[sys.gen.delta0] ≈ om.delta atol = 1e-9
    @test integ.ps[sys.gen.e1q0] ≈ om.e1q atol = 1e-9
    @test integ.ps[sys.gen.e1d0] ≈ om.e1d atol = 1e-9
    @test integ.ps[sys.gen.vf00] ≈ om.vf atol = 1e-9
    @test integ.ps[sys.gen.id0] ≈ om.id atol = 1e-9
    @test integ.ps[sys.gen.iq0] ≈ om.iq atol = 1e-9
    @test integ.ps[sys.gen.pm00] ≈ 1.629999999999999 atol = 1e-9   # ra = 0: pm00 = p0 (pm is an alias in the OM CSV)

    # initial point (states and algebraic variables solved by ModelingToolkit)
    @test integ[sys.gen.delta] ≈ om.delta atol = 1e-9
    @test integ[sys.gen.w] ≈ 1
    @test integ[sys.gen.e1q] ≈ om.e1q atol = 1e-9
    @test integ[sys.gen.e1d] ≈ om.e1d atol = 1e-9
    @test integ[sys.gen.id] ≈ om.id atol = 1e-9
    @test integ[sys.gen.iq] ≈ om.iq atol = 1e-9
    @test integ[sys.gen.vf] ≈ om.vf atol = 1e-9
    @test integ[sys.gen.P] ≈ 1.629999999999999 atol = 1e-9
    @test integ[sys.gen.Q] ≈ 0.066536560198189 atol = 1e-9
    @test integ[sys.gen.v] ≈ v_0 atol = 1e-9
    for var in (sys.gen.delta, sys.gen.w, sys.gen.e1q)
        @test abs(initial_derivative(integ, sys, var)) < 1e-9
    end
    @test initial_derivative(integ, sys, sys.gen.e1d) ≈ -om.e1d / 0.5350 atol = 1e-9

    sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.5; idxs = sys.gen.e1d) ≈ om.e1d * exp(-0.5 / 0.5350) atol = 1e-6
end
