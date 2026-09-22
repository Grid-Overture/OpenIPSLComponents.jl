# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/PSATSystems/ThreeArea/SixthOrder_AVRIII.mo (extends BaseClasses/BaseOrder6.mo),
# transcribed automatically (2026-09-16); reviewed by hand.
# Named `ThreeArea_SixthOrder_AVRIII` (JULIA_NAMES). Third level of the `extend` chain: two AVRtypeIII, `Exc1` on
# `Syn2` and `Exc2` on `order3_2`, each with a zero constant on its stabilizer input.
# The base wires `order3_2.pm0 ~ order3_2.pm` only and leaves that machine's field to this child (it connects
# `vf0` to `vf` for `order2` alone), so `Exc2.vf -> order3_2.vf` closes it. `T1 = 1`, `T2 = 10` keep AVRtypeIII's
# `1 - T1/T2` term alive here, unlike the KundurSMIB and Tutorial cases where T1 = T2 cancels it.
# Omitted: Modelica.Icons.Example, graphical annotations, displayPF.
@component function ThreeArea_SixthOrder_AVRIII(; name, S_b = 100e6, fn = 50)
    @named base = ThreeArea_BaseOrder6(; S_b, fn)
    @unpack Syn2, order3_2 = base
    systems = @named begin
        Exc1 = AVRtypeIII(; T2 = 10.0, T1 = 1.0, Te = 0.01, K0 = 25.0)
        Exc2 = AVRtypeIII(; T2 = 10.0, T1 = 1.0, Te = 0.01, K0 = 25.0)
        vs_1 = Constant(; k = 0.0)
        vs_2 = Constant(; k = 0.0)
    end
    eqs = Equation[
        Syn2.vf ~ Exc1.vf,           # connect(Exc1.vf, Syn2.vf)
        Exc1.vf0 ~ Syn2.vf0,         # connect(Exc1.vf0, Syn2.vf0)
        Exc1.v ~ Syn2.v,             # connect(Exc1.v, Syn2.v)
        Exc1.vs ~ vs_1.y,            # connect(vs_1.y, Exc1.vs)
        order3_2.vf ~ Exc2.vf,       # connect(Exc2.vf, order3_2.vf)
        Exc2.vf0 ~ order3_2.vf0,     # connect(order3_2.vf0, Exc2.vf0)
        Exc2.vs ~ vs_2.y,            # connect(vs_2.y, Exc2.vs)
        Exc2.v ~ order3_2.v,         # connect(Exc2.v, order3_2.v)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
