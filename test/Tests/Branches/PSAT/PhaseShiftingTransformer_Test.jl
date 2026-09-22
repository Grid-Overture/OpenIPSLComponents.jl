# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Branches/PSAT/PhaseShiftingTransformer_Test.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function PhaseShiftingTransformer_Test(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        lOADPQ = PQ(; S_b, fn)
        B1 = Bus(; S_b, fn)
        B2 = Bus(; S_b, fn)
        infiniteBus = InfiniteBus(; S_b, fn)
        phaseShiftingTransformer = PhaseShiftingTransformer(; V_b = 400000, Vn = 400000, m = 0.95, pref = 0.005, alpha0 = 0.34906585039887)
    end
    eqs = Equation[
        connect(lOADPQ.p, B2.p),
        connect(infiniteBus.p, B1.p),
        connect(B1.p, phaseShiftingTransformer.p),
        connect(phaseShiftingTransformer.n, B2.p),
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.Branches.PSAT.PhaseShiftingTransformer_Test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Branches.PSAT.PhaseShiftingTransformer_Test.jl"))
    # the shifter's states have no initial equation: OpenModelica fixes them at their start values (F-28)
    ps = sys -> [sys.phaseShiftingTransformer.phaseShifter.pmes => sys.phaseShiftingTransformer.phaseShifter.pmes0,
        sys.phaseShiftingTransformer.phaseShifter.alpha => sys.phaseShiftingTransformer.phaseShifter.alpha0]
    validate_against_oracle(PhaseShiftingTransformer_Test, oracle; u0 = ps, transformer_aliases(oracle)...)
end
