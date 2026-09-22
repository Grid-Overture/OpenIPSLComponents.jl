# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Electrical.Wind.PSSE.WT4G.WT4E1 (PLAN-08, batch 8). Tests.Wind.PSSE.WT4G.WT4E1 does not translate in OpenModelica
# 1.25 (F-70: the Pantelides index reduction fails on WT4E1's `initial equation`), so there is no oracle and the
# Test is not transcribed to test/Tests/. Its network is built here instead (the WT4G1 Test's SMIB, the same wT4G1,
# plus wT4E1 with the Test's data; transcribed from Tests/Wind/PSSE/WT4G/WT4E1.mo automatically (test kind),
# 2026-09-19, reviewed by hand) and validated by hand:
# (1) at t = 0 it is the operating point of the WT4G1 Test: every variable of the WT4G1 oracle's row 0 (39, with the
#     Is.re/Is.im renames) to 1e-6 -- WIQCMD(0) = k70 = q0/v0 and WIPCMD(0) = p0/v0 differ from WT4G1's Iy0 = q0 and
#     Ix0 by q0 (1/v0 - 1) = 6e-9 and 1.5e-9 (the Test's v_0 = 0.9999999, sic);
# (2) it stays at rest until the fault (GEN1.v, P, Q at 1.9 s equal to t = 0 to 1e-6) and rides through it (2.00-2.15 s:
#     GEN1.v = 0.911 at 2.1 s, the reactive command on its Q-priority limit: WIQCMD = cCL.IQmax = 0.579) back to rest
#     at 10 s (GEN1.v = 1, P and Q at their t = 0 values to 1e-4; the return needs the discrete fallback of
#     `IntegratorLimVar`, F-76: without it the emulator's integrator stayed above `outMax` after the clearing and the
#     plant settled at GEN1.v = 1.0945 on three limits);
# (3) with PFAFLG = true, PQFLAG = true and PSSEMATCH = false the point is the same (Qord.u = q0 by both routes,
#     the P-priority limits, the emulator's integrator fed by the voltage error).
# The reactive loop with the shipped Kpv = 18 is stable here (unlike the Renewables plants of F-64): the pre-fault
# rest and the return after the fault are asserted, not just the point.
include(joinpath(@__DIR__, "test_WT4E1_component.jl"))

@testset "Wind.PSSE.WT4G.WT4E1 on the WT4E1 Test network (no oracle, F-70)" begin
    oracle = include(joinpath(@__DIR__, "oracle", "Wind.PSSE.WT4G.WT4G1.jl"))
    rename = Dict("wT4G1.Is.re" => "wT4G1.Is_re", "wT4G1.Is.im" => "wT4G1.Is_im")
    @named model = WT4E1_Test()
    sys = mtkcompile(model)
    prob = ODEProblem(sys, [], (0.0, 10.0))
    integ = init(prob, Rodas5P(); initializealg = OverrideInit(; abstol = 1e-12, reltol = 1e-12, nlsolve = NewtonRaphson()))
    worst = ("", 0.0)
    for (name, om) in sort(collect(oracle.vars); by = first)
        var = foldl(resolve_path_part, split(get(rename, name, name), "."); init = sys)
        err = abs(integ[var] - om[1])
        err > worst[2] && (worst = (name, err))
        @test err <= 1e-6
    end
    println("  WT4E1 on the WT4G1 point: $(length(oracle.vars)) variables, worst $(worst[1]) |Δ| = $(round(worst[2]; sigdigits = 3)) (limit 1e-6)")
    p0, q0, v0 = integ[sys.wT4G1.P], integ[sys.wT4G1.Q], integ[sys.wT4G1.V]
    @test integ[sys.wT4E1.WIQCMD] ≈ q0 / v0 atol = 1e-9
    @test integ[sys.wT4E1.WIPCMD] ≈ p0 / v0 atol = 1e-9
    @test integ.ps[sys.wT4E1.p0] ≈ p0 atol = 1e-12
    @test integ.ps[sys.wT4E1.q0] ≈ q0 atol = 1e-12
    @test integ.ps[sys.wT4E1.v0] ≈ v0 atol = 1e-12
    @test integ[sys.wT4E1.cCL.IQmax] ≈ 0.48 atol = 1e-6   # min(Iqhl, (0.48 - 1.6)(v0 - 1) + 0.48, ImaxTD) at v0 = 1
    @test integ[sys.wT4E1.cCL.IPmax] ≈ 1.11 atol = 1e-9
    @test integ[sys.wT4E1.windControlEmulator1.integrator.y] ≈ q0 atol = 1e-9   # k10, frozen by PSSEMATCH

    own = prob.kwargs[:tstops]
    own = own isa AbstractVector ? own : own(prob.p, prob.tspan)
    sol = solve(prob, Rodas5P(); abstol = 1e-6, reltol = 1e-6, tstops = sort(unique([own; [1.9, 2.1, 10.0]])),
        saveat = [0.0, 1.9, 2.1, 5.0, 10.0], initializealg = INIT)
    @test sol.retcode == ReturnCode.Success
    for v in (sys.GEN1.v, sys.wT4G1.P, sys.wT4G1.Q, sys.wT4E1.WIQCMD, sys.wT4E1.WIPCMD)
        @test sol(1.9; idxs = v) ≈ sol(0.0; idxs = v) atol = 1e-6
    end
    @test sol(2.1; idxs = sys.GEN1.v) < 0.95
    @test abs(sol(2.1; idxs = sys.wT4E1.WIQCMD)) <= sol(2.1; idxs = sys.wT4E1.cCL.IQmax) + 1e-9   # on the limit
    @test sol(10.0; idxs = sys.GEN1.v) ≈ sol(0.0; idxs = sys.GEN1.v) atol = 1e-4
    @test sol(10.0; idxs = sys.wT4G1.P) ≈ sol(0.0; idxs = sys.wT4G1.P) atol = 1e-4
    @test sol(10.0; idxs = sys.wT4G1.Q) ≈ sol(0.0; idxs = sys.wT4G1.Q) atol = 1e-4

    @named model2 = WT4E1_Test(; PFAFLG = true, PQFLAG = true, PSSEMATCH = false)
    sys2 = mtkcompile(model2)
    integ2 = init(ODEProblem(sys2, [], (0.0, 10.0)), Rodas5P(); initializealg = OverrideInit(; abstol = 1e-12, reltol = 1e-12, nlsolve = NewtonRaphson()))
    @test integ2[sys2.wT4E1.WIQCMD] ≈ q0 / v0 atol = 1e-6
    @test integ2[sys2.wT4E1.WIPCMD] ≈ p0 / v0 atol = 1e-6
    @test integ2[sys2.wT4E1.Qord.u] ≈ q0 atol = 1e-6            # switch_QREF -> PF_Controller.Q_REF_PF = tan(atan2(q0, p0)) p0
    @test integ2[sys2.wT4E1.PF_Controller.Q_REF_PF] ≈ q0 atol = 1e-6
    @test integ2[sys2.wT4E1.cCL.IPmax] ≈ 1.11 atol = 1e-9        # P priority: min(Iphl, ImaxTD)
    @test integ2[sys2.wT4E1.cCL.IQmax] ≈ 0.48 atol = 1e-6         # min(sqrt(ImaxTD^2 - IpCMD^2), min(Iqhl, Iqmax))
    @test integ2[sys2.GEN1.v] ≈ v0 atol = 1e-6
end
