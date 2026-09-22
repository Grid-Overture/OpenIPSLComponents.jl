# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_4/Experiments/SMIB.mo (extends BaseModels/BaseNetwork/SMIBPartial.mo)
# The partial network plus the `replaceable genunit`, by default `GeneratorTurbGovAVR` (GENROE + IEEEG1 + ESST1A),
# on the machine's own power-flow data. `genunit` is a constructor keyword, as `replaceable` always is (F-20 b).
# Named `Example_4_SMIB` (JULIA_NAMES): the leaf name collides with `Tests.BaseClasses.SMIB`.
# Omitted: Modelica.Icons.Example, graphical annotations, displayPF.

@component function Example_4_SMIB(; name, S_b = 100e6, fn = 50, pf = Example_4_PF00000,
        genunit = Example_4_GeneratorTurbGovAVR)
    @named base = Example_4_SMIBPartial(; S_b, fn, pf)
    @unpack B01 = base
    genunit_ = genunit(; name = :genunit, P_0 = pf.machine.PG1, Q_0 = pf.machine.QG1, v_0 = pf.bus.v1,
        angle_0 = pf.bus.A1, S_b, fn)
    eqs = Equation[connect(genunit_.pwPin, B01.p)]
    extend(System(eqs, t, [], []; name, systems = [genunit_]), base)
end
