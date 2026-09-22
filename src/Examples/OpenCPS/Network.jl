# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/OpenCPS/Network.mo (extends nothing; Modelica.Icons.Example is graphical)
# The OpenCPS resynchronization bench on S_b = 100 MVA, fn = 50 Hz: `G1` (GENSAL + SEXS + HYGOV) on BG1, the
# 220 kV path BG1-T1-B1-L1-B2-(L2_1 || L2_2)-B3 with `LD1` on B2 and the infinite bus `IB` (a GENCLS with
# X_d = 0.2) on B3, and the island `B4`-`LD2`-`T2`-`B5`-`G2` fed from B3 through `L3` and `breaker1`, which is
# open at t = 0 and closes when `G2.central_Unit` says so.
# The four `protected RealOutput` of the .mo (`V_IB = B3.v`, `fi_IB = B3.angle`, `V_DN = B4.v`,
# `fi_DN = B4.angle`) are plain variables with their four equations; OpenModelica writes them as variables of the
# system, so they are compared as such.
# Named `OpenCPS_Network` (JULIA_NAMES, precedent `SevenBus_Network`). Omitted: graphical annotations, displayPF,
# `inner SystemBase SysData`.

@component function OpenCPS_Network(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        BG1 = Bus(; S_b, fn)
        B1 = Bus(; S_b, fn)
        T1 = PSSE_TwoWindingTransformer(; R = 0.001, X = 0.2, G = 0, B = 0, VNOM1 = 220e3, VB1 = 220e3,
            VNOM2 = 24e3, VB2 = 24e3, S_b, fn)
        G1 = OpenCPS_G1(; v_0 = 1, angle_0 = 0.15656662805, P_0 = 40e6, Q_0 = 4547321, V_b = 24e3, S_b, fn)
        L1 = PwLine(; R = 0.001, X = 0.2, G = 0, B = 0, S_b, fn)
        B2 = Bus(; S_b, fn)
        B3 = Bus(; S_b, fn)
        L2_1 = PwLine(; R = 0.0005, X = 0.1, G = 0, B = 0, S_b, fn)
        L2_2 = PwLine(; R = 0.0005, X = 0.1, G = 0, B = 0, S_b, fn)
        IB = GENCLS(; V_b = 220e3, v_0 = 1, angle_0 = 0, P_0 = 10067010.00, Q_0 = 12058260.00, M_b = 100e6,
            X_d = 0.2, S_b, fn)
        B4 = Bus(; angle_0 = -0.1075140447, v_0 = 0.9291416, S_b, fn)
        L3 = PwLine(; R = 0.001, X = 0.2, G = 0, B = 0, S_b, fn)
        B5 = Bus(; S_b, fn)
        T2 = PSSE_TwoWindingTransformer(; G = 0, B = 0, VNOM1 = 220e3, VB1 = 220e3, VNOM2 = 24e3, VB2 = 24e3,
            R = 0.005, X = 0.1, S_b, fn)
        LD2 = Load(; V_b = 220e3, P_0 = 10e6, v_0 = 0.9893408, angle_0 = -0.00960250483, Q_0 = 10e6, S_b, fn)
        G2 = OpenCPS_G2(; v_0 = 1, angle_0 = 0, V_b = 24e3, P_0 = 10010220.00, Q_0 = 10204330.00, S_b, fn)
        LD1 = Load(; V_b = 220e3, v_0 = 0.9939582, angle_0 = -0.00501670109, P_0 = 50e6, Q_0 = 10e6, S_b, fn)
        breaker1 = OpenCPS_Breaker()
    end
    vars = @variables begin
        V_IB(t), [description = "Voltage magnitude of the infinite-bus side (pu)"]
        V_DN(t), [description = "Voltage magnitude of the islanded side (pu)"]
        fi_IB(t), [description = "Voltage angle of the infinite-bus side (rad)"]
        fi_DN(t), [description = "Voltage angle of the islanded side (rad)"]
    end
    eqs = Equation[
        V_IB ~ B3.v,
        fi_IB ~ B3.angle,
        V_DN ~ B4.v,
        fi_DN ~ B4.angle,
        connect(T1.p, B1.p),
        connect(BG1.p, T1.n),
        connect(G1.conn, BG1.p),
        connect(L1.n, B2.p),
        connect(L1.p, B1.p),
        connect(L2_2.n, B3.p),
        connect(L2_1.n, B3.p),
        connect(L2_1.p, B2.p),
        connect(L2_2.p, B2.p),
        connect(T2.p, B4.p),
        connect(T2.n, B5.p),
        connect(LD2.p, B4.p),
        connect(G2.conn, B5.p),
        connect(LD1.p, B2.p),
        connect(L3.n, breaker1.n),
        connect(B4.p, breaker1.p),
        G2.V_DN ~ V_DN,                # connect(V_DN, G2.V_DN)
        G2.V_IB ~ V_IB,                # connect(V_IB, G2.V_IB)
        fi_DN ~ G2.fi_DN,              # connect(G2.fi_DN, fi_DN)
        fi_IB ~ G2.fi_IB,              # connect(G2.fi_IB, fi_IB)
        breaker1.TRIGGER ~ G2.TRIGGER, # connect(breaker1.TRIGGER, G2.TRIGGER)
        connect(L3.p, B3.p),
        connect(IB.p, B3.p),
    ]
    System(eqs, t, vars, []; name, systems)
end
