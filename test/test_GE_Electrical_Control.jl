# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Electrical.Wind.GE.Type_3.Electrical_Control and Generator (PLAN-08, batch 8): lim_exc_s1, Electrical_Control,
# GE_Generator. None has an upstream Test of its own; GE_WT is exercised by Tests.Wind.GE.WT_Test against its oracle.

# lim_exc_s1(xiqmax = 0.4, xiqmin = -0.5). typpe = 1 (anti-windup gate) on (Efd, Vt, Vref): (1.5, 1, 0.2) -> Efd >=
# Vt + xiqmax and Vref >= 0 -> 0; (1.5, 1, -0.2) -> -0.2; (1.0, 1, 0.2) -> 0.2; (0.4, 1, -0.1) -> Efd <= Vt + xiqmin and
# Vref <= 0 -> 0. typpe = 2 (variable limiter of Vref) with Vt = 1: Vref = 1.6 -> 1.4; 0.3 -> 0.5; 1.0 -> 1.0.
# typpe = 3 -> 0.
@testset "Wind.GE.Type_3.Electrical_Control lim_exc_s1" begin
    cases = [(1, 1.5, 1.0, 0.2, 0.0), (1, 1.5, 1.0, -0.2, -0.2), (1, 1.0, 1.0, 0.2, 0.2), (1, 0.4, 1.0, -0.1, 0.0),
             (1, 1.4, 1.0, 0.2, 0.2), (1, 0.5, 1.0, -0.1, -0.1),   # exactly on a limit: no gate (F-77)
             (2, 0.0, 1.0, 1.6, 1.4), (2, 0.0, 1.0, 0.3, 0.5), (2, 0.0, 1.0, 1.0, 1.0), (3, 0.0, 1.0, 1.0, 0.0)]
    for (typpe, efd, vt, vref, y) in cases
        @named lim = lim_exc_s1(; typpe, xiqmax = 0.4, xiqmin = -0.5)
        @named rig = System(Equation[lim.Efd ~ efd, lim.Vt ~ vt, lim.Vref ~ vref], t, [], []; systems = [lim])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
        @test integ[sys.lim.y] ≈ y atol = 1e-12
    end
end

# Electrical_Control with the GE data (qmax = 0.312, qmin = -0.436, KQi = 0.1, KVi = 40, xiqmax = 0.4, xiqmin = -0.5)
# and the initial states of `ge_wt_init` (ex_x0_0 = _V0 = 1.03, ex_x1_0 = ge_x0_0 = 0.8701328020775211), fed with
# Qgen = Qord = qgen = -0.20582901732519165, Pord = 0.9, Vterm = 1.03: Ipcmd = Pord/Vterm = 0.8737864077669902,
# Efd = lim_exc_s12(integrator1.y = 0.8701, within Vt + xiqmin .. Vt + xiqmax) = 0.8701328020775211, limIntegrator1
# at rest (Qord - Qgen = 0) and integrator1 at rest (gain1 = KVi (1.03 - 1.03) = 0). With Pord = 1.5 the current
# command saturates at 1.1.
@testset "Wind.GE.Type_3.Electrical_Control Electrical_Control" begin
    qgen = -37049223.1185345 / 180e6
    @named ec = Electrical_Control(; qmax = 0.312, qmin = -0.436, KQi = 0.1, ex_x0_0 = 1.03, ex_x1_0 = 0.8701328020775211,
        KVi = 40, xiqmax = 0.4, xiqmin = -0.5)
    @named rig = System(Equation[ec.Qgen ~ qgen, ec.Qord ~ qgen, ec.Pord ~ 0.9, ec.Vterm ~ 1.03], t, [], []; systems = [ec])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ[sys.ec.Ipcmd] ≈ 0.9 / 1.03 atol = 1e-12
    @test integ[sys.ec.Efd] ≈ 0.8701328020775211 atol = 1e-12
    @test abs(initial_derivative(integ, sys, sys.ec.limIntegrator1.y)) < 1e-9
    @test abs(initial_derivative(integ, sys, sys.ec.integrator1.y)) < 1e-9
    @named ec2 = Electrical_Control(; qmax = 0.312, qmin = -0.436, KQi = 0.1, ex_x0_0 = 1.03, ex_x1_0 = 0.8701328020775211,
        KVi = 40, xiqmax = 0.4, xiqmin = -0.5)
    @named rig2 = System(Equation[ec2.Qgen ~ qgen, ec2.Qord ~ qgen, ec2.Pord ~ 1.5, ec2.Vterm ~ 1.03], t, [], []; systems = [ec2])
    sys2 = mtkcompile(rig2)
    integ2 = init(ODEProblem(sys2, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ2[sys2.ec2.Ipcmd] ≈ 1.1 atol = 1e-12
end

# GE_Generator (freq = 60, Kpllp = 30, Lpp = 0.8, GEN_base = 180e6, SYS_base = 100e6) on an ideal source at the GE
# power-flow point V = 1.03 at _Ang0 = 0.00735136412 rad, with Ipcmd = ge_x1_0 = _P0/GEN_base/_V0 =
# 0.8737864077669902 and Efd = ge_x0_0 = _V0 + _Q0/GEN_base Lpp/_V0 = 0.8701328020775211 (the states of
# `ge_wt_init`): with the PLL angle at the voltage angle, Pgen = Vt Ip = _P0/GEN_base = 0.9 and Qgen = Vt (E -
# Vt)/Lpp = _Q0/GEN_base = -0.20582901732519165 (in GEN_base); the pin absorbs -Pgen GEN_base/SYS_base = -1.62 in
# SYS_base; the PLL error add1 = Vt_im cos - sin Vt_re = 0 and the three integrators are at rest.
@testset "Wind.GE.Type_3.Generator GE_Generator" begin
    V0, A0 = 1.03, 0.00735136412
    ge_x0_0 = V0 + (-37049223.1185345 / 180e6) * 0.8 / V0
    ge_x1_0 = 162e6 / 180e6 / V0
    @named src = FixedVoltageSource(; vr = V0 * cos(A0), vi = V0 * sin(A0))
    @named gen = GE_Generator(; freq = 60, ge_x0_0, ge_x1_0, ge_x2_0 = A0, GEN_base = 180e6, Kpllp = 30, Lpp = 0.8, SYS_base = 100e6)
    @named rig = System(Equation[connect(src.p, gen.p), gen.Ipcmd ~ ge_x1_0, gen.Efd ~ ge_x0_0], t, [], []; systems = [src, gen])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ[sys.gen.Vt] ≈ V0 atol = 1e-12
    @test integ[sys.gen.Pgen] ≈ 0.9 atol = 1e-9
    @test integ[sys.gen.Qgen] ≈ -37049223.1185345 / 180e6 atol = 1e-9
    @test -(integ[sys.gen.p.vr] * integ[sys.gen.p.ir] + integ[sys.gen.p.vi] * integ[sys.gen.p.ii]) ≈ 0.9 * 1.8 atol = 1e-9
    @test integ[sys.gen.add1.y] ≈ 0.0 atol = 1e-12
    @test integ[sys.gen.Anglet] ≈ A0 atol = 1e-12
    for s in (sys.gen.integrator1.y, sys.gen.integrator2.y, sys.gen.integrator3.y)
        @test abs(initial_derivative(integ, sys, s)) < 1e-9
    end
end
