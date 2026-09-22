# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Solar/PowerFactory/DIgSILENT_PV.mo, transcribed automatically (2026-09-19); reviewed by hand.
# extends: Modelica.Icons.Example (nothing to port). No Bus: the plant hangs from the ideal source `voltage_source`
# (ElmVac) driven by the two Steps (voltage -5 % at 0.5 s, frequency -5 % at 1 s, discrete events with their own
# tstops, F-25); `SysData` with its defaults is `S_b = 100e6`, `fn = 50`. `angle_v`/`angle_i` of the static generator
# are skipped: with `p.vi` (`p.ii`) at +-1e-9 (+-0) their `atan2` flips between +-pi on a sign that neither tool
# controls (F-74). Omitted: graphical annotations, displayPF.
@component function DIgSILENT_PV(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        voltage = Step(; height = -0.05, offset = 1, startTime = 0.5)
        voltage_source = ElmVac(; angle_0 = 0.0, v_0 = 1.0, S_b, fn)
        frequency = Step(; height = -0.05, offset = 1, startTime = 1)
        pv_plant = PV_Plant(; M_b = 0.5e6, P_0 = 300000.0, angle_0 = 0.0, v_0 = 1.0, S_b, fn)
    end
    eqs = Equation[
        connect(pv_plant.p, voltage_source.p),
        voltage.y ~ voltage_source.v,   # connect(voltage.y, voltage_source.v)
        voltage_source.f0 ~ frequency.y,   # connect(voltage_source.f0, frequency.y)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.Solar.PowerFactory.DIgSILENT_PV" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Solar.PowerFactory.DIgSILENT_PV.jl"))
    validate_against_oracle(DIgSILENT_PV, oracle; skip = ["pv_plant.generator.angle_v", "pv_plant.generator.angle_i"])
end
