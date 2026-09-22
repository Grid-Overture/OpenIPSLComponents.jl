# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_4/Experiments/SMIBVarLoad.mo
# (extends BaseModels/BaseNetwork/SMIBPartial.mo). The same network as SMIB with three modifiers of the extends:
# the load is redeclared to `Load_variation` (a ramp of -0.1 pu starting at t1 = 10 s over d_t = 60 s), the fault is
# moved to 101-101.1 s, and the unit is `GeneratorTurbGovAVRPSS` (the AVR unit plus a PSS2A).
# Over the 10 s of this port's comparison grid nothing happens: it is an equilibrium case.
# `Example_4_SMIBVarLoad` (JULIA_NAMES). Omitted: Modelica.Icons.Example, graphical annotations, displayPF.

@component function Example_4_SMIBVarLoad(; name, S_b = 100e6, fn = 50, pf = Example_4_PF00000,
        genunit = Example_4_GeneratorTurbGovAVRPSS)
    @named base = Example_4_SMIBPartial(; S_b, fn, pf, load = Load_variation,
        load_mods = (; d_P = -0.1, t1 = 10.0, d_t = 60.0), pwFault_mods = (; t1 = 101.0, t2 = 101.1))
    @unpack B01 = base
    genunit_ = genunit(; name = :genunit, P_0 = pf.machine.PG1, Q_0 = pf.machine.QG1, v_0 = pf.bus.v1,
        angle_0 = pf.bus.A1, S_b, fn)
    eqs = Equation[connect(genunit_.pwPin, B01.p)]
    extend(System(eqs, t, [], []; name, systems = [genunit_]), base)
end
