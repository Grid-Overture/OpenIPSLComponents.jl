# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Banks/PSSE/SVC.mo (a Test of this port, not OpenIPSL's: PLAN-12, family D), transcribed by
# the transcriber (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The rig of Tests.Banks.PSSE.CSVGN1 with the SVC in place of the static compensator on SHUNT. Four of its
# parameters are this port's against the .mo's own defaults, and each for a reason OpenModelica made unavoidable
# (F-90): `var_C < var_R`, because the model hands SimpleLagLim its two limits swapped and outMax < outMin makes
# the limiter's reinit clauses fire alternately at t = 0; `Sbase = 1`, the only reading under which the three
# branches of the inner Relay3 carry the same quantity, so that var_C, var_R and [Vmin, Vmax] are all per unit on
# the system base (a +/- 10 Mvar compensator); and `init_SVC_Lag = -0.01` rather than 0, because the bridge feeds
# PwShunt, whose atan2(p.ii, p.ir) is undefined at exactly zero reactive power. So parameterized the SVC holds
# SHUNT.v at Vref within Vmax/K and saturates during the fault. `SVC` is the model, so the Test function takes
# the suffix _Test (PLAN-02 rule).
@component function SVC_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1, SHUNT = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 4402877.0, v_0 = 1.0, S_b, fn)
        sVC = SVC(; Vref = 1.0, Bref = 0.0, K = 150.0, T1 = 0.5, T2 = 0.1, T3 = 0.05, T4 = 0.01, T5 = 0.03, Vmax = 0.1, Vmin = -0.1, Vov = 0.5, Sbase = 1.0, init_SVC_Leadlag = 0.0, init_SVC_Lag = -0.01, OtherSignals = 0.0, var_C = -0.1, var_R = 0.1)
    end
    eqs = Equation[
        gENSAL.PMECH ~ gENSAL.PMECH0,   # connect(gENSAL.PMECH, gENSAL.PMECH0)
        gENSAL.EFD ~ gENSAL.EFD0,   # connect(gENSAL.EFD, gENSAL.EFD0)
        connect(gENSAL.p, GEN1.p),
        connect(sVC.VIB, SHUNT.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Banks.PSSE.SVC" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Banks.PSSE.SVC.jl"))
    validate_against_oracle(SVC_Test, oracle)
end
