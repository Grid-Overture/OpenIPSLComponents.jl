# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# CIM5 (batch 3) has no Test in OpenIPSL 3.1.0 (its only user is Examples.Microgrids.IEEEMicrogrid, batch 7), so it
# is validated by hand. The motor hangs on an ideal 1 angle 0 source, with the .mo defaults (Mtype = 1, R2 = X2 = 0,
# i.e. single cage) and Ctrl = false (no VSD input; we_source_fix drives we_fix).
#
# (1) Sup = false: OpenIPSL's own steady-state initialization (`der(s) = der(Ekr) = der(Eki) = der(Epr) = der(Epi) = 0`).
#     The five derivatives must vanish at t = 0, and the mechanical balance of the model gives Te_motor = TL exactly
#     (`der(s) = (TL - Te_motor)/(2H)`), with TL = T_nom*(1 - s)^D. A motor draws active power and, being inductive,
#     also reactive power: P > 0, Q > 0 with the sign convention of baseMotor (Q = -p.vr*p.ii + p.vi*p.ir with the
#     pin current flowing into the component). The slip of a loaded induction motor is small and positive.
# (2) Sup = true: the start-up branch fixes only the slip at 1 - eps; the four flux states have no initial equation,
#     so the test pins them as OpenModelica would (F-28) - but not at their `start` of exactly 0: `Epp =
#     sqrt(Eppr^2 + Eppi^2)` has the derivative Eppr/Epp = 0/0 at the origin, so the Jacobian of the model is NaN
#     there and any solver aborts at the first step (F-35). They start at 1e-3, deep inside the unsaturated region
#     (SE returns 0 below 0.919 pu with these coefficients), which is the same operating branch. After 3 s the motor
#     must have reached the steady state of (1).
@testset "CIM5" begin
    @component function motor_case(; name, Sup)
        systems = @named begin
            src = FixedVoltageSource(; vr = 1.0, vi = 0.0)
            m = CIM5(; Sup, Ctrl = false, M_b = 15e6, S_b = 100e6)
        end
        System([connect(m.p, src.p)], t, [], []; name, systems)
    end

    # (1) steady state
    @named c1 = motor_case(; Sup = false)
    s1 = mtkcompile(c1)
    p1 = ODEProblem(s1, [], (0.0, 1.0))
    i1 = init(p1, Rodas5P(); initializealg = INIT)
    for v in (s1.m.s, s1.m.Ekr, s1.m.Eki, s1.m.Epr, s1.m.Epi)
        @test abs(initial_derivative(i1, s1, v)) < 1e-9
    end
    slip = i1[s1.m.s]
    @test 0 < slip < 0.1
    @test isapprox(i1[s1.m.Te_motor], i1[s1.m.TL]; atol = 1e-9)
    @test isapprox(i1[s1.m.TL], 1.0 * (1 - slip)^1.0; atol = 1e-12)   # TL = T_nom*(1 - s)^D
    @test i1[s1.m.P] > 0
    @test i1[s1.m.Q] > 0

    # (2) start-up from standstill reaches the same operating point
    @named c2 = motor_case(; Sup = true)
    s2 = mtkcompile(c2)
    p2 = ODEProblem(s2, [s2.m.Ekr => 1e-3, s2.m.Eki => 1e-3, s2.m.Epr => 1e-3, s2.m.Epi => 1e-3], (0.0, 3.0))
    sol2 = solve(p2, Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
    @test sol2.retcode == ReturnCode.Success
    @test isapprox(sol2(0.0; idxs = s2.m.s), 1 - 1e-15; atol = 1e-12)
    @test isapprox(sol2(3.0; idxs = s2.m.s), slip; atol = 1e-3)
    println("  CIM5: steady-state slip = ", round(slip; sigdigits = 6), ", after start-up = ",
        round(sol2(3.0; idxs = s2.m.s); sigdigits = 6))
end
