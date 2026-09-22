# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Banks/PwCapacitorBankWithModification.mo (a Test of this port, not OpenIPSL's: PLAN-12,
# family D), transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The same base and machine as the PwShunt Test, with the bank on SHUNT: two 0.02 pu elements (about 4 Mvar at
# 1 pu) and one more switched in at t1 = 5 s, so the time event that changes `nt` and the admittance of the
# branch is inside the horizon, on top of the base's fault at 2 s. The model name is the Test's, so the function
# takes the suffix _Test (PLAN-02 rule).
@component function PwCapacitorBankWithModification_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1, SHUNT = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        pwCapacitorBankWithModification = PwCapacitorBankWithModification(; nsteps = 2, Go = 0.0, Bo = 0.02, t1 = 5.0, nmod = 1)
    end
    eqs = Equation[
        gENSAL.PMECH ~ gENSAL.PMECH0,   # connect(gENSAL.PMECH, gENSAL.PMECH0)
        gENSAL.EFD ~ gENSAL.EFD0,   # connect(gENSAL.EFD, gENSAL.EFD0)
        connect(gENSAL.p, GEN1.p),
        connect(pwCapacitorBankWithModification.p, SHUNT.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Banks.PwCapacitorBankWithModification" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "Banks.PwCapacitorBankWithModification.jl"))
    validate_against_oracle(PwCapacitorBankWithModification_Test, oracle)
end
