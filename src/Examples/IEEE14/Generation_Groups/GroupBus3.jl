# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/IEEE14/Generation_Groups/GroupBus3.mo (extends Electrical/Essentials/pfComponent.mo),
# drafted automatically (2026-09-16, --kind base); reviewed by hand.
# 69 kV / 60 MVA synchronous condenser connected to bus 3. Machine + AVRTypeII with `vref0 -> vref` (the exciter holds its own initial
# reference: there is no disturbance path in this case). `vf0` and `vref0` are declared and used nowhere in the .mo
# (F-05): kept as keyword arguments and inert. `fn = 60` is a modifier of the machine, not of the group.
# Omitted: displayPF, graphical annotations.

@component function GroupBus3(; name, S_b = 100e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        vf0 = 2.045032675265054, vref0 = 1.112638137121514, mods = (;))
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    Syn2 = redeclared(mods, :Syn2, Order6)(; name = :Syn2, modified(mods, :Syn2, (;
        Sn = 60000000.0, Vn = 69000.0, ra = 0.0031, xq = 0.98, x1d = 0.1850, x1q = 0.36, x2d = 0.13,
        x2q = 0.13, T1d0 = 6.1, T1q0 = 0.3, T2q0 = 0.099, M = 2 * 6.54, D = 2.0, xd = 1.05, V_b, v_0, angle_0, P_0, Q_0, S_b, fn = 60.0))...)
    aVR2TypeII2 = redeclared(mods, :aVR2TypeII2, AVRTypeII)(; name = :aVR2TypeII2, modified(mods, :aVR2TypeII2, (;
        Ta = 0.02, Tf = 1.0, Ke = 1.0, Tr = 0.001, Ka = 20.0, Kf = 0.001, Te = 1.98, v0 = v_0, vrmin = 0.0,
        vrmax = 4.38))...)
    pwPin_ = PwPin(; name = :pwPin)
    systems = [Syn2, aVR2TypeII2, pwPin_]
    eqs = Equation[
        Syn2.vf ~ aVR2TypeII2.vf,            # connect(aVR2TypeII2.vf, Syn2.vf)
        aVR2TypeII2.v ~ Syn2.v,              # connect(Syn2.v, aVR2TypeII2.v)
        connect(Syn2.p, pwPin_),
        Syn2.pm ~ Syn2.pm0,          # connect(Syn2.pm0, Syn2.pm)
        aVR2TypeII2.vref ~ aVR2TypeII2.vref0,        # connect(aVR2TypeII2.vref0, aVR2TypeII2.vref)
        aVR2TypeII2.vf0 ~ Syn2.vf0,          # connect(aVR2TypeII2.vf0, Syn2.vf0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
