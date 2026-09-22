# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Gen1, Gen2 and Gen3 on a fixed source at their power-flow voltage: the closed-form initialization
# (delta0, e1q0, e1d0, vf00, pm00, vr10, vref0) and the initial point must match the OpenModelica row t = 0.
# OM's initialization is under-determined ("initial conditions are not fully specified") and Example_3's power-flow
# data are consistent only to ~1e-6, so OM's t = 0 values of gen2/gen3 deviate up to 3e-6 from the closed form
# while gen1 matches to machine precision (F-11). The residuals of all states but e1d vanish at t = 0; e1d decays
# from e1d0 with T1q0 (F-04). The disturbance path (step -> switch1, refdisturb = false) leaves AVR.vref on
# AVR.vref0, so the same assertions hold as when the three groups were one flattened model (batch 0).
@testset "Gen1/Gen2/Gen3" begin
    S_b = 100e6
    disturb = (height = 0.05, tstart = 2.0, refdisturb = false)   # Example_3's values
    cases = [
        ("gen1", Gen1, (V_b = 18000, v_0 = 1.025, angle_0 = 0.161966652912444, P_0 = 1.629999999999999 * S_b,
            Q_0 = 0.066536560198189 * S_b, vref0 = 1.120103884682511, vf0 = 1.789323314329606), 0.5350, 1e-9),
        ("gen2", Gen2, (V_b = 13800, v_0 = 1.025, angle_0 = 0.081415270775183, P_0 = 0.850000000000000 * S_b,
            Q_0 = -0.108597088920594 * S_b, vref0 = 1.097573933623472, vf0 = 1.402994304406186), 0.6, 5e-6),
        ("gen3", Gen3, (V_b = 16500, v_0 = 1.040000000000000, angle_0 = 0, P_0 = 0.716410214993680 * S_b,
            Q_0 = 0.270459279594234 * S_b, vref0 = 1.095242742681042, vf0 = 1.082148046273888), 0.310, 5e-6),
    ]
    for (label, ctor, kw, T1q0, tol) in cases
        @testset "$label" begin
            om = OM_T0[label]
            @named src = FixedVoltageSource(; vr = kw.v_0 * cos(kw.angle_0), vi = kw.v_0 * sin(kw.angle_0))
            @named G = ctor(; S_b = S_b, fn = 60, kw..., disturb...)
            @named rig = System(Equation[connect(src.p, G.pwPin)], t, [], []; systems = [src, G])
            sys = mtkcompile(rig)
            prob = ODEProblem(sys, [], (0.0, 1.0))
            integ = init(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)   # runs the DAE initialization
            # closed-form initialization vs OM
            @test integ.ps[sys.G.gen.delta0] ≈ om.delta atol = tol
            @test integ.ps[sys.G.gen.e1q0] ≈ om.e1q atol = tol
            @test integ.ps[sys.G.gen.e1d0] ≈ om.e1d atol = tol
            @test integ.ps[sys.G.gen.vf00] ≈ om.vf atol = 1e-9
            @test integ.ps[sys.G.gen.pm00] ≈ kw.P_0 / S_b atol = 1e-9
            @test integ.ps[sys.G.AVR.vr10] ≈ om.state atol = 1e-9
            @test integ[sys.G.AVR.vref0] ≈ om.vref atol = 1e-9
            # initial point
            @test integ[sys.G.gen.delta] ≈ om.delta atol = tol
            @test integ[sys.G.gen.e1q] ≈ om.e1q atol = tol
            @test integ[sys.G.gen.e1d] ≈ om.e1d atol = tol
            @test integ[sys.G.gen.id] ≈ om.id atol = tol
            @test integ[sys.G.gen.iq] ≈ om.iq atol = tol
            @test integ[sys.G.gen.vf] ≈ om.vf atol = 1e-9
            @test integ[sys.G.AVR.simpleLagLim.state] ≈ om.state atol = 1e-9
            @test integ[sys.G.AVR.vref] ≈ om.vref atol = 1e-9
            @test integ[sys.G.P] ≈ kw.P_0 atol = 1e-3
            @test integ[sys.G.Q] ≈ kw.Q_0 atol = 1e-3
            for var in (sys.G.gen.delta, sys.G.gen.w, sys.G.gen.e1q, sys.G.AVR.firstOrder2.y,
                sys.G.AVR.simpleLagLim.state, sys.G.AVR.derivativeBlock.x, sys.G.AVR.vf)
                @test abs(initial_derivative(integ, sys, var)) < 1e-9
            end
            @test initial_derivative(integ, sys, sys.G.gen.e1d) ≈ -integ.ps[sys.G.gen.e1d0] / T1q0 atol = 1e-9
        end
    end
end
