# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Machines/PSSE/GEN.mo, transcribed by hand (2026-09-14).
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The .mo carries the four `redeclare`s in the *instance* modifier of `Plant G1(...)`, which the transcriber does not
# emit: they are written here as the `mods` keyword of Plant (PLAN-03). The .mo has no `experiment` annotation, so
# OpenModelica used its defaults (1 s, tol 1e-6, 500 intervals) and the oracle records them.
@component function GEN_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        G1 = Plant(; mods = (;
                machine = (; redeclare = GENROE, Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0,
                    Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39,
                    angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, Xpq = 2.0, Tpq0 = 2.0, M_b = 100000000.0,
                    P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0),
                governor = (; redeclare = ConstantPower),
                exciter = (; redeclare = ConstantExcitation),
                pss = (; redeclare = DisabledPSS)),
            S_b, fn)
    end
    eqs = Equation[
        connect(G1.pwPin, GEN1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Machines.PSSE.GEN" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Machines.PSSE.GEN.jl"))
    validate_against_oracle(GEN_Test, oracle)
end
