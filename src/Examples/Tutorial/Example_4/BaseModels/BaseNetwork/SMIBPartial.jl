# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_4/BaseModels/BaseNetwork/SMIBPartial.mo (extends nothing)
# Four buses, four lines, the infinite-bus unit, the load and the fault; the generating unit is added by the
# experiment that extends this model. The `pf` record is the `Example_4_PF00000` NamedTuple (PFData/PF00000.jl),
# passed as a keyword and read as `pf.bus.v1` (the .mo writes `pf.powerflow.bus.v1`).
# The `replaceable load` and the `pwFault` modifiers of `SMIBVarLoad` come in as constructor keywords
# (`load`, `load_mods`, `pwFault_mods`), the form the transcribed `Tests.BaseClasses.SMIB` uses for the same
# Modelica construct. Named `Example_4_SMIBPartial` (JULIA_NAMES). Omitted: graphical annotations, displayPF,
# `inner SystemBase SysData` (the S_b/fn keywords).

@component function Example_4_SMIBPartial(; name, S_b = 100e6, fn = 50, pf = Example_4_PF00000, load = Load,
        load_mods = (;), pwFault_mods = (;))
    B = pf.bus
    load_ = load(; name = :load, merge((; P_0 = pf.load.PL1, Q_0 = pf.load.QL1, v_0 = B.v3, angle_0 = B.A3, S_b, fn),
        load_mods)...)
    pwFault_ = PwFault(; name = :pwFault, merge((; R = 0.01, X = 0.1, t1 = 1.0, t2 = 1.1), pwFault_mods)...)
    systems = @named begin
        B01 = Bus(; v_0 = B.v1, angle_0 = B.A1, S_b, fn)
        B03 = Bus(; v_0 = B.v3, angle_0 = B.A3, S_b, fn)
        B04 = Bus(; v_0 = B.v4, angle_0 = B.A4, S_b, fn)
        B02 = Bus(; v_0 = B.v2, angle_0 = B.A2, S_b, fn)
        line_01 = PwLine(; R = 0.001, X = 0.2, G = 0.0, B = 0.0, S_b, fn)
        line_02 = PwLine(; R = 0.01, X = 0.2, G = 0.0, B = 0.0, S_b, fn)
        line_03 = PwLine(; R = 0.0005, X = 0.1, G = 0.0, B = 0.0, S_b, fn)
        line_04 = PwLine(; R = 0.0005, X = 0.1, G = 0.0, B = 0.0, S_b, fn)
        infiniteBus = Example_4_InfiniteBus(; P_0 = pf.machine.PG2, Q_0 = pf.machine.QG2, v_0 = B.v2,
            angle_0 = B.A2, S_b, fn)
    end
    append!(systems, [load_, pwFault_])
    eqs = Equation[
        connect(line_01.p, B01.p),
        connect(line_01.n, B03.p),
        connect(line_02.p, B03.p),
        connect(line_02.n, B02.p),
        connect(line_03.p, B03.p),
        connect(line_03.n, B04.p),
        connect(line_04.p, B04.p),
        connect(line_04.n, B02.p),
        connect(infiniteBus.pwPin, B02.p),
        connect(load_.p, B03.p),
        connect(pwFault_.p, B04.p),
    ]
    System(eqs, t, [], []; name, systems)
end
