# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/KundurSMIB/SMIB_AVR_PSS.mo (extends SMIB_Partial.mo), transcribed by
# the transcriber (2026-09-16); reviewed by hand. Named `KundurSMIB_SMIB_AVR_PSS` (JULIA_NAMES).
# `G1` on the case's power flow (P_0 = 0.9*S_b, Q_0 = 0.436*S_b, angle_0 = 0.4947 rad) at B1.
# The .mo's `machine(delta(fixed = true))` modifier (the AVR variants) is already the initial condition of
# baseMachine (F-20), so nothing has to travel in `mods`.
# Omitted: Modelica.Icons.Example, graphical annotations, displayPF.
@component function KundurSMIB_SMIB_AVR_PSS(; name, S_b = 2220e6, fn = 60)
    @named base = KundurSMIB_Partial(; S_b, fn)
    @unpack B1 = base
    systems = @named begin
        G1 = KundurSMIB_Generator_AVR_PSS(; v_0 = 1.0, P_0 = 0.899999999997135 * S_b, Q_0 = 0.436002238696658 * S_b,
            angle_0 = 0.494677176989155, S_b, fn)
    end
    eqs = Equation[connect(G1.pwPin, B1.p)]
    extend(System(eqs, t, [], []; name, systems), base)
end
