# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/NonElectrical/Functions/ImSE_exp.mo (a Test of this port, not OpenIPSL's: PLAN-12, family A),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# The block alone with a ramp that stays positive throughout (`SE_exp` has no guard for a non-positive argument,
# F-88). The saturation data are the S10/S12 of the machine of Tests.Machines.PSSE.GENSAL. The Test function takes
# the suffix _Test because `ImSE_exp` is the model (PLAN-02 rule).
@component function ImSE_exp_Test(; name)
    systems = @named begin
        imSE_exp = ImSE_exp(; SE1 = 0.11, SE2 = 0.39, E1 = 1, E2 = 1.2)
        VE_IN = Ramp(; height = 1.5, duration = 3, offset = 0.5, startTime = 1)
    end
    eqs = Equation[
        VE_IN.y ~ imSE_exp.VE_IN,   # connect(VE_IN.y, imSE_exp.VE_IN)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "PortTests.NonElectrical.Functions.ImSE_exp" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "NonElectrical.Functions.ImSE_exp.jl"))
    validate_against_oracle(ImSE_exp_Test, oracle)
end
