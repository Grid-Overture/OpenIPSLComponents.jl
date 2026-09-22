# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Loads/PSAT/LoadTestZipExtInput.mo (a Test of this port, not OpenIPSL's: PLAN-12, family E),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.LoadTestBase. Omitted: graphical annotations, displayPF.
# The network of Tests.Loads.PSAT.LoadTestZip and the same load parameters, with the input `u` the model adds: a
# step of 0.002 pu at 3 s, which is 200 kW on the system base and not on the load's Sn, because the .mo sums `u`
# after the division by S_b (sic). The horizon is 20 s, long enough for the last of the base's sines.
# The Test class is not named after a model, so it keeps the .mo's own name.
@component function LoadTestZipExtInput(; name, S_b = 100e6, fn = 50)
    @named base = LoadTestBase(; S_b, fn)
    @unpack bus3 = base
    systems = @named begin
        zIP_ExtInput = ZIP_ExtInput(; Sn = 10000000.0, Pz = 0.5, Pi = 0.3, Qz = 0.5, Qi = 0.3, P_0 = 800000.0, Q_0 = 600000.0, v_0 = 0.993325452568749, S_b, fn)
        u = Step(; height = 0.002, startTime = 3)
    end
    eqs = Equation[
        connect(bus3.p, zIP_ExtInput.p),
        u.y ~ zIP_ExtInput.u,   # connect(u.y, zIP_ExtInput.u)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Loads.PSAT.LoadTestZipExtInput" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Loads.PSAT.LoadTestZipExtInput.jl"))
    validate_against_oracle(LoadTestZipExtInput, oracle)
end
