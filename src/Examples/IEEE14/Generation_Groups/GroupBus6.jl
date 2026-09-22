# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/IEEE14/Generation_Groups/GroupBus6.mo (extends Electrical/Essentials/pfComponent.mo),
# drafted automatically (2026-09-16, --kind base); reviewed by hand.
# 13.8 kV / 25 MVA synchronous condenser connected to bus 6. Machine + AVRTypeII with `vref0 -> vref` (the exciter holds its own initial
# reference: there is no disturbance path in this case). `vf0` and `vref0` are declared and used nowhere in the .mo
# (F-05): kept as keyword arguments and inert. `fn = 60` is a modifier of the machine, not of the group.
# Omitted: displayPF, graphical annotations.

@component function GroupBus6(; name, S_b = 100e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        vf0 = 3.146313160164693, vref0 = 1.228917822125829, mods = (;))
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    Syn5 = redeclared(mods, :Syn5, Order6)(; name = :Syn5, modified(mods, :Syn5, (;
        D = 2.0, Sn = 25000000.0, xd = 1.25, xq = 1.22, x1d = 0.232, x1q = 0.715, x2d = 0.12, x2q = 0.12,
        T1d0 = 4.75, T1q0 = 1.5, T2d0 = 0.06, T2q0 = 0.21, M = 2 * 5.06, ra = 0.0041, Vn = 13800.0, V_b, v_0, angle_0, P_0, Q_0, S_b, fn = 60.0))...)
    aVR4TypeII1 = redeclared(mods, :aVR4TypeII1, AVRTypeII)(; name = :aVR4TypeII1, modified(mods, :aVR4TypeII1, (;
        Ta = 0.02, Tf = 1.0, Ke = 1.0, Tr = 0.001, Ka = 20.0, Kf = 0.001, Te = 0.7, v0 = v_0, vrmin = 1.395,
        vrmax = 6.81))...)
    pwPin_ = PwPin(; name = :pwPin)
    systems = [Syn5, aVR4TypeII1, pwPin_]
    eqs = Equation[
        Syn5.vf ~ aVR4TypeII1.vf,            # connect(aVR4TypeII1.vf, Syn5.vf)
        aVR4TypeII1.v ~ Syn5.v,              # connect(Syn5.v, aVR4TypeII1.v)
        connect(Syn5.p, pwPin_),
        Syn5.pm ~ Syn5.pm0,          # connect(Syn5.pm0, Syn5.pm)
        aVR4TypeII1.vref ~ aVR4TypeII1.vref0,        # connect(aVR4TypeII1.vref0, aVR4TypeII1.vref)
        aVR4TypeII1.vf0 ~ Syn5.vf0,          # connect(aVR4TypeII1.vf0, Syn5.vf0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
