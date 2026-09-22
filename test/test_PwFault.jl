# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Fault (R = X = 0.01) on a fixed 1 pu source, t1 = 1 s, t2 = 2 s. Before t1 and from t2 the fault draws no current;
# inside [t1, t2) it draws  ir = (R vr + X vi)/(R^2 + X^2) = 0.01/0.0002 = 50,  ii = (R vi - X vr)/(R^2 + X^2) = -50.
@testset "PwFault" begin
    @named src = FixedVoltageSource(; vr = 1.0, vi = 0.0)
    @named fault = PwFault(; R = 0.01, X = 0.01, t1 = 1.0, t2 = 2.0)
    @named rig = System(Equation[connect(src.p, fault.p)], t, [], []; systems = [src, fault])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 3.0))
    sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)
    @test sol.retcode == ReturnCode.Success
    @test 1.0 in sol.t   # tstops registered by the component
    @test 2.0 in sol.t
    @test sol(0.5; idxs = sys.fault.p.ir) ≈ 0 atol = 1e-12
    @test sol(0.5; idxs = sys.fault.p.ii) ≈ 0 atol = 1e-12
    @test sol(1.5; idxs = sys.fault.p.ir) ≈ 50 atol = 1e-9
    @test sol(1.5; idxs = sys.fault.p.ii) ≈ -50 atol = 1e-9
    @test sol(2.5; idxs = sys.fault.p.ir) ≈ 0 atol = 1e-12
    @test sol(2.5; idxs = sys.fault.p.ii) ≈ 0 atol = 1e-12

    # events = false: `on` is left to the caller (segmented leg)
    @named fault_fixed = PwFault(; R = 0.01, X = 0.01, t1 = 1.0, t2 = 2.0, events = false)
    @named rig_fixed = System(Equation[connect(src.p, fault_fixed.p)], t, [], []; systems = [src, fault_fixed])
    sys_fixed = mtkcompile(rig_fixed)
    prob_on = ODEProblem(sys_fixed, [sys_fixed.fault_fixed.on => 1], (0.0, 3.0))
    sol_on = solve(prob_on, Rodas5P(); abstol = 1e-8, reltol = 1e-8)
    @test sol_on(0.5; idxs = sys_fixed.fault_fixed.p.ir) ≈ 50 atol = 1e-9
    @test sol_on(2.5; idxs = sys_fixed.fault_fixed.p.ir) ≈ 50 atol = 1e-9

    @test_throws ArgumentError PwFault(; name = :bolted, R = 0, X = 0, t1 = 1.0, t2 = 2.0)
end
