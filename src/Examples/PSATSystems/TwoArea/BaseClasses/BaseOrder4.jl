# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/PSATSystems/TwoArea/BaseClasses/BaseOrder4.mo (partial; extends BaseNetwork.mo),
# transcribed automatically (2026-09-16, --kind base); reviewed by hand.
# Named `TwoArea_BaseOrder4` (JULIA_NAMES). Adds the 991 MVA Order4 at B1 (the machine that *supplies* the 110 MW the
# Order3 of the base absorbs), with pm <- pm0 and its field left for the exciter of the child.
# Second level of a three-level `extend` chain with numeric keyword arguments only, so `@named base` is safe
# (F-39 concerns symbolic ones). Omitted: graphical annotations, displayPF.
@component function TwoArea_BaseOrder4(; name, S_b = 100e6, fn = 50)
    @named base = TwoArea_BaseNetwork(; S_b, fn)
    @unpack B1 = base
    systems = @named begin
        order4 = Order4(; Sn = 991000000.0, Vn = 20000.0, V_b = 20000.0, v_0 = 1.05, ra = 0.0, xd = 2.0, xq = 1.91,
            x1d = 0.245, x1q = 0.42, T1d0 = 5.0, T1q0 = 0.66, M = 2.8756 * 2, P_0 = 109999999.9999998,
            Q_0 = -13662066.6228504, angle_0 = 0.145884959290248, D = 0.0, S_b, fn)
    end
    eqs = Equation[
        connect(order4.p, B1.p),
        order4.pm ~ order4.pm0,   # connect(order4.pm, order4.pm0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
