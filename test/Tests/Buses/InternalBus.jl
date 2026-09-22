# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Buses/InternalBus.mo (a Test of this port, not OpenIPSL's: PLAN-12, family F), transcribed
# automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The SMIB base and the machine of Tests.Machines.PSSE.GENSAL with the internal bus inserted between the machine
# and GEN1. The model is a change of base and nothing else, so M_b = 120 MVA against SysData's 100 MVA gives
# CoB = 1.2 and n.ir = -1.2 p.ir; the machine keeps M_b = 100 MVA because a PSS/E machine already converts its
# own current with its own CoB, and the base change measured here is the bus's. The declared operating point is
# therefore not an exact power flow and the run starts with a small transient (F-54).
# `InternalBus` is the model, so the Test function takes the suffix _Test (PLAN-02 rule).
@component function InternalBus_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        internalBus = InternalBus(; M_b = 120e6, S_b, fn)
    end
    eqs = Equation[
        gENSAL.PMECH ~ gENSAL.PMECH0,   # connect(gENSAL.PMECH, gENSAL.PMECH0)
        gENSAL.EFD ~ gENSAL.EFD0,   # connect(gENSAL.EFD, gENSAL.EFD0)
        connect(gENSAL.p, internalBus.p),
        connect(internalBus.n, GEN1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Buses.InternalBus" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "Buses.InternalBus.jl"))
    validate_against_oracle(InternalBus_Test, oracle)
end
