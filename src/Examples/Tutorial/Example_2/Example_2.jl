# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_2/Example_2.mo, transcribed automatically
# (2026-09-16); reviewed by hand.
# Example_1's network with the generation unit that carries a PSSTypeII. The transformer is called `Transformer`
# (capital, sic) here and the three buses take their defaults, unlike Example_1's; the topology is the same and
# neither line opens.
# Omitted: Modelica.Icons.Example, graphical annotations, displayPF.
@component function Example_2(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        B1 = Bus(; S_b, fn)
        B2 = Bus(; S_b, fn)
        B3 = Bus(; S_b, fn)
        G1 = Example_2_Generator(; V_b = 400000.0, v_0 = 1.0, P_0 = 1997999999.9936396, Q_0 = 967924969.9065775,
            angle_0 = 0.494677176989154, S_b, fn)
        Transformer = TwoWindingTransformer(; Sn = 2220000000.0, V_b = 400000.0, Vn = 400000.0, rT = 0.0, xT = 0.15,
            S_b, fn)
        line_1 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.5 * 100 / 2220, S_b = 100000000.0, fn)
        infinite_bus = InfiniteBus(; v_0 = 0.90081, P_0 = -1998000000.0, Q_0 = 87066000.0, S_b, fn)
        fault = PwFault(; R = 0.0, t1 = 0.5, t2 = 0.57, X = 0.01 * 100 / 2220)
        line_2 = PwLine(; R = 0.0, G = 0.0, B = 0.0, S_b = 100000000.0, X = 0.93 * 100 / 2220, fn)
    end
    eqs = Equation[
        connect(G1.pwPin, B1.p),
        connect(B1.p, Transformer.p),
        connect(Transformer.n, B2.p),
        connect(B2.p, line_1.p),
        connect(B3.p, infinite_bus.p),
        connect(B3.p, line_1.n),
        connect(line_2.n, line_1.n),
        connect(B2.p, line_2.p),
        connect(fault.p, B2.p),
    ]
    System(eqs, t, [], []; name, systems)
end
