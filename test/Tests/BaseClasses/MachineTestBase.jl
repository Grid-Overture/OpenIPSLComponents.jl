# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/BaseClasses/MachineTestBase.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function MachineTestBase(; name, S_b = 100e6, fn = 50, mods = (;))
    pwLine1 = redeclared(mods, :pwLine1, PwLine)(; name = :pwLine1, modified(mods, :pwLine1, (; X = 0.1, R = 0.01, G = 0.0, B = 0.0005, S_b, fn))...)
    pwLinewithOpening1 = redeclared(mods, :pwLinewithOpening1, PwLine)(; name = :pwLinewithOpening1, modified(mods, :pwLinewithOpening1, (; G = 0.0, R = 0.01, X = 0.1, opening = 1, B = 0.0005, t1 = 2.0, t2 = 2.15, S_b, fn))...)
    pwLine2 = redeclared(mods, :pwLine2, PwLine)(; name = :pwLine2, modified(mods, :pwLine2, (; G = 0.0, R = 0.01, X = 0.1, B = 0.0005, S_b, fn))...)
    pwLine3 = redeclared(mods, :pwLine3, PwLine)(; name = :pwLine3, modified(mods, :pwLine3, (; G = 0.0, R = 0.01, X = 0.1, B = 0.0005, S_b, fn))...)
    pwLine4 = redeclared(mods, :pwLine4, PwLine)(; name = :pwLine4, modified(mods, :pwLine4, (; G = 0.0, R = 0.01, X = 0.1, B = 0.0005, S_b, fn))...)
    pwLoadPQ1 = redeclared(mods, :pwLoadPQ1, PQ)(; name = :pwLoadPQ1, modified(mods, :pwLoadPQ1, (; P_0 = 8000000.0, Q_0 = 6000000.0, S_b, fn))...)
    pwLoadPQ2 = redeclared(mods, :pwLoadPQ2, PQvar)(; name = :pwLoadPQ2, modified(mods, :pwLoadPQ2, (; P_0 = 8000000.0, Q_0 = 6000000.0, S_b, fn))...)
    bus1 = redeclared(mods, :bus1, Bus)(; name = :bus1, modified(mods, :bus1, (; S_b, fn))...)
    bus2 = redeclared(mods, :bus2, Bus)(; name = :bus2, modified(mods, :bus2, (; S_b, fn))...)
    bus3 = redeclared(mods, :bus3, Bus)(; name = :bus3, modified(mods, :bus3, (; S_b, fn))...)
    bus4 = redeclared(mods, :bus4, Bus)(; name = :bus4, modified(mods, :bus4, (; S_b, fn))...)
    systems = [pwLine1, pwLinewithOpening1, pwLine2, pwLine3, pwLine4, pwLoadPQ1, pwLoadPQ2, bus1, bus2, bus3, bus4]
    eqs = Equation[
        connect(pwLine2.p, pwLine1.p),
        connect(pwLine2.n, pwLine1.n),
        connect(pwLine4.p, pwLinewithOpening1.p),
        connect(pwLine4.n, pwLinewithOpening1.n),
        connect(bus1.p, pwLine1.p),
        connect(bus2.p, pwLine1.n),
        connect(bus2.p, pwLinewithOpening1.p),
        connect(pwLine3.p, pwLinewithOpening1.p),
        connect(bus3.p, pwLoadPQ1.p),
        connect(bus3.p, pwLinewithOpening1.n),
        connect(bus4.p, pwLoadPQ2.p),
        connect(pwLine3.n, bus4.p),
    ]
    System(eqs, t, [], []; name, systems)
end
