# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Solar/PSAT/SolarPVTest.mo, transcribed automatically (2026-09-19); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB (no modifiers). `PV1` has no `fn`; its P_0/Q_0 are pu of Sn = S_b and
# its `x`/`Qref` are protected (not in the oracle). Omitted: graphical annotations, displayPF.
@component function SolarPVTest(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        SPV = PV1(; Q_0 = 5.416582/100, angle_0 = 0.070492225331847, v_0 = 1.0, vref = 1.0, P_0 = 0.4, S_b)
    end
    eqs = Equation[
        connect(GEN1.p, SPV.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Solar.PSAT.SolarPVTest" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Solar.PSAT.SolarPVTest.jl"))
    validate_against_oracle(SolarPVTest, oracle)
end
