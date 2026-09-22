# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Loads/PSSE/Load_ExtInput.mo (a Test of this port, not OpenIPSL's: PLAN-12, family E),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The SMIB base and the machine of Tests.Machines.PSSE.GENSAL, as in the harness probe, with the load under test
# on the LOAD bus beside the base's own constantLoad and the operating point that bus declares. The model has two
# independent ways of changing its consumption and the Test makes their four combinations visible: the
# parameterized variation d_P in [t1, t1 + d_t] = [4, 6] s and the input `u`, stepped by 0.01 pu at 5 s.
# `Load_ExtInput` is the model, so the Test function takes the suffix _Test (PLAN-02 rule).
@component function Load_ExtInput_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1, LOAD = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        load_ExtInput = Load_ExtInput(; P_0 = 10000000.0, Q_0 = 2000000.0, v_0 = 0.9919935, angle_0 = -0.5762684, characteristic = 2, PQBRAK = 0.7, d_P = 0.05, t1 = 4.0, d_t = 2.0, S_b, fn)
        u = Step(; height = 0.01, startTime = 5)
    end
    eqs = Equation[
        gENSAL.PMECH ~ gENSAL.PMECH0,   # connect(gENSAL.PMECH, gENSAL.PMECH0)
        gENSAL.EFD ~ gENSAL.EFD0,   # connect(gENSAL.EFD, gENSAL.EFD0)
        connect(gENSAL.p, GEN1.p),
        connect(load_ExtInput.p, LOAD.p),
        u.y ~ load_ExtInput.u,   # connect(u.y, load_ExtInput.u)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Loads.PSSE.Load_ExtInput" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Loads.PSSE.Load_ExtInput.jl"))
    validate_against_oracle(Load_ExtInput_Test, oracle)
end
