# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/PSATSystems/TwoArea/FourthOrder_AVRII.mo (extends BaseClasses/BaseOrder4.mo),
# transcribed automatically (2026-09-16); reviewed by hand.
# Named `TwoArea_FourthOrder_AVRII` (JULIA_NAMES): `FourthOrder_AVRII` exists in both PSATSystems areas.
# Third level of the `extend` chain: the AVRTypeII on `order4`, with `vref0 -> vref` and `Ae = Be = 0` (no ceiling).
# Omitted: Modelica.Icons.Example, graphical annotations, displayPF.
@component function TwoArea_FourthOrder_AVRII(; name, S_b = 100e6, fn = 50)
    @named base = TwoArea_BaseOrder4(; S_b, fn)
    @unpack order4 = base
    systems = @named begin
        aVRTypeII = AVRTypeII(; v0 = 1.05, vrmin = 0.0, vrmax = 7.57, Ka = 7.04, Ta = 0.4, Kf = 1.0, Tf = 0.05,
            Ke = 1.0, Te = 0.4, Tr = 0.05, Ae = 0.0, Be = 0.0)
    end
    eqs = Equation[
        order4.vf ~ aVRTypeII.vf,        # connect(aVRTypeII.vf, order4.vf)
        aVRTypeII.v ~ order4.v,          # connect(aVRTypeII.v, order4.v)
        aVRTypeII.vref ~ aVRTypeII.vref0,   # connect(aVRTypeII.vref0, aVRTypeII.vref)
        aVRTypeII.vf0 ~ order4.vf0,      # connect(order4.vf0, aVRTypeII.vf0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
