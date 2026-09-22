# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Loads/PSAT/LoadTestFreqDependent.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: BaseClasses.LoadTestBase. Omitted: graphical annotations, displayPF.
@component function LoadTestFreqDependent(; name, S_b = 100e6, fn = 50)
    @named base = LoadTestBase(; S_b, fn)
    @unpack bus3 = base
    systems = @named begin
        frequencyDependent = FrequencyDependent(; alpha_p = 0.0, beta_p = 1.0, beta_q = 1.0, Sn = 10000000.0, angle_0 = -0.00746932024404292, alpha_q = 0.0, Tf = 0.1, P_0 = 800000.0, Q_0 = 600000.0, v_0 = 0.993325452568749, S_b, fn)
    end
    eqs = Equation[
        connect(bus3.p, frequencyDependent.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Loads.PSAT.LoadTestFreqDependent" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Loads.PSAT.LoadTestFreqDependent.jl"))
    # rtol 5e-3: the undamped Order3 of LoadTestBase drifts after the pm pulse, identically at tol 1e-8 (F-27)
    validate_against_oracle(LoadTestFreqDependent, oracle; rtol = 5e-3)
end
