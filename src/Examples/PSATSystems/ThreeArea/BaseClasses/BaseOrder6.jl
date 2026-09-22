# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/PSATSystems/ThreeArea/BaseClasses/BaseOrder6.mo (partial; extends BaseNetwork.mo),
# transcribed automatically (2026-09-16, --kind base); reviewed by hand.
# Named `ThreeArea_BaseOrder6` (JULIA_NAMES). Adds the 900 MVA Order6 `Syn2` at B800 with pm <- pm0; its field is
# left for the exciter of the child. Second level of a three-level `extend` chain with numeric keyword arguments only
# (F-39 concerns symbolic ones). Omitted: graphical annotations, displayPF.
@component function ThreeArea_BaseOrder6(; name, S_b = 100e6, fn = 50)
    @named base = ThreeArea_BaseNetwork(; S_b, fn)
    @unpack B800 = base
    systems = @named begin
        Syn2 = Order6(; Sn = 900000000.0, Vn = 1000.0, V_b = 1000.0, ra = 0.0, xd = 1.8, x1d = 0.3, M = 21.0,
            v_0 = 1.05, D = 2.0, T1q0 = 0.4, x2d = 0.25, x2q = 0.25, T2d0 = 0.03, T2q0 = 0.05, x1q = 0.55,
            Q_0 = 19794689.2114274, angle_0 = 0.820649645221366, P_0 = 50000000.0, S_b, fn)
    end
    eqs = Equation[
        connect(Syn2.p, B800.p),
        Syn2.pm ~ Syn2.pm0,   # connect(Syn2.pm0, Syn2.pm)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
