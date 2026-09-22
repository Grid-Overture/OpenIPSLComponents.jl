# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_1/Example_1.mo, transcribed automatically
# (2026-09-16); reviewed by hand.
# The single-machine-infinite-bus tutorial system: the 2220 MVA unit at B1, a PSAT transformer, two parallel lines to
# the infinite bus and a bolted fault at B2 from 0.5 to 0.57 s. **Neither line opens** - a correction to PLAN-06,
# which expected the permanent trip of KundurSMIB: `line_2` carries no `t1`/`t2`.
# `SysData(fn = 60)` leaves `S_b` at its 100 MVA default while the machine is rated 2220 MVA, so `G1.P_0 = 1.998e9 W`
# is 19.98 pu on the system base (the .mo's own data), and the two lines carry `S_b = 100e6` explicitly.
# Omitted: Modelica.Icons.Example, graphical annotations, displayPF.
@component function Example_1(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        B1 = Bus(; angle_0 = 0.494677176989154, S_b, fn)
        B2 = Bus(; v_0 = 0.944299492912195, angle_0 = 0.351222533717268, S_b, fn)
        B3 = Bus(; v_0 = 0.900810000000000, S_b, fn)
        G1 = Example_1_Generator(; v_0 = 1.0, P_0 = 1997999999.99364, Q_0 = 967924969.906578,
            angle_0 = 0.494677176989154, S_b, fn)
        transformer = TwoWindingTransformer(; Sn = 2220000000.0, V_b = 400000.0, Vn = 400000.0, rT = 0.0, xT = 0.15,
            S_b, fn)
        line_1 = PwLine(; R = 0.0, G = 0.0, B = 0.0, S_b = 100000000.0, X = 0.5 * 100 / 2220, fn)
        infinite_bus = InfiniteBus(; v_0 = 0.90081, angle_0 = 0.0, P_0 = -1998000000.0, Q_0 = 87066000.0, S_b, fn)
        fault = PwFault(; R = 0.0, t1 = 0.5, t2 = 0.57, X = 0.01 * 100 / 2220)
        line_2 = PwLine(; R = 0.0, G = 0.0, B = 0.0, S_b = 100000000.0, X = 0.93 * 100 / 2220, fn)
    end
    eqs = Equation[
        connect(G1.pwPin, B1.p),
        connect(B1.p, transformer.p),
        connect(transformer.n, B2.p),
        connect(line_1.n, B3.p),
        connect(B3.p, infinite_bus.p),
        connect(line_2.n, B3.p),
        connect(fault.p, B2.p),
        connect(line_2.p, B2.p),
        connect(line_1.p, B2.p),
    ]
    System(eqs, t, [], []; name, systems)
end
