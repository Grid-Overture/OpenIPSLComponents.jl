# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Loads/PSAT/LoadTestPQ.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: BaseClasses.LoadTestBase. Omitted: graphical annotations, displayPF.
@component function LoadTestPQ(; name, S_b = 100e6, fn = 50)
    @named base = LoadTestBase(; S_b, fn)
    @unpack bus3 = base
    systems = @named begin
        pQ = PQ(; Sn = 10000000.0, P_0 = 800000.0, Q_0 = 600000.0, S_b, fn)
    end
    eqs = Equation[
        connect(bus3.p, pQ.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Loads.PSAT.LoadTestPQ" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Loads.PSAT.LoadTestPQ.jl"))
    # rtol 5e-3 (F-27): the undamped Order3 of LoadTestBase drifts after the pm pulse and the MTK-OM difference at 15 s
    # (1.5e-3 rad in pQ.anglev) is identical at abstol = reltol = 1e-8, i.e. the oracle's own floor
    validate_against_oracle(LoadTestPQ, oracle; rtol = 5e-3)
end
