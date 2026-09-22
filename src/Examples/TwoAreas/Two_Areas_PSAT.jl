# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/TwoAreas/Two_Areas_PSAT.mo, transcribed automatically (2026-09-16);
# reviewed by hand. The same 11-bus two-area network as `Two_Areas_PSSE` (batch 4) with PSAT models: four 900 MVA
# Order6 without controls, four PSAT transformers, eight lines, two `ZIP(Pz = 0, Pi = 1, Qz = Qi = 0)` loads at
# buses 7 and 9, and a bolted fault at bus 8 from 1 to 1.05 s.
# `r`, `x`, `b` are parameters of the .mo and Julia locals here (they only scale the line data).
# `replaceable Data.PF1 PF_results` is the `PF_results` keyword (F-20 b).
# Omitted: Modelica.Icons.Example, graphical annotations, displayPF.

@component function Two_Areas_PSAT(; name, S_b = 100e6, fn = 60, PF_results = TwoAreas_PF1)
    r = 0.0001            # parameter
    x = 0.001             # parameter
    b = 0.00175 * 0.5     # parameter
    V, M, L = PF_results.voltages, PF_results.machines, PF_results.loads
    systems = @named begin
        bus1 = Bus(; S_b, fn)
        bus2 = Bus(; S_b, fn)
        bus3 = Bus(; S_b, fn)
        bus4 = Bus(; S_b, fn)
        bus5 = Bus(; S_b, fn)
        bus6 = Bus(; S_b, fn)
        bus7 = Bus(; S_b, fn)
        bus8 = Bus(; S_b, fn)
        bus9 = Bus(; S_b, fn)
        bus10 = Bus(; S_b, fn)
        bus11 = Bus(; S_b, fn)
        g1 = TwoAreas_PSAT_G1(; V_b = 20000.0, v_0 = V.V1, angle_0 = V.A1, P_0 = M.P1_1, Q_0 = M.Q1_1, S_b, fn)
        g2 = TwoAreas_PSAT_G2(; v_0 = V.V2, angle_0 = V.A2, P_0 = M.P2_1, Q_0 = M.Q2_1, V_b = 20000.0, S_b, fn)
        g3 = TwoAreas_PSAT_G3(; v_0 = V.V3, angle_0 = V.A3, P_0 = M.P3_1, Q_0 = M.Q3_1, V_b = 20000.0, S_b, fn)
        g4 = TwoAreas_PSAT_G4(; v_0 = V.V4, angle_0 = V.A4, P_0 = M.P4_1, Q_0 = M.Q4_1, V_b = 20000.0, S_b, fn)
        Line6_7 = PwLine(; R = r * 10, X = x * 10, G = 0.0, B = b * 10, S_b, fn)
        Line5_6 = PwLine(; R = r * 25, X = x * 25, G = 0.0, B = b * 25, S_b, fn)
        Line7_8_1 = PwLine(; R = r * 110, X = x * 110, G = 0.0, B = b * 110 / 2, S_b, fn)
        Line7_8_2 = PwLine(; R = r * 110, X = x * 110, G = 0.0, B = b * 110, S_b, fn)
        Line8_9_2 = PwLine(; R = r * 110, X = x * 110, G = 0.0, B = b * 110, S_b, fn)
        Line8_9_1 = PwLine(; R = r * 110, X = x * 110, G = 0.0, B = b * 110 / 2, S_b, fn)
        Line9_10 = PwLine(; R = r * 10, X = x * 10, G = 0.0, B = b * 10, S_b, fn)
        Line10_11 = PwLine(; R = r * 25, X = x * 25, G = 0.0, B = b * 25, S_b, fn)
        pwFault = PwFault(; R = 0.0, t1 = 1.0, t2 = 1.050, X = 1e-5)
        Load7 = ZIP(; Pz = 0.0, Pi = 1.0, Qz = 0.0, Qi = 0.0, V_b = 230000.0, v_0 = V.V7, angle_0 = V.A7,
            P_0 = L.PL7_1, Q_0 = L.QL7_1, S_b, fn)
        Load9 = ZIP(; Pz = 0.0, Pi = 1.0, Qz = 0.0, Qi = 0.0, V_b = 230000.0, v_0 = V.V9, angle_0 = V.A9,
            P_0 = L.PL9_1, Q_0 = L.QL9_1, S_b, fn)
        trafo1 = TwoWindingTransformer(; Sn = 900000000.0, V_b = 20000.0, Vn = 20000.0, rT = 0.0, xT = 0.15, S_b, fn)
        trafo2 = TwoWindingTransformer(; Sn = 900000000.0, V_b = 20000.0, Vn = 20000.0, rT = 0.0, xT = 0.15, S_b, fn)
        trafo3 = TwoWindingTransformer(; Sn = 900000000.0, V_b = 20000.0, Vn = 20000.0, rT = 0.0, xT = 0.15, S_b, fn)
        trafo4 = TwoWindingTransformer(; Sn = 900000000.0, V_b = 20000.0, Vn = 20000.0, rT = 0.0, xT = 0.15, S_b, fn)
    end
    eqs = Equation[
        connect(g1.pwPin, bus1.p),
        connect(g2.pwPin, bus2.p),
        connect(Line6_7.n, bus7.p),
        connect(Line6_7.p, bus6.p),
        connect(Line5_6.n, bus6.p),
        connect(Line5_6.p, bus5.p),
        connect(Line8_9_2.n, bus9.p),
        connect(Line8_9_1.n, bus9.p),
        connect(Line8_9_2.p, bus8.p),
        connect(Line8_9_1.p, bus8.p),
        connect(Line7_8_2.n, bus8.p),
        connect(Line7_8_1.n, bus8.p),
        connect(Line7_8_1.p, bus7.p),
        connect(Line7_8_2.p, bus7.p),
        connect(bus9.p, Line9_10.p),
        connect(Line9_10.n, bus10.p),
        connect(bus10.p, Line10_11.p),
        connect(Line10_11.n, bus11.p),
        connect(g4.pwPin, bus4.p),
        connect(g3.pwPin, bus3.p),
        connect(Load7.p, bus7.p),
        connect(Load9.p, Line9_10.p),
        connect(pwFault.p, bus8.p),
        connect(bus1.p, trafo1.p),
        connect(bus5.p, trafo1.n),
        connect(bus2.p, trafo2.p),
        connect(trafo2.n, bus6.p),
        connect(trafo4.n, bus10.p),
        connect(trafo4.p, bus4.p),
        connect(trafo3.p, bus3.p),
        connect(bus11.p, trafo3.n),
    ]
    System(eqs, t, [], []; name, systems)
end
