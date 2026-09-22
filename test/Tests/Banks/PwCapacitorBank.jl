# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Banks/PwCapacitorBank.mo (a Test of this port, not OpenIPSL's: PLAN-12, phase 0, the end-to-end
# probe of the PortTests harness), transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# OpenIPSL 3.1.0 has no Test that instantiates `Electrical.Banks.PwCapacitorBank` (batch 2, until now only in the
# hand test test_Banks_Sensors.jl). The network and the machine are those of Tests.Machines.PSSE.GENSAL; the bank sits
# on SHUNT with B = 0.05 pu (about 5 Mvar capacitive at 1 pu), so the declared power flow of the base is not an exact
# equilibrium and the run starts with a small transient, as any upstream Test whose flow does not square (F-54).
# `PwCapacitorBank` is the model (PLAN-02 rule: a Test named as its model gets the suffix _Test). The oracle is the
# DASSL run with the experiment's own options; its `origin` field says `PortTests`.
@component function PwCapacitorBank_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1, SHUNT = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        pwCapacitorBank = PwCapacitorBank(; nsteps = 1, G = 0.0, B = 0.05)
    end
    eqs = Equation[
        gENSAL.PMECH ~ gENSAL.PMECH0,   # connect(gENSAL.PMECH, gENSAL.PMECH0)
        gENSAL.EFD ~ gENSAL.EFD0,   # connect(gENSAL.EFD, gENSAL.EFD0)
        connect(gENSAL.p, GEN1.p),
        connect(pwCapacitorBank.p, SHUNT.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Banks.PwCapacitorBank" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "Banks.PwCapacitorBank.jl"))
    validate_against_oracle(PwCapacitorBank_Test, oracle)
end
