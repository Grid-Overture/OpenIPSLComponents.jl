# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/BaseClasses/TGTestBase.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# `p0` is a parameter of the .mo that the base itself does not use (TGTypeI_test redeclares it with the same value and
# passes it as `pref`): a keyword argument. `gen`'s delta(fixed = true), w(fixed = true) are already the
# `initial_conditions` of baseMachine (F-20), so the modifiers need no extra handling. No Test of batch 6 modifies a
# component of this base, so it takes no `mods`.
@component function TGTestBase(; name, S_b = 100e6, fn = 50, p0 = 0.160352698692006)
    systems = @named begin
        pwLoadPQ1 = PQ(; angle_0 = 0.0, P_0 = 80000.0, Q_0 = 60000.0, v_0 = 1.0, S_b, fn)
        pwLineFault = PwLine(; B = 0.001 / 2, G = 0.0, R = 0.01, X = 0.1, t1 = 8.0, t2 = 8.1, S_b, fn)
        pwLine3 = PwLine(; B = 0.001 / 2, G = 0.0, R = 0.01, X = 0.1, S_b, fn)
        pwLine4 = PwLine(; B = 0.001 / 2, G = 0.0, R = 0.01, X = 0.1, S_b, fn)
        pwLoadPQ2 = PQ(; angle_0 = 0.0, P_0 = 80000.0, Q_0 = 60000.0, v_0 = 1.0, S_b, fn)
        pwLine1 = PwLine(; B = 0.001 / 2, G = 0.0, R = 0.01, X = 0.1, S_b, fn)
        pwLine2 = PwLine(; B = 0.001 / 2, G = 0.0, R = 0.01, X = 0.1, S_b, fn)
        pwFault = PwFaultPQ(; X = 0.001, t1 = 3.0, t2 = 3.1, R = 10.0)
        gen = Order3(; D = 0.0, M = 10.0, P_0 = 160410.0, Q_0 = 120120.0, Sn = 20000000.0, T1d0 = 8.0,
            V_b = 400000.0, Vn = 400000.0, angle_0 = 0.0, ra = 0.001, v_0 = 1.0, x1d = 0.302, xd = 1.9, xq = 1.7,
            S_b, fn)
        bus1 = Bus(; S_b, fn)
        bus2 = Bus(; S_b, fn)
        bus3 = Bus(; S_b, fn)
        bus4 = Bus(; S_b, fn)
    end
    pars = @parameters begin
        p0 = p0, [description = "Power flow, node active power"]
    end
    eqs = Equation[
        gen.vf ~ gen.vf0,   # connect(gen.vf0, gen.vf)
        connect(gen.p, bus1.p),
        connect(bus1.p, pwLine1.p),
        connect(bus1.p, pwLine2.p),
        connect(bus2.p, pwLine1.n),
        connect(bus2.p, pwLine2.n),
        connect(bus2.p, pwLine3.p),
        connect(bus2.p, pwLine4.p),
        connect(pwLine4.n, bus3.p),
        connect(bus3.p, pwLoadPQ2.p),
        connect(bus4.p, pwLine3.n),
        connect(bus4.p, pwLoadPQ1.p),
        connect(bus4.p, pwLineFault.n),
        connect(bus3.p, pwFault.p),
        connect(pwLineFault.p, pwLine3.p),
    ]
    System(eqs, t, [], pars; name, systems)
end
