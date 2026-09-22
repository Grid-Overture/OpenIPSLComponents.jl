# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/TG/TGOV1.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `TGOV1` is the governor (a Test named as its model gets the suffix _Test): GENROE with no exciter (EFD <- EFD0).
@component function TGOV1_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        tGOV1 = TGOV1(; R = 0.04, D_t = 0.0, T_1 = 0.4, T_2 = 2.0, T_3 = 6.0, V_MAX = 0.86, V_MIN = 0.3)
    end
    eqs = Equation[
        gENROE.EFD ~ gENROE.EFD0,      # connect(gENROE.EFD, gENROE.EFD0)
        tGOV1.SPEED ~ gENROE.SPEED,    # connect(tGOV1.SPEED, gENROE.SPEED)
        tGOV1.PMECH0 ~ gENROE.PMECH0,  # connect(tGOV1.PMECH0, gENROE.PMECH0)
        tGOV1.PMECH ~ gENROE.PMECH,    # connect(tGOV1.PMECH, gENROE.PMECH)
        connect(gENROE.p, GEN1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.TG.TGOV1" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.TG.TGOV1.jl"))
    validate_against_oracle(TGOV1_Test, oracle)
end
