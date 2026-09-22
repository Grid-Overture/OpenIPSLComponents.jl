# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/IEEE14/IEEE_14_Buses.mo, transcribed automatically (2026-09-16);
# reviewed by hand.
# The IEEE 14-bus 5-machine base system: `GroupBus1` (Order5_Type2 of 615 MVA) at B1, `GroupBus2` (Order6 of 60 MVA)
# at B2 and three synchronous condensers (`GroupBus3`, `GroupBus6`, `GroupBus8`, whose `P_0` is 1e-15*S_b or 0),
# sixteen lines, four PSAT transformers (three with a fixed tap ratio `m`), eleven `VoltageDependent` loads,
# `pwLinewithOpeningSending(opening = 2, t1 = 20, t2 = 25)` whose opening is outside the 10 s horizon, and a bolted
# fault at B4 from 1 to 1.2 s.
# No machine declares `delta(fixed = true)` here, so OpenModelica's initialization is under-determined and it fixes
# what it fixes (F-28, F-57's mechanism); baseMachine's own `delta`/`w` initial conditions are the Julia choice
# (F-11), and `Order5_Type2.e1q` needs no `u0` because OpenModelica does not fix it either (probe with
# -d=initialization, 2026-09-16, correcting PLAN-06's expectation).
# Omitted: Modelica.Icons.Example, graphical annotations, displayPF.

