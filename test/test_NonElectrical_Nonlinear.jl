# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# NonElectrical.Nonlinear (PLAN-01). Input u = t - 1 over [0, 2] where a ramp is needed.
# Div0block(u1 = 1, u2 = 0) = 1e60 (the Div0Block Test of OpenIPSL says the same); (3, 2) = 1.5.
# CeilingBlock(Ae = 0.0039, Be = 1.555) at u = 1.789323314329605 (gen1's vf00): 0.0039*exp(1.555*1.7893)*1.7893 =
#   the batch-0 value 1.902077693650219 - 1*1.789323314329605 = 0.112754379320614 (vr10 - Ke vf00 of F-10).
# FEX: u = -0.5 -> 1; u = 0.2 -> 1 - 0.577*0.2 = 0.8846; u = 0.6 -> sqrt(0.75 - 0.36) = 0.6244997998398398;
#   u = 0.9 -> 1.732*0.1 = 0.1732; u = 1.5 -> 0.
# Deadband1(db = 0.1, err = 0.05): u = 0.3 -> 0.25; u = -0.3 -> -0.25; u = 0.05 -> 0. With err = 0: u = 0.3 -> 0.2.
# Deadband2(db = 0.1): `when u > pre(y) + db then y := u - db` fires at the crossing, where u - db = pre(y): with a
#   smooth ramp the assignment is a no-op and y stays 0 at the located root (Modelica's event iteration on the same
#   `when` is settled against OpenModelica by the Test of the model that instantiates the block, PLAN-01).
@testset "NonElectrical.Nonlinear" begin
    @named d0 = Div0block()
    @named d0b = Div0block()
    @named ceil = CeilingBlock(; Ae = 0.0039, Be = 1.555)
    @named fex = FEX()
    @named db1 = Deadband1(; db = 0.1, err = 0.05)
    @named db1z = Deadband1(; db = 0.1, err = 0)
    @named rig = System(Equation[d0.u1 ~ 1, d0.u2 ~ 0, d0b.u1 ~ 3, d0b.u2 ~ 2, ceil.u ~ 1.789323314329605,
            fex.u ~ t - 1, db1.u ~ t - 1, db1z.u ~ t - 1], t, [], []; systems = [d0, d0b, ceil, fex, db1, db1z])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 2.5)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.0; idxs = sys.d0.y) ≈ 1e60
    @test sol(0.0; idxs = sys.d0b.y) ≈ 1.5 atol = 1e-9
    @test sol(0.0; idxs = sys.ceil.y) ≈ 0.112754379320614 atol = 1e-9
    @test sol(0.5; idxs = sys.fex.y) ≈ 1 atol = 1e-9
    @test sol(1.2; idxs = sys.fex.y) ≈ 0.8846 atol = 1e-9
    @test sol(1.6; idxs = sys.fex.y) ≈ 0.6244997998398398 atol = 1e-9
    @test sol(1.9; idxs = sys.fex.y) ≈ 0.1732 atol = 1e-9
    @test sol(2.5; idxs = sys.fex.y) ≈ 0 atol = 1e-9
    @test sol(1.3; idxs = sys.db1.y) ≈ 0.25 atol = 1e-9
    @test sol(0.7; idxs = sys.db1.y) ≈ -0.25 atol = 1e-9
    @test sol(1.05; idxs = sys.db1.y) ≈ 0 atol = 1e-9
    @test sol(1.3; idxs = sys.db1z.y) ≈ 0.2 atol = 1e-9

    @named db2 = Deadband2(; db = 0.1)
    @variables x(t) = 0.0
    @named rig2 = System(Equation[db2.u ~ t - 1, D_nounits(x) ~ db2.y], t, [x], []; systems = [db2])
    sys2 = mtkcompile(rig2)
    sol2 = solve(ODEProblem(sys2, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol2.retcode == ReturnCode.Success
    @test sol2(0.5; idxs = sys2.db2.y) ≈ 0 atol = 1e-9
    @test sol2(1.5; idxs = sys2.db2.y) ≈ 0 atol = 1e-6
    @test sol2(2.0; idxs = sys2.db2.y) ≈ 0 atol = 1e-6
end
