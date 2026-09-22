# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Banks/PwShunt.mo (a Test of this port, not OpenIPSL's: PLAN-12, family D), transcribed by
# the transcriber (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The SMIB base and the machine of Tests.Machines.PSSE.GENSAL, as in the harness probe, with the shunt on SHUNT
# and its reactive power as a signal: a step from +0.1 to -0.1 pu at 5 s, i.e. 10 Mvar capacitive and then
# 10 Mvar inductive on the 100 MVA base, so both branches of the model's `if Q >= 0` and the crossing itself are
# inside the horizon. `PwShunt` is the model, so the Test function takes the suffix _Test (PLAN-02 rule).
@component function PwShunt_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1, SHUNT = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        pwShunt = PwShunt(; )
        Q = Step(; height = -0.2, offset = 0.1, startTime = 5)
    end
    eqs = Equation[
        gENSAL.PMECH ~ gENSAL.PMECH0,   # connect(gENSAL.PMECH, gENSAL.PMECH0)
        gENSAL.EFD ~ gENSAL.EFD0,   # connect(gENSAL.EFD, gENSAL.EFD0)
        connect(gENSAL.p, GEN1.p),
        connect(pwShunt.p, SHUNT.p),
        Q.y ~ pwShunt.Q,   # connect(Q.y, pwShunt.Q)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Banks.PwShunt" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "Banks.PwShunt.jl"))
    validate_against_oracle(PwShunt_Test, oracle)
end
