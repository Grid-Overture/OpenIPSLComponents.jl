# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/PSATSystems/ThreeArea/BaseClasses/BaseNetwork.mo (partial), transcribed by
# the transcriber (2026-09-16, --kind base); reviewed by hand. Named `ThreeArea_BaseNetwork`
# (JULIA_NAMES): `BaseNetwork` also names the TwoArea base.
# The 14-bus PSAT three-area network (B100..B1400): fifteen `PwLine(R = 0, B = 0)` with their own reactances, no
# loads and no transformers, a resistive fault `PwFault(R = 0.15, X = 0)` at the B1000-B1100 branch from 2 to 2.1 s,
# an `Order3` of 900 MVA at B1200 (vf <- vf0 in the base, overridden by the exciter of the child of `SixthOrder_AVRIII`
# through its own connection: here only `pm <- pm0` is wired) and an `Order2` at B100 that **absorbs** 100 MW, with
# vf <- vf0 and pm <- pm0.
# Omitted: graphical annotations, displayPF.
@component function ThreeArea_BaseNetwork(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        order3_2 = Order3(; Sn = 900000000.0, Vn = 1000.0, ra = 0.0, xd = 1.8, x1d = 0.3, M = 7.0, v_0 = 1.05,
            angle_0 = 0.755059086011694, P_0 = 50000000.0000002, Q_0 = 21915765.9600514, D = 2.0, T1d0 = 8.0,
            xq = 1.7, V_b = 1000.0, S_b, fn)
        order2 = Order2(; Sn = 900000000.0, v_0 = 1.050000000000000, ra = 0.0, M = 14.0, D = 2.0, x1d = 0.3,
            P_0 = -99999999.9999999, Q_0 = 41391335.7523525, V_b = 1000.0, Vn = 1000.0, S_b, fn)
        B100 = Bus(; S_b, fn)
        B200 = Bus(; S_b, fn)
        B300 = Bus(; S_b, fn)
        B400 = Bus(; S_b, fn)
        B500 = Bus(; S_b, fn)
        B600 = Bus(; S_b, fn)
        B700 = Bus(; S_b, fn)
        B800 = Bus(; S_b, fn)
        B900 = Bus(; S_b, fn)
        B1000 = Bus(; S_b, fn)
        B1100 = Bus(; S_b, fn)
        B1200 = Bus(; S_b, fn)
        B1300 = Bus(; S_b, fn)
        B1400 = Bus(; S_b, fn)
        pwLine1to4 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.1, S_b, fn)
        pwLine1to1 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.1, S_b, fn)
        pwLine1to2 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.2, S_b, fn)
        pwLine1to3 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.1, S_b, fn)
        pwLine1to5 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 1.2, S_b, fn)
        pwLine1to6 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.1, S_b, fn)
        pwLine1to7 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.2, S_b, fn)
        pwLine1to8 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.2, S_b, fn)
        pwLine1to9 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.1, S_b, fn)
        pwLine1to10 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.1, S_b, fn)
        pwLine1to11 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.4, S_b, fn)
        pwLine1to12 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.1, S_b, fn)
        pwLine1to13 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.2, S_b, fn)
        pwLine1to14 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.2, S_b, fn)
        pwLine1to15 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 1.3, S_b, fn)
        pwFault = PwFault(; R = 0.15, X = 0.0, t1 = 2.0, t2 = 2.1)
    end
    eqs = Equation[
        connect(pwLine1to4.n, B100.p),
        connect(pwLine1to4.p, B200.p),
        connect(pwLine1to1.p, B300.p),
        connect(B500.p, pwLine1to11.p),
        connect(B600.p, pwLine1to11.n),
        connect(B600.p, pwLine1to12.p),
        connect(pwLine1to13.n, B700.p),
        connect(pwLine1to13.p, B800.p),
        connect(B400.p, pwLine1to3.p),
        connect(pwLine1to3.n, B900.p),
        connect(B1000.p, pwLine1to9.p),
        connect(pwLine1to9.n, B1100.p),
        connect(B1100.p, pwLine1to10.p),
        connect(pwLine1to10.n, B1200.p),
        connect(pwLine1to15.n, B1000.p),
        connect(pwLine1to15.p, B700.p),
        connect(pwLine1to6.n, B1300.p),
        connect(B1300.p, pwLine1to7.p),
        connect(B1400.p, pwLine1to8.p),
        connect(pwLine1to8.n, B1000.p),
        connect(pwLine1to7.n, B1400.p),
        connect(pwFault.p, pwLine1to9.p),
        connect(pwLine1to5.n, B1000.p),
        connect(pwLine1to6.p, B900.p),
        connect(pwLine1to5.p, B900.p),
        connect(pwLine1to12.n, B700.p),
        connect(pwLine1to2.n, B400.p),
        connect(pwLine1to1.n, B200.p),
        connect(order2.p, B100.p),
        order2.pm0 ~ order2.pm,   # connect(order2.pm0, order2.pm)
        order2.vf0 ~ order2.vf,   # connect(order2.vf0, order2.vf)
        connect(pwLine1to14.n, B500.p),
        connect(pwLine1to14.p, B400.p),
        connect(pwLine1to2.p, B300.p),
        connect(B1200.p, order3_2.p),
        order3_2.pm0 ~ order3_2.pm,   # connect(order3_2.pm0, order3_2.pm)
    ]
    System(eqs, t, [], []; name, systems)
end
