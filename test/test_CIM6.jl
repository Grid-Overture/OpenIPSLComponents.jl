# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# CIM6 (batch 12) has a Test of this port's own on the SMIB (Tests/Machines/PSSE/CIM6.jl), and that Test takes the
# only two flags a network Test can take: `Sup = false` (steady-state initialization) and `Ctrl = false` (no VSD
# input). The two `true` sides are covered here, as test_CIM5.jl covers them for the sibling model, on an ideal
# 1 angle 0 source with the .mo's electrical defaults (Mtype = 1, R2 = X2 = 0, i.e. single cage).
#
# The load-torque characteristic is the only thing CIM6 adds to CIM5: TL = T_nom*(A w^2 + B w + C0 + D w^E) against
# CIM5's T_nom*(1 - s)^D. The defaults T_nom = A = B = C0 = D = E = 1 give TL = 4 pu at w = 1, four times the motor
# rating, and no steady state exists anywhere near rated speed (F-90); that is reproduced, not fixed, so the cases
# below use the quadratic characteristic this port's Test uses (A = 1, B = C0 = D = 0, T_nom = 0.6) and one case
# checks the shipped formula itself at a known speed.
#
# (1) Sup = true: the start-up branch fixes only the slip at 1 - eps; the four flux states have no initial equation,
#     so they are pinned at 1e-3 rather than at their `start` of exactly 0, where `Epp = sqrt(Eppr^2 + Eppi^2)` has
#     a NaN derivative and any solver aborts at the first step (F-35, as in test_CIM5.jl). After 3 s the motor must
#     have reached the steady state that `Sup = false` finds directly.
# (2) Ctrl = true: the synchronous speed comes from the `we` input instead of from w_b. Driven at exactly w_b the
#     model must reproduce the `Ctrl = false` operating point; the four reactances are then scaled by
#     we_fix.y/w_b = 1 and `P = Te_sys*nr/w_b` instead of `P = Te_sys`.
# (3) the load-torque formula, evaluated on the model's own variables at the steady state it reaches.
@testset "CIM6" begin
    # a tighter Newton than `INIT`'s default: what is checked at t = 0 is a residual, and with this torque
    # characteristic the default stops at about 1e-7 (the same pattern as `validate_operating_point`)
    TIGHT = OverrideInit(; abstol = 1e-12, reltol = 1e-12, nlsolve = NewtonRaphson())
    @component function motor6(; name, Sup, Ctrl, we = nothing)
        systems = @named begin
            src = FixedVoltageSource(; vr = 1.0, vi = 0.0)
            m = CIM6(; Sup, Ctrl, M_b = 15e6, S_b = 100e6, T_nom = 0.6, A = 1, B = 0, C0 = 0, D = 0, E = 2)
        end
        eqs = we === nothing ? Equation[connect(m.p, src.p)] : Equation[connect(m.p, src.p), m.we ~ we]
        System(eqs, t, [], []; name, systems)
    end

    # (1) steady state, then the same point reached from standstill
    @named c1 = motor6(; Sup = false, Ctrl = false)
    s1 = mtkcompile(c1)
    i1 = init(ODEProblem(s1, [], (0.0, 1.0)), Rodas5P(); initializealg = TIGHT)
    for v in (s1.m.s, s1.m.Ekr, s1.m.Eki, s1.m.Epr, s1.m.Epi)
        @test abs(initial_derivative(i1, s1, v)) < 1e-9
    end
    slip = i1[s1.m.s]
    @test 0 < slip < 0.1
    @test isapprox(i1[s1.m.Te_motor], i1[s1.m.TL]; atol = 1e-9)
    @test isapprox(i1[s1.m.TL], 0.6 * (1 - slip)^2; atol = 1e-12)   # (3) TL = T_nom*A*Omegar^2 with Omegar = 1 - s
    @test i1[s1.m.P] > 0
    @test i1[s1.m.Q] > 0

    @named c2 = motor6(; Sup = true, Ctrl = false)
    s2 = mtkcompile(c2)
    p2 = ODEProblem(s2, [s2.m.Ekr => 1e-3, s2.m.Eki => 1e-3, s2.m.Epr => 1e-3, s2.m.Epi => 1e-3], (0.0, 3.0))
    sol2 = solve(p2, Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
    @test sol2.retcode == ReturnCode.Success
    @test isapprox(sol2(0.0; idxs = s2.m.s), 1 - 1e-15; atol = 1e-12)
    @test isapprox(sol2(3.0; idxs = s2.m.s), slip; atol = 1e-3)

    # (2) the controllable synchronous speed, driven at exactly w_b
    @named c3 = motor6(; Sup = false, Ctrl = true, we = 2pi * 50)
    s3 = mtkcompile(c3)
    i3 = init(ODEProblem(s3, [], (0.0, 1.0)), Rodas5P(); initializealg = TIGHT)
    @test isapprox(i3[s3.m.s], slip; atol = 1e-9)
    @test isapprox(i3[s3.m.Xa_c], 0.0759; atol = 1e-12)             # we_fix.y/w_b = 1
    @test isapprox(i3[s3.m.P], i3[s3.m.Te_sys] * (1 - slip); atol = 1e-9)   # P = Te_sys*nr/w_b with Ctrl = true
    println("  CIM6: steady-state slip = ", round(slip; sigdigits = 6), ", after start-up = ",
        round(sol2(3.0; idxs = s2.m.s); sigdigits = 6), ", with Ctrl = true ", round(i3[s3.m.s]; sigdigits = 6))
end