@component function IEEE_14_Buses(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        B1 = Bus(; V_b = 69000.0, v_0 = 1.060, S_b, fn)
        B2 = Bus(; V_b = 69000.0, v_0 = 1.045, S_b, fn)
        B3 = Bus(; V_b = 69000.0, v_0 = 1.01, S_b, fn)
        B4 = Bus(; V_b = 69000.0, v_0 = 0.99782, S_b, fn)
        B5 = Bus(; V_b = 69000.0, v_0 = 1.0029, S_b, fn)
        B6 = Bus(; V_b = 13800.0, v_0 = 1.07, S_b, fn)
        B7 = Bus(; v_0 = 1.09, V_b = 13800.0, S_b, fn)
        B8 = Bus(; v_0 = 1.09, V_b = 18000.0, S_b, fn)
        B9 = Bus(; v_0 = 1.0129, V_b = 13800.0, S_b, fn)
        B10 = Bus(; V_b = 13800.0, v_0 = 1.0122, S_b, fn)
        B11 = Bus(; V_b = 13800.0, v_0 = 1.0357, S_b, fn)
        B12 = Bus(; V_b = 13800.0, v_0 = 1.0462, S_b, fn)
        B13 = Bus(; V_b = 13800.0, v_0 = 1.0366, S_b, fn)
        B14 = Bus(; v_0 = 0.99695, V_b = 13800.0, S_b, fn)
        L1 = PwLine(; R = 0.05695, X = 0.17388, G = 0.0, B = 0.034 / 2, S_b, fn)
        L7 = PwLine(; G = 0.0, R = 0.05403, X = 0.22304, B = 0.0492 / 2, S_b, fn)
        L3 = PwLine(; G = 0.0, R = 0.01938, X = 0.05917, B = 0.0528 / 2, S_b, fn)
        L6 = PwLine(; G = 0.0, R = 0.06701, X = 0.17103, B = 0.0346 / 2, S_b, fn)
        L8 = PwLine(; G = 0.0, R = 0.01335, X = 0.04211, B = 0.0128 / 2, S_b, fn)
        L13 = PwLine(; G = 0.0, R = 0.09498, X = 0.1989, B = 0.0, S_b, fn)
        L10 = PwLine(; G = 0.0, R = 0.12291, X = 0.25581, B = 0.0, S_b, fn)
        L12 = PwLine(; G = 0.0, R = 0.06615, X = 0.13027, B = 0.0, S_b, fn)
        L14 = PwLine(; G = 0.0, B = 0.0, R = 0.08205, X = 0.19207, S_b, fn)
        L15 = PwLine(; G = 0.0, B = 0.0, R = 0.03181, X = 0.0845, S_b, fn)
        L16 = PwLine(; G = 0.0, B = 0.0, R = 0.12711, X = 0.27038, S_b, fn)
        L17 = PwLine(; G = 0.0, B = 0.0, R = 0.17093, X = 0.34802, S_b, fn)
        L2 = PwLine(; G = 0.0, B = 0.0, R = 0.0, X = 0.11001, S_b, fn)
        L5 = PwLine(; G = 0.0, R = 0.04699, X = 0.19797, B = 0.0438 / 2, S_b, fn)
        L11 = PwLine(; G = 0.0, B = 0.0, R = 0.22092, X = 0.19988, S_b, fn)
        lPQ2 = VoltageDependent(; V_b = 69000.0, v_0 = 1.00292, angle_0 = -0.234469, P_0 = 10640000.0,
            Q_0 = 2240000.0, S_b, fn)
        lPQ3 = VoltageDependent(; v_0 = 1.045, V_b = 69000.0, angle_0 = -0.1431934, P_0 = 30380000.0,
            Q_0 = 17780000.0, S_b, fn)
        lPQ12 = VoltageDependent(; v_0 = 1.01, V_b = 69000.0, angle_0 = -0.33964, P_0 = 131880000.0,
            Q_0 = 26600000.0, S_b, fn)
        lPQ9 = VoltageDependent(; V_b = 13800.0, v_0 = 1.0129, angle_0 = -0.38659, P_0 = 41300000.0,
            Q_0 = 23240000.0, S_b, fn)
        lPQ6 = VoltageDependent(; V_b = 13800.0, v_0 = 0.996954, angle_0 = -0.4180744, P_0 = 20860000.0,
            Q_0 = 7000000.0, S_b, fn)
        lPQ8 = VoltageDependent(; V_b = 13800.0, v_0 = 1.01219, angle_0 = -0.391978, P_0 = 12600000.0,
            Q_0 = 8120000.0, S_b, fn)
        lPQ11 = VoltageDependent(; V_b = 13800.0, v_0 = 1.03659, angle_0 = -0.39899, P_0 = 18900000.0,
            Q_0 = 8120000.0, S_b, fn)
        lPQ7 = VoltageDependent(; V_b = 13800.0, v_0 = 1.04615, angle_0 = -0.398104, P_0 = 8540000.0,
            Q_0 = 2240000.0, S_b, fn)
        lPQ10 = VoltageDependent(; V_b = 13800.0, v_0 = 1.03565, angle_0 = -0.3873584, P_0 = 4900000.0,
            Q_0 = 2520000.0, S_b, fn)
        lPQ4 = VoltageDependent(; v_0 = 1.07, V_b = 13800.0, angle_0 = -0.37708, P_0 = 15680000.0,
            Q_0 = 10500000.0, S_b, fn)
        lPQ5 = VoltageDependent(; V_b = 69000.0, v_0 = 0.997818, angle_0 = -0.2719275, P_0 = 66920000.0,
            Q_0 = 5600000.0, S_b, fn)
        twoWindingTransformer = TwoWindingTransformer(; V_b = 18000.0, Vn = 18000.0, rT = 0.0, xT = 0.17615, S_b, fn)
        tWTransformerWithFixedTapRatio = TwoWindingTransformer(; m = 0.932, V_b = 69000.0, Vn = 69000.0, rT = 0.0,
            xT = 0.25202, S_b, fn)
        tWTransformerWithFixedTapRatio1 = TwoWindingTransformer(; m = 0.969, V_b = 69000.0, Vn = 69000.0, rT = 0.0,
            xT = 0.55618, S_b, fn)
        tWTransformerWithFixedTapRatio2 = TwoWindingTransformer(; m = 0.978, V_b = 69000.0, Vn = 69000.0, rT = 0.0,
            xT = 0.20912, S_b, fn)
        gen2 = GroupBus2(; V_b = 69000.0, v_0 = 1.045, P_0 = 0.400000000000003 * S_b, Q_0 = 0.948604 * S_b,
            angle_0 = -0.143192, S_b, fn)
        gen3 = GroupBus3(; V_b = 69000.0, v_0 = 1.01, P_0 = 0.000000000000001 * S_b, Q_0 = 0.597359 * S_b,
            angle_0 = -0.3396376, S_b, fn)
        gen6 = GroupBus6(; V_b = 13800.0, v_0 = 1.07, P_0 = 0.000000000000039 * S_b, angle_0 = -0.37708,
            Q_0 = 0.444329 * S_b, S_b, fn)
        gen8 = GroupBus8(; V_b = 18000.0, v_0 = 1.09, P_0 = -0.000000000000000 * S_b, Q_0 = 0.334022 * S_b,
            angle_0 = -0.346893, S_b, fn)
        pwLinewithOpeningSending = PwLine(; R = 0.05811, X = 0.17632, G = 0.0, B = 0.0374 / 2, t2 = 25.0, t1 = 20.0,
            opening = 2, S_b, fn)
        pwFault2 = PwFault(; X = 1e-5, t1 = 1.0, R = 0.0, t2 = 1.2)
        gen1 = GroupBus1(; V_b = 69000.0, v_0 = 1.06, angle_0 = -0.00751491652, P_0 = 3.5203 * S_b,
            Q_0 = -0.281968 * S_b, S_b, fn)
    end
    eqs = Equation[
        connect(B12.p, L11.p),
        connect(L10.p, B6.p),
        connect(B3.p, L6.p),
        connect(B1.p, L3.p),
        connect(B4.p, L6.n),
        connect(B4.p, L8.n),
        connect(B5.p, lPQ2.p),
        connect(lPQ5.p, B4.p),
        connect(lPQ11.p, B13.p),
        connect(B10.p, L15.n),
        connect(B10.p, L14.n),
        connect(B13.p, L12.n),
        connect(L16.n, B14.p),
        connect(B9.p, lPQ9.p),
        connect(B11.p, lPQ10.p),
        connect(B11.p, L14.p),
        connect(lPQ4.p, B6.p),
        connect(B6.p, L12.p),
        connect(lPQ7.p, B12.p),
        connect(B13.p, L11.n),
        connect(L10.n, B12.p),
        connect(B3.p, lPQ12.p),
        connect(B3.p, L5.p),
        connect(B7.p, L2.p),
        connect(B9.p, L2.n),
        connect(B2.p, lPQ3.p),
        connect(B2.p, L1.p),
        connect(L1.n, B5.p),
        connect(B1.p, L7.p),
        connect(B5.p, L7.n),
        connect(B7.p, twoWindingTransformer.n),
        connect(twoWindingTransformer.p, B8.p),
        connect(B4.p, tWTransformerWithFixedTapRatio1.p),
        connect(B5.p, tWTransformerWithFixedTapRatio.p),
        connect(B6.p, tWTransformerWithFixedTapRatio.n),
        connect(gen2.pwPin, B2.p),
        connect(gen3.pwPin, B3.p),
        connect(gen6.pwPin, B6.p),
        connect(B4.p, tWTransformerWithFixedTapRatio2.p),
        connect(B7.p, tWTransformerWithFixedTapRatio2.n),
        connect(B9.p, tWTransformerWithFixedTapRatio1.n),
        connect(B6.p, L13.p),
        connect(L13.n, B11.p),
        connect(B5.p, L8.p),
        connect(B8.p, gen8.pwPin),
        connect(L15.p, B9.p),
        connect(B9.p, L16.p),
        connect(B14.p, L17.p),
        connect(B13.p, L17.n),
        connect(lPQ8.p, B10.p),
        connect(lPQ6.p, L17.p),
        connect(B2.p, pwLinewithOpeningSending.p),
        connect(B4.p, pwLinewithOpeningSending.n),
        connect(L5.n, B2.p),
        connect(L3.n, B2.p),
        connect(gen1.pwPin, B1.p),
        connect(B4.p, pwFault2.p),
    ]
    System(eqs, t, [], []; name, systems)
end
