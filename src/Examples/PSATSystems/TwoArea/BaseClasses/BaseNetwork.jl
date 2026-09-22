# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/PSATSystems/TwoArea/BaseClasses/BaseNetwork.mo (partial), transcribed by
# the transcriber (2026-09-16, --kind base); reviewed by hand. Named `TwoArea_BaseNetwork`
# (JULIA_NAMES): `BaseNetwork` also names the ThreeArea base.
# The 31-bus PSAT two-area network: twenty `PwLine(R = 0, X = 0.005, B = 0)`, ten PSAT transformers with
# `xT = 0.005` (the five around the Order3 side carry `Sn = 100e6`, the other five take the default `Sn = S_b`),
# **no loads at all**, a resistive fault `PwFault(R = 0.15, X = 0)` on the B3-B18 branch from 2 to 2.1 s, and an
# `Order3` of 991 MVA at B2 that **absorbs** 110 MW (`P_0 < 0`), with vf <- vf0 and pm <- pm0.
# A network of twenty zero-resistance branches in series with an absorbing machine and no load is PLAN-06's
# candidate for a collapsed-voltage root (F-31, F-52); `Bus` is already `irreducible` (F-30).
# Omitted: graphical annotations, displayPF.
@component function TwoArea_BaseNetwork(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        order3 = Order3(; Sn = 991000000.0, Vn = 20000.0, V_b = 20000.0, v_0 = 1.081, ra = 0.0, xd = 2.0,
            x1d = 0.245, T1d0 = 5.0, xq = 1.91, M = 6.0, D = 0.0, angle_0 = 0.0,
            P_0 = -110000000.0000006, Q_0 = 30378600.0438159, S_b, fn)
        B1 = Bus(; S_b, fn)
        B3 = Bus(; S_b, fn)
        B4 = Bus(; S_b, fn)
        B5 = Bus(; S_b, fn)
        B6 = Bus(; S_b, fn)
        B7 = Bus(; S_b, fn)
        B8 = Bus(; S_b, fn)
        B9 = Bus(; S_b, fn)
        B10 = Bus(; S_b, fn)
        B2 = Bus(; S_b, fn)
        B11 = Bus(; S_b, fn)
        B12 = Bus(; S_b, fn)
        B13 = Bus(; S_b, fn)
        B14 = Bus(; S_b, fn)
        B15 = Bus(; S_b, fn)
        B16 = Bus(; S_b, fn)
        B17 = Bus(; S_b, fn)
        B18 = Bus(; S_b, fn)
        B19 = Bus(; S_b, fn)
        B20 = Bus(; S_b, fn)
        B21 = Bus(; S_b, fn)
        B22 = Bus(; S_b, fn)
        B23 = Bus(; S_b, fn)
        B24 = Bus(; S_b, fn)
        B25 = Bus(; S_b, fn)
        B26 = Bus(; S_b, fn)
        B27 = Bus(; S_b, fn)
        B28 = Bus(; S_b, fn)
        B29 = Bus(; S_b, fn)
        B30 = Bus(; S_b, fn)
        B31 = Bus(; S_b, fn)
        L410 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L1011 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L1112 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L1213 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L1314 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L1415 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L1516 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L1617 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L1718 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L318 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L319 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L1920 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L2021 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L2122 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L2223 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L2324 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L2425 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L2526 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L2627 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        L527 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.005, S_b, fn)
        pwFault = PwFault(; R = 0.15, X = 0.0, t1 = 2.0, t2 = 2.1)
        Tr16 = TwoWindingTransformer(; V_b = 20000.0, Vn = 20000.0, Sn = 100000000.0, rT = 0.0, xT = 0.005, S_b, fn)
        Tr67 = TwoWindingTransformer(; V_b = 20000.0, Vn = 20000.0, Sn = 100000000.0, rT = 0.0, xT = 0.005, S_b, fn)
        Tr78 = TwoWindingTransformer(; V_b = 20000.0, Vn = 20000.0, Sn = 100000000.0, rT = 0.0, xT = 0.005, S_b, fn)
        Tr89 = TwoWindingTransformer(; V_b = 20000.0, Vn = 20000.0, Sn = 100000000.0, rT = 0.0, xT = 0.005, S_b, fn)
        Tr49 = TwoWindingTransformer(; V_b = 20000.0, Vn = 20000.0, Sn = 100000000.0, rT = 0.0, xT = 0.005, S_b, fn)
        Tr528 = TwoWindingTransformer(; V_b = 20000.0, Vn = 20000.0, rT = 0.0, xT = 0.005, S_b, fn)
        Tr2829 = TwoWindingTransformer(; V_b = 20000.0, Vn = 20000.0, rT = 0.0, xT = 0.005, S_b, fn)
        Tr2930 = TwoWindingTransformer(; V_b = 20000.0, Vn = 20000.0, rT = 0.0, xT = 0.005, S_b, fn)
        Tr3031 = TwoWindingTransformer(; V_b = 20000.0, Vn = 20000.0, rT = 0.0, xT = 0.005, S_b, fn)
        Tr231 = TwoWindingTransformer(; V_b = 20000.0, Vn = 20000.0, rT = 0.0, xT = 0.005, S_b, fn)
    end
    eqs = Equation[
        connect(Tr67.n, B7.p),
        connect(Tr67.p, B6.p),
        connect(Tr16.n, B6.p),
        connect(Tr16.p, B1.p),
        connect(L410.n, B10.p),
        connect(L1011.n, B11.p),
        connect(B11.p, L1112.p),
        connect(B14.p, L1415.p),
        connect(B15.p, L1516.p),
        connect(B16.p, L1617.p),
        connect(L1617.n, B17.p),
        connect(L319.n, B3.p),
        connect(L319.p, B19.p),
        connect(L1920.n, B19.p),
        connect(L1920.p, B20.p),
        connect(L2021.n, B20.p),
        connect(L2021.p, B21.p),
        connect(L2122.n, B21.p),
        connect(L2122.p, B22.p),
        connect(L2223.n, B22.p),
        connect(L2223.p, B23.p),
        connect(L2324.p, B24.p),
        connect(L2526.n, B25.p),
        connect(L2526.p, B26.p),
        connect(B26.p, L2627.p),
        connect(L2627.n, B27.p),
        connect(B27.p, L527.n),
        connect(L527.p, B5.p),
        connect(Tr231.n, B2.p),
        connect(Tr231.p, B31.p),
        connect(Tr3031.n, B31.p),
        connect(Tr3031.p, B30.p),
        connect(Tr2930.n, B30.p),
        connect(Tr2930.p, B29.p),
        connect(Tr2829.n, B29.p),
        connect(Tr528.n, B28.p),
        connect(Tr528.p, B5.p),
        connect(Tr78.p, B7.p),
        connect(Tr78.n, B8.p),
        connect(Tr89.p, B8.p),
        connect(Tr89.n, B9.p),
        connect(B10.p, L1011.p),
        connect(L1112.n, B12.p),
        connect(B12.p, L1213.p),
        connect(L1213.n, B13.p),
        connect(B13.p, L1314.p),
        connect(L1314.n, B14.p),
        connect(L1415.n, B15.p),
        connect(L1516.n, B16.p),
        connect(B9.p, Tr49.p),
        connect(B4.p, L410.p),
        connect(Tr49.n, B4.p),
        connect(L1718.n, B18.p),
        connect(B17.p, L1718.p),
        connect(B25.p, L2425.p),
        connect(L2425.n, B24.p),
        connect(L2324.n, B23.p),
        connect(B3.p, L318.n),
        connect(L318.p, B18.p),
        connect(pwFault.p, L318.n),
        connect(B28.p, Tr2829.p),
        connect(B2.p, order3.p),
        order3.pm ~ order3.pm0,   # connect(order3.pm, order3.pm0)
        order3.vf ~ order3.vf0,   # connect(order3.vf, order3.vf0)
    ]
    System(eqs, t, [], []; name, systems)
end
