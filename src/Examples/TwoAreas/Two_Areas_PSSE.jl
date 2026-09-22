# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/TwoAreas/Two_Areas_PSSE.mo, drafted automatically (2026-09-14);
# reviewed by hand. extends: none (Modelica.Icons.Example is graphical). Omitted: graphical annotations, displayPF.
# The 11-bus, 4-machine, 2-area Kundur system with GENSAL machines and no controls. `inner SystemBase SysData(fn = 60)`
# is the pair of keyword arguments S_b (SystemBase default 100e6) and fn passed to every component; the
# `replaceable Data.PF2 PF_results constrainedby Support.PF_TwoAreas` record is the keyword `PF_results`, a NamedTuple
# (Data/PF2.jl) whose fields are read as in the .mo. `r`, `x`, `b` are the .mo's system parameters: they only scale
# the line data, so they are Julia numbers here (a PwLine takes numbers, F-22). The fault sits on bus 8 (t1 = 3 s,
# t2 = 3.2 s, X = 1e-5). Line7_8_1/2 and Line8_9_1/2 are identical parallel pairs (F-21, F-30).

@component function Two_Areas_PSSE(; name, S_b = 100e6, fn = 60, PF_results = TwoAreas_PF2)
    r = 0.0001   # parameter
    x = 0.001   # parameter
    b = 0.00175 * 0.5   # parameter
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
        g1 = TwoAreas_NoControls_G1(; v_0 = V.V1, angle_0 = V.A1, P_0 = M.P1_1, Q_0 = M.Q1_1, S_b, fn)
        g2 = TwoAreas_NoControls_G2(; v_0 = V.V2, angle_0 = V.A2, P_0 = M.P2_1, Q_0 = M.Q2_1, S_b, fn)
        g3 = TwoAreas_NoControls_G3(; v_0 = V.V3, angle_0 = V.A3, P_0 = M.P3_1, Q_0 = M.Q3_1, S_b, fn)
        g4 = TwoAreas_NoControls_G4(; v_0 = V.V4, angle_0 = V.A4, P_0 = M.P4_1, Q_0 = M.Q4_1, S_b, fn)
        Line6_7 = PwLine(; R = r * 10, X = x * 10, G = 0.0, B = b * 10, S_b, fn)
        Line5_6 = PwLine(; R = r * 25, X = x * 25, G = 0.0, B = b * 25, S_b, fn)
        Line7_8_1 = PwLine(; R = r * 110, X = x * 110, G = 0.0, B = b * 110, S_b, fn)
        Line7_8_2 = PwLine(; R = r * 110, X = x * 110, G = 0.0, B = b * 110, S_b, fn)
        Line8_9_2 = PwLine(; R = r * 110, X = x * 110, G = 0.0, B = b * 110, S_b, fn)
        Line8_9_1 = PwLine(; R = r * 110, X = x * 110, G = 0.0, B = b * 110, S_b, fn)
        Line9_10 = PwLine(; R = r * 10, X = x * 10, G = 0.0, B = b * 10, S_b, fn)
        Line10_11 = PwLine(; R = r * 25, X = x * 25, G = 0.0, B = b * 25, S_b, fn)
        pwFault = PwFault(; X = 1e-5, R = 0.0, t1 = 3.0, t2 = 3.2)
        Load7 = Load(; PQBRAK = 0.7, v_0 = V.V7, angle_0 = V.A7, P_0 = L.PL7_1, Q_0 = L.QL7_1, S_b, fn)
        Load9 = Load(; PQBRAK = 0.7, v_0 = V.V9, angle_0 = V.A9, P_0 = L.PL9_1, Q_0 = L.QL9_1, S_b, fn)
        Line5_1 = PwLine(; G = 0.0, R = 0.0, X = 0.01667, B = 0.0, S_b, fn)
        Line5_2 = PwLine(; G = 0.0, R = 0.0, X = 0.01667, B = 0.0, S_b, fn)
        Line5_3 = PwLine(; G = 0.0, R = 0.0, X = 0.01667, B = 0.0, S_b, fn)
        Line5_4 = PwLine(; G = 0.0, R = 0.0, X = 0.01667, B = 0.0, S_b, fn)
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
        connect(bus1.p, Line5_1.p),
        connect(bus5.p, Line5_1.n),
        connect(bus2.p, Line5_2.p),
        connect(Line5_2.n, bus6.p),
        connect(bus11.p, Line5_3.p),
        connect(Line5_3.n, bus3.p),
        connect(bus4.p, Line5_4.n),
        connect(Line5_4.p, Line10_11.p),
    ]
    System(eqs, t, [], []; name, systems)
end
