# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/CGMES/TG/GovHydroIEEE0_Test.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# GENROU (instance `generator`) with no exciter (EFD0 <- EFD); the governor takes its defaults and its power
# reference is the machine's own electrical power (`Pref <- generator.PELEC`, sic). StopTime 5 s.
@component function GovHydroIEEE0_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        const2 = Constant(; k = 0)
        generator = GENROU(; M_b = 100000000.0, Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, P_0 = 40000000.0, angle_0 = 0.070492225331847, Q_0 = 5416582.0, Xppq = 0.2, R_a = 0.0, Xpp = 0.2, H = 4.28, v_0 = 1.0, S_b, fn)
        govHydroIEEE0_1 = GovHydroIEEE0()
    end
    eqs = Equation[
        connect(generator.p, GEN1.p),
        generator.EFD0 ~ generator.EFD,              # connect(generator.EFD0, generator.EFD)
        generator.SPEED ~ govHydroIEEE0_1.SPEED,     # connect(generator.SPEED, govHydroIEEE0_1.SPEED)
        generator.PELEC ~ govHydroIEEE0_1.Pref,      # connect(generator.PELEC, govHydroIEEE0_1.Pref)
        govHydroIEEE0_1.PMECH ~ generator.PMECH,     # connect(govHydroIEEE0_1.PMECH, generator.PMECH)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.CGMES.TG.GovHydroIEEE0_Test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.CGMES.TG.GovHydroIEEE0_Test.jl"))
    validate_against_oracle(GovHydroIEEE0_Test, oracle)
end
