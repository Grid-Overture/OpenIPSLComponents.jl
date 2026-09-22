# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Controls/PSSE/ES/BaseClasses/SelectLogic.mo (a Test of this port, not OpenIPSL's: PLAN-12,
# family A), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# The block alone: three distinguishable constants on V1/V2/V3 so that the output names the active branch, VERR
# tied to 0 because the model declares the input and never reads it, and two steps that walk the output through
# Vout = 1, 2, 3. The block has no parameters. The Test function takes the suffix _Test because `SelectLogic` is
# the model (PLAN-02 rule).
@component function SelectLogic_Test(; name)
    systems = @named begin
        selectLogic = SelectLogic()
        V1 = Constant(; k = 1)
        V2 = Constant(; k = 2)
        V3 = Constant(; k = 3)
        VERR = Constant(; k = 0)
        VUEL = Step(; height = 1, startTime = 1)
        VOEL = Step(; height = 1, startTime = 2)
    end
    eqs = Equation[
        V1.y ~ selectLogic.V1,   # connect(V1.y, selectLogic.V1)
        V2.y ~ selectLogic.V2,   # connect(V2.y, selectLogic.V2)
        V3.y ~ selectLogic.V3,   # connect(V3.y, selectLogic.V3)
        VOEL.y ~ selectLogic.VOEL,   # connect(VOEL.y, selectLogic.VOEL)
        VUEL.y ~ selectLogic.VUEL,   # connect(VUEL.y, selectLogic.VUEL)
        VERR.y ~ selectLogic.VERR,   # connect(VERR.y, selectLogic.VERR)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "PortTests.Controls.PSSE.ES.BaseClasses.SelectLogic" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.BaseClasses.SelectLogic.jl"))
    validate_against_oracle(SelectLogic_Test, oracle)
end
