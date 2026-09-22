# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/TwoAreas/Groups/PSAT/G1.mo (extends Support/Generator.mo), transcribed by
# the transcriber (2026-09-16); reviewed by hand. Named `TwoAreas_PSAT_G1` (JULIA_NAMES): the leaf
# name collides with the PSSE groups of batch 4.
# A 900 MVA Order6 with vf <- vf0 and pm <- pm0, no controls (M = 13.0 here). G2/G3/G4 extend it through
# `mods` (G2 is an exact copy in the .mo, G3 and G4 change only M). Omitted: graphical annotations, displayPF.
@component function TwoAreas_PSAT_G1(; name, S_b = 100e6, V_b = 400e3, fn = 60, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0, mods = (;))
    @named base = TwoAreas_Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    order6_1 = redeclared(mods, :order6_1, Order6)(; name = :order6_1, modified(mods, :order6_1,
        (; Sn = 900000000.0, Vn = 20000.0, ra = 0.0025, x1d = 0.3, M = 13.0, D = 0.0, xd = 1.80,
        xq = 1.7, x1q = 0.55, x2d = 0.25, x2q = 0.25, T1d0 = 8.0, T1q0 = 0.4, T2d0 = 0.03, T2q0 = 0.05,
        V_b, v_0, angle_0, P_0, Q_0, S_b, fn))...)
    systems = [order6_1]
    eqs = Equation[
        connect(order6_1.p, pwPin),
        order6_1.vf ~ order6_1.vf0,   # connect(order6_1.vf0, order6_1.vf)
        order6_1.pm ~ order6_1.pm0,   # connect(order6_1.pm0, order6_1.pm)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
