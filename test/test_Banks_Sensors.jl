# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Shunt, PwCapacitorBank, PwCurrent, PwVoltage (PLAN-02).
# Fixed voltage (1, 0) -> PwCurrent (p -> n) -> Shunt(G = 0.1, B = 0.5) and PwVoltage at the sensor's n:
#   shunt.p.ir = G*1 - B*0 = 0.1, shunt.p.ii = B*1 + G*0 = 0.5; the sensor reads ir = 0.1, ii = 0.5, i = sqrt(0.26);
#   PwVoltage: vr = 1, vi = 0, v = 1, no current. PwCapacitorBank(G = 0.1, B = 0.5) with 0.3 + 0.1j injected:
#   vr = (0.3*0.1 + 0.1*0.5)/0.26 = 0.08/0.26, vi = (-0.3*0.5 + 0.1*0.1)/0.26 = -0.14/0.26.
@testset "Banks and sensors" begin
    @named src = FixedVoltageSource(; vr = 1.0, vi = 0.0)
    @named cs = PwCurrent()
    @named sh = Shunt(; G = 0.1, B = 0.5)
    @named vs = PwVoltage()
    @named rig = System(Equation[connect(src.p, cs.p), connect(cs.n, sh.p), connect(cs.n, vs.p)], t, [], [];
        systems = [src, cs, sh, vs])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.sh.p.ir] ≈ 0.1 atol = 1e-9
    @test integ[sys.sh.p.ii] ≈ 0.5 atol = 1e-9
    @test integ[sys.sh.v] ≈ 1.0 atol = 1e-9
    @test integ[sys.cs.ir] ≈ 0.1 atol = 1e-9
    @test integ[sys.cs.ii] ≈ 0.5 atol = 1e-9
    @test integ[sys.cs.i] ≈ sqrt(0.26) atol = 1e-9
    @test integ[sys.vs.vr] ≈ 1.0 atol = 1e-9
    @test integ[sys.vs.vi] ≈ 0.0 atol = 1e-9
    @test integ[sys.vs.v] ≈ 1.0 atol = 1e-9
    @test integ[sys.vs.p.ir] ≈ 0.0 atol = 1e-9

    @named cb = PwCapacitorBank(; nsteps = 1, G = 0.1, B = 0.5)
    @named inj = CurrentInjection(; ir = 0.3, ii = 0.1)
    @named rig2 = System(Equation[connect(cb.p, inj.p)], t, [], []; systems = [cb, inj])
    sys2 = mtkcompile(rig2)
    integ2 = init(ODEProblem(sys2, [], (0.0, 1.0)), Rodas5P())
    @test integ2[sys2.cb.p.vr] ≈ 0.08 / 0.26 atol = 1e-9
    @test integ2[sys2.cb.p.vi] ≈ -0.14 / 0.26 atol = 1e-9
end

# PwShunt and the two branches of the PSS/E SVC's inner Relay3 (batch 12, PLAN-12 phase 5), which the Test of the
# SVC cannot reach: on the SMIB the voltage error |Vref - |V|| stays far under Vov = 0.5 pu and the relay never
# leaves its middle branch (F-90). With the bus voltage held at 0.4 pu the error is +0.6 > Vov and the relay
# passes `u3 = var_C`; at 1.6 pu it is -0.6 < -Vov and the relay passes `u4 = var_R`. The Test's own
# parameterization is used (Sbase = 1, so the relay output IS the per-unit reactive power).
#
# PwShunt alone at Q = 0.2 pu on a 1 pu voltage: the shunt is capacitive, the current leads the voltage by 90
# degrees and its magnitude is Q/v = 0.2, so (ir, ii) = (0, 0.2) and c = Q/(v^2 2 pi f) = 0.2/(100 pi) = 6.366e-4.
# At Q = -0.2 it is inductive, the current lags, (ir, ii) = (0, -0.2), and l = v^2/(2 pi f |Q|) = 1/(20 pi).
@testset "PwShunt and the SVC relay branches" begin
    for (Q, sgn) in ((0.2, +1), (-0.2, -1))
        @named sh = PwShunt()
        @named src = FixedVoltageSource(; vr = 1.0, vi = 0.0)
        @named rig = System(Equation[connect(src.p, sh.p), sh.Q ~ Q], t, [], []; systems = [sh, src])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
        @test integ[sys.sh.p.ir] ≈ 0 atol = 1e-9
        @test integ[sys.sh.p.ii] ≈ sgn * 0.2 atol = 1e-9
        @test integ[sys.sh.i] ≈ 0.2 atol = 1e-9
        @test integ[sys.sh.anglei] ≈ sgn * pi / 2 atol = 1e-9
        @test integ[sys.sh.c] ≈ (sgn > 0 ? 0.2 / (100pi) : 0) atol = 1e-12
        @test integ[sys.sh.l] ≈ (sgn > 0 ? 0 : 1 / (20pi)) atol = 1e-9
    end
    for (vr, expected) in ((0.4, -0.1), (1.6, 0.1))     # var_C = -0.1 above +Vov, var_R = 0.1 below -Vov
        @named svc = SVC(; Vref = 1, Bref = 0, K = 150, T1 = 0.5, T2 = 0.1, T3 = 0.05, T4 = 0.01, T5 = 0.03,
            Vmax = 0.1, Vmin = -0.1, Vov = 0.5, Sbase = 1, init_SVC_Leadlag = 0, init_SVC_Lag = -0.01,
            OtherSignals = 0, var_C = -0.1, var_R = 0.1)
        @named src = FixedVoltageSource(; vr = vr, vi = 0.0)
        @named rig = System(Equation[connect(src.p, svc.VIB)], t, [], []; systems = [svc, src])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
        @test integ[sys.svc.add.y] ≈ 1 - vr atol = 1e-9            # Verr = Vref - |V|
        @test integ[sys.svc.imRelay.y] ≈ expected atol = 1e-9
        @test integ[sys.svc.shunt.Q] ≈ expected atol = 1e-9        # Sbase = 1: the gain is unity
    end
end
