# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/IEEE14/Generation_Groups/GroupBus1.mo (extends Electrical/Essentials/pfComponent.mo),
# drafted automatically (2026-09-16, --kind base); reviewed by hand.
# 69 kV / 615 MVA generation unit connected to bus 1; the only `Order5_Type2` of the port. Machine + AVRTypeII with `vref0 -> vref` (the exciter holds its own initial
# reference: there is no disturbance path in this case). `vf0` and `vref0` are declared and used nowhere in the .mo
# (F-05): kept as keyword arguments and inert. `fn = 60` is a modifier of the machine, not of the group.
# Omitted: displayPF, graphical annotations.

@component function GroupBus1(; name, S_b = 100e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        vf0 = 1.122656195484139, vref0 = 1.065622531687790, mods = (;))
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    Syn1 = redeclared(mods, :Syn1, Order5_Type2)(; name = :Syn1, modified(mods, :Syn1, (;
        Sn = 615000000.0, Vn = 69000.0, ra = 0.0, xd = 0.8979, xq = 0.646, x1d = 0.2998, x2d = 0.23,
        x2q = 0.4, T1d0 = 7.4, T2d0 = 0.03, T2q0 = 0.033, M = 2 * 5.148, D = 2.0, V_b, v_0, angle_0, P_0, Q_0, S_b, fn = 60.0))...)
    AVR1 = redeclared(mods, :AVR1, AVRTypeII)(; name = :AVR1, modified(mods, :AVR1, (;
        Ta = 0.02, Tf = 1.0, Ke = 1.0, Tr = 0.001, Ka = 200.0, Kf = 0.002, Te = 0.2, v0 = v_0, vrmin = 0.0,
        vrmax = 7.32))...)
    pwPin_ = PwPin(; name = :pwPin)
    systems = [Syn1, AVR1, pwPin_]
    eqs = Equation[
        Syn1.vf ~ AVR1.vf,            # connect(AVR1.vf, Syn1.vf)
        AVR1.v ~ Syn1.v,              # connect(Syn1.v, AVR1.v)
        connect(Syn1.p, pwPin_),
        Syn1.pm ~ Syn1.pm0,          # connect(Syn1.pm0, Syn1.pm)
        AVR1.vref ~ AVR1.vref0,        # connect(AVR1.vref0, AVR1.vref)
        AVR1.vf0 ~ Syn1.vf0,          # connect(AVR1.vf0, Syn1.vf0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
