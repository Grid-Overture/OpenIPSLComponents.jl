# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Loads/PSSE/Load_switch.mo (a Test of this port, not OpenIPSL's: PLAN-12, family E),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The same base, machine and load parameters as the Load_ExtInput Test. The load is on only inside
# [t1, t2) = [4, 7) s and draws exactly zero current outside it, so what the Test exercises is a change in the
# structure of the algebraic system and not a coefficient in it; the run starts in the off state, which is what
# makes the first switching visible. `Load_switch` is the model, so the Test function takes the suffix _Test.
@component function Load_switch_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1, LOAD = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        load_switch = Load_switch(; P_0 = 10000000.0, Q_0 = 2000000.0, v_0 = 0.9919935, angle_0 = -0.5762684, characteristic = 2, PQBRAK = 0.7, t1 = 4.0, t2 = 7.0, S_b, fn)
    end
    eqs = Equation[
        gENSAL.PMECH ~ gENSAL.PMECH0,   # connect(gENSAL.PMECH, gENSAL.PMECH0)
        gENSAL.EFD ~ gENSAL.EFD0,   # connect(gENSAL.EFD, gENSAL.EFD0)
        connect(gENSAL.p, GEN1.p),
        connect(load_switch.p, LOAD.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Loads.PSSE.Load_switch" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Loads.PSSE.Load_switch.jl"))
    validate_against_oracle(Load_switch_Test, oracle)
end
