# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Machines/PSSE/GENCLS.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
@component function GENCLS_Test(; name, S_b = 100e6, fn = 50)   # `GENCLS` is the machine (PLAN-02: a Test named as its model gets the suffix _Test)
    @named base = SMIB(; S_b, fn, mods = (; GEN1 = (; v_0 = (1), angle_0 = (0.070492225331847))))
    @unpack GEN1 = base
    systems = @named begin
        gENCLS1 = GENCLS(; H = 6.0, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, angle_0 = 0.070492225331847, S_b, fn)
    end
    eqs = Equation[
        connect(gENCLS1.p, GEN1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Machines.PSSE.GENCLS" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Machines.PSSE.GENCLS.jl"))
    validate_against_oracle(GENCLS_Test, oracle)
end
