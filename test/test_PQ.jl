# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PQ and PQvar loads on a fixed source, and PwLine's opening (PLAN-00, Phase 0 step 5: pulled forward from batch 2
# because MachineTestBase instantiates them).
# PQ at v = 0.95 + 0.05j (|v|^2 = 0.905), P_0 = 8 MW, Q_0 = 6 Mvar on S_b = 100 MVA -> P = 0.08, Q = 0.06 pu;
#   ir = (P vr + Q vi)/|v|^2 = (0.076 + 0.003)/0.905 = 0.0872928176795580, ii = (P vi - Q vr)/|v|^2 = (0.004 - 0.057)/0.905
#   = -0.0585635359116022 (baseLoad convention: positive current into the load).
# PQvar with dP1 = 2 MW in [1, 2) s and dQ2 = -1 Mvar in [2, 3) s: P = 0.08 -> 0.10 -> 0.08, Q = 0.06 -> 0.06 -> 0.05.
# PwLine opening = 1 in [0.5, 1.0) s between two fixed sources: both pin currents vanish inside the window and are
# back to the closed-line values (test_PwLine.jl) outside it.
@testset "PQ, PQvar, PwLine opening" begin
    vr, vi = 0.95, 0.05
    @named src = FixedVoltageSource(; vr, vi)
    @named load = PQ(; P_0 = 8e6, Q_0 = 6e6, v_0 = 0.95, angle_0 = 0)
    @named rig = System(Equation[connect(src.p, load.p)], t, [], []; systems = [src, load])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-8, reltol = 1e-8)
    @test integ[sys.load.P] ≈ 0.08 atol = 1e-12
    @test integ[sys.load.Q] ≈ 0.06 atol = 1e-12
    @test integ[sys.load.v] ≈ sqrt(0.905) atol = 1e-12
    @test integ[sys.load.p.ir] ≈ 0.0872928176795580 atol = 1e-9
    @test integ[sys.load.p.ii] ≈ -0.0585635359116022 atol = 1e-9

    @named loadv = PQvar(; P_0 = 8e6, Q_0 = 6e6, v_0 = 0.95, dP1 = 2e6, dQ2 = -1e6)
    @named rigv = System(Equation[connect(src.p, loadv.p)], t, [], []; systems = [src, loadv])
    sysv = mtkcompile(rigv)
    solv = solve(ODEProblem(sysv, [], (0.0, 4.0)), Rodas5P(); abstol = 1e-8, reltol = 1e-8)
    @test solv.retcode == ReturnCode.Success
    @test solv(0.5; idxs = sysv.loadv.P) ≈ 0.08 atol = 1e-9
    @test solv(1.5; idxs = sysv.loadv.P) ≈ 0.10 atol = 1e-9
    @test solv(1.5; idxs = sysv.loadv.Q) ≈ 0.06 atol = 1e-9
    @test solv(2.5; idxs = sysv.loadv.P) ≈ 0.08 atol = 1e-9
    @test solv(2.5; idxs = sysv.loadv.Q) ≈ 0.05 atol = 1e-9
    @test solv(3.5; idxs = sysv.loadv.Q) ≈ 0.06 atol = 1e-9

    R, X, G, B = 0.02, 0.1, 0.01, 0.05
    vs, vrr = 1.0 + 0.0im, 0.95 - 0.05im
    is_closed = (vs - vrr) / complex(R, X) + vs * complex(G, B)
    @named src_s = FixedVoltageSource(; vr = real(vs), vi = imag(vs))
    @named src_r = FixedVoltageSource(; vr = real(vrr), vi = imag(vrr))
    @named line = PwLine(; R, X, G, B, t1 = 0.5, t2 = 1.0, opening = 1)
    @named rigl = System(Equation[connect(src_s.p, line.p), connect(src_r.p, line.n)], t, [], []; systems = [src_s, src_r, line])
    sysl = mtkcompile(rigl)
    soll = solve(ODEProblem(sysl, [], (0.0, 1.5)), Rodas5P(); abstol = 1e-8, reltol = 1e-8)
    @test soll.retcode == ReturnCode.Success
    @test soll(0.25; idxs = sysl.line.p.ir) ≈ real(is_closed) atol = 1e-9
    @test soll(0.75; idxs = sysl.line.p.ir) ≈ 0 atol = 1e-9
    @test soll(0.75; idxs = sysl.line.n.ii) ≈ 0 atol = 1e-9
    @test soll(1.25; idxs = sysl.line.p.ir) ≈ real(is_closed) atol = 1e-9
    @test soll(1.25; idxs = sysl.line.p.ii) ≈ imag(is_closed) atol = 1e-9
end
