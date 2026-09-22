# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Loads/PSAT/LoadTestZip.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: BaseClasses.LoadTestBase. Omitted: graphical annotations, displayPF.
@component function LoadTestZip(; name, S_b = 100e6, fn = 50)
    @named base = LoadTestBase(; S_b, fn)
    @unpack bus3 = base
    systems = @named begin
        zIP = ZIP(; Sn = 10000000.0, Pz = 0.5, Pi = 0.3, Qz = 0.5, Qi = 0.3, P_0 = 800000.0, Q_0 = 600000.0, v_0 = 0.993325452568749, S_b, fn)
    end
    eqs = Equation[
        connect(bus3.p, zIP.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Loads.PSAT.LoadTestZip" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Loads.PSAT.LoadTestZip.jl"))
    # rtol 5e-3: the undamped Order3 of LoadTestBase drifts after the pm pulse, identically at tol 1e-8 (F-27)
    validate_against_oracle(LoadTestZip, oracle; rtol = 5e-3)
end
