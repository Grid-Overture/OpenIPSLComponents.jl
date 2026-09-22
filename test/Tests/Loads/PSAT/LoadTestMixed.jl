# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Loads/PSAT/LoadTestMixed.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: BaseClasses.LoadTestBase. Omitted: graphical annotations, displayPF.
@component function LoadTestMixed(; name, S_b = 100e6, fn = 50)
    @named base = LoadTestBase(; S_b, fn)
    @unpack bus3 = base
    systems = @named begin
        mixed = Mixed(; Sn = 10000000.0, Tpv = 0.1, Tqv = 0.1, Tfv = 0.1, Tft = 0.1, Kpf = 1.0, Kqf = 1.0, alpha = 1.0, beta = 1.0, angle_0 = -0.00746932024404292, P_0 = 800000.0, Q_0 = 600000.0, v_0 = 0.993325452568749, S_b, fn)
    end
    eqs = Equation[
        connect(bus3.p, mixed.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Loads.PSAT.LoadTestMixed" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Loads.PSAT.LoadTestMixed.jl"))
    # OpenIPSL's Test is under-determined (e1q, x, y free; one initial equation): OpenModelica fixes e1q and x at their
    # start values and lets y absorb the mismatch (F-28); rtol 5e-3 for the undamped machine's drift (F-27)
    validate_against_oracle(LoadTestMixed, oracle; rtol = 5e-3,
        u0 = sys -> [sys.order3_Inputs_Outputs1.e1q => sys.order3_Inputs_Outputs1.e1q0, sys.mixed.x => -0.993325452568749 / 0.1])
end
