# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/IEEE14/Generation_Groups/GroupBus8.mo (extends Electrical/Essentials/pfComponent.mo),
# drafted automatically (2026-09-16, --kind base); reviewed by hand.
# 18 kV / 25 MVA synchronous condenser connected to bus 8. Machine + AVRTypeII with `vref0 -> vref` (the exciter holds its own initial
# reference: there is no disturbance path in this case). `vf0` and `vref0` are declared and used nowhere in the .mo
# (F-05): kept as keyword arguments and inert. `fn = 60` is a modifier of the machine, not of the group.
# Omitted: displayPF, graphical annotations.

@component function GroupBus8(; name, S_b = 100e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        vf0 = 2.622215878949932, vref0 = 1.221943942023239, mods = (;))
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    Syn4 = redeclared(mods, :Syn4, Order6)(; name = :Syn4, modified(mods, :Syn4, (;
        D = 2.0, Sn = 25000000.0, xd = 1.25, xq = 1.22, x1d = 0.232, x1q = 0.715, x2d = 0.12, x2q = 0.12,
        T1d0 = 4.75, T1q0 = 1.5, T2d0 = 0.06, T2q0 = 0.21, M = 2 * 5.06, ra = 0.0041, Vn = 18000.0, V_b, v_0, angle_0, P_0, Q_0, S_b, fn = 60.0))...)
    aVR3TypeII2 = redeclared(mods, :aVR3TypeII2, AVRTypeII)(; name = :aVR3TypeII2, modified(mods, :aVR3TypeII2, (;
        Ta = 0.02, Tf = 1.0, Ke = 1.0, Tr = 0.001, Ka = 20.0, Kf = 0.001, Te = 0.7, v0 = v_0, vrmin = 1.395,
        vrmax = 6.810))...)
    pwPin_ = PwPin(; name = :pwPin)
    systems = [Syn4, aVR3TypeII2, pwPin_]
    eqs = Equation[
        Syn4.vf ~ aVR3TypeII2.vf,            # connect(aVR3TypeII2.vf, Syn4.vf)
        aVR3TypeII2.v ~ Syn4.v,              # connect(Syn4.v, aVR3TypeII2.v)
        connect(Syn4.p, pwPin_),
        Syn4.pm ~ Syn4.pm0,          # connect(Syn4.pm0, Syn4.pm)
        aVR3TypeII2.vref ~ aVR3TypeII2.vref0,        # connect(aVR3TypeII2.vref0, aVR3TypeII2.vref)
        aVR3TypeII2.vf0 ~ Syn4.vf0,          # connect(aVR3TypeII2.vf0, Syn4.vf0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
