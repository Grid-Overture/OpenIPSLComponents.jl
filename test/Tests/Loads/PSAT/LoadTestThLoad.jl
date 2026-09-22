# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Loads/PSAT/LoadTestThLoad.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.LoadTestBase. Omitted: graphical annotations, displayPF.
@component function LoadTestThLoad(; name, S_b = 100e6, fn = 50)
    @named base = LoadTestBase(; S_b, fn)
    @unpack bus3 = base
    systems = @named begin
        Tref = Constant(; k = 70)
        T_a = Constant(; k = 10)
        thLoad = ThermostaticallyControlled(; Sn = 10000000.0, P_0 = 800000.0, Q_0 = 600000.0, Ti = 12.0, Kl = 1.0, S_b, fn)
    end
    eqs = Equation[
        Tref.y ~ thLoad.t_ref,   # connect(Tref.y, thLoad.t_ref)
        T_a.y ~ thLoad.t_a,   # connect(T_a.y, thLoad.t_a)
        connect(bus3.p, thLoad.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Loads.PSAT.LoadTestThLoad" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Loads.PSAT.LoadTestThLoad.jl"))
    # SimpleLag's `const` sub-block is `const_` in Julia (keyword); rtol 5e-3: the undamped Order3 of LoadTestBase drifts
    # after the pm pulse (36 variables exact at t = 0, errors above 1e-4 only from 10 s on), identically at tol 1e-8 (F-27)
    validate_against_oracle(LoadTestThLoad, oracle; rtol = 5e-3,
        rename = Dict("thLoad.firstOrder.const.y" => "thLoad.firstOrder.const_.y"))
end
