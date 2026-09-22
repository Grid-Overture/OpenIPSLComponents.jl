# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Solar/PSAT/SolarPQTest.mo, transcribed automatically (2026-09-19); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB(constantLoad(P_0 = 1000000*(50/2), Q_0 = 1000000*(10/2))), i.e. the load at
# half the SMIB value (25 MW, 5 Mvar) while LOAD.v_0/angle_0 keep the 50 MW values (sic). `PQ1` has no `fn` (no
# SystemBase frequency in the .mo) and its P_0/Q_0 are pu of Sn = S_b. Omitted: graphical annotations, displayPF.
@component function SolarPQTest(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn, mods = (; constantLoad = (; P_0 = 25e6, Q_0 = 5e6)))
    @unpack GEN1 = base
    systems = @named begin
        SPQ = PQ1(; Q_0 = 0.05416582152, angle_0 = 0.14093849062925, v_0 = 1.0146961212, P_0 = 0.4, Td = 0.15, Tq = 0.15, S_b)
    end
    eqs = Equation[
        connect(GEN1.p, SPQ.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Solar.PSAT.SolarPQTest" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Solar.PSAT.SolarPQTest.jl"))
    validate_against_oracle(SolarPQTest, oracle)
end
