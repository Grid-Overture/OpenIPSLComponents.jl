# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Solar/PowerFactory/PVD1.mo, transcribed automatically (2026-09-19); reviewed by hand.
# extends: Modelica.Icons.Example (nothing to port). The same network as DIgSILENT_PV (ElmVac + two Steps, no Bus);
# `M_b(displayUnit = "V.A") = 0.5e6` is `M_b = 0.5e6` (F-68). 2 s, 2000 intervals (the .mo's experiment; its
# `s = "rungekutta"` simulation flag is not honoured by the oracle, DASSL as every Test). `angle_v` of the static
# generator is skipped (F-74: +-pi on the sign of a 1e-9 `p.vi`). Omitted: graphical annotations, displayPF.
@component function PVD1(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        frequency = Step(; height = -0.05, offset = 1, startTime = 1)
        voltage = Step(; height = -0.05, offset = 1, startTime = 0.5)
        elmVac = ElmVac(; angle_0 = 0.0, v_0 = 1.0, S_b, fn)
        plantPVD1 = PlantPVD1(; M_b = 0.5e6, P_0 = 300000.0, Q_0 = 100000.0, S_b, fn)
    end
    eqs = Equation[
        voltage.y ~ elmVac.v,   # connect(voltage.y, elmVac.v)
        frequency.y ~ elmVac.f0,   # connect(frequency.y, elmVac.f0)
        connect(plantPVD1.p, elmVac.p),
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.Solar.PowerFactory.PVD1" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Solar.PowerFactory.PVD1.jl"))
    validate_against_oracle(PVD1, oracle; skip = ["plantPVD1.static_generator.angle_v"])
end
