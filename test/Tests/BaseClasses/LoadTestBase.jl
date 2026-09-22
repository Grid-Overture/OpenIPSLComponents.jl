# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/BaseClasses/LoadTestBase.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function LoadTestBase(; name, S_b = 100e6, fn = 50, mods = (;))
    pwLine2 = redeclared(mods, :pwLine2, PwLine)(; name = :pwLine2, modified(mods, :pwLine2, (; B = 0.001/2, G = 0.0, R = 0.01, X = 0.1, S_b, fn))...)
    pwLine3 = redeclared(mods, :pwLine3, PwLine)(; name = :pwLine3, modified(mods, :pwLine3, (; B = 0.001/2, G = 0.0, R = 0.01, X = 0.1, S_b, fn))...)
    pwLine4 = redeclared(mods, :pwLine4, PwLine)(; name = :pwLine4, modified(mods, :pwLine4, (; B = 0.001/2, G = 0.0, R = 0.01, X = 0.1, S_b, fn))...)
    Vstep1 = redeclared(mods, :Vstep1, Step)(; name = :Vstep1, modified(mods, :Vstep1, (; height = 0.0005, startTime = 2))...)
    Vstep2 = redeclared(mods, :Vstep2, Step)(; name = :Vstep2, modified(mods, :Vstep2, (; height = -0.0005, startTime = 2.1))...)
    Vsine1 = redeclared(mods, :Vsine1, Sine)(; name = :Vsine1, modified(mods, :Vsine1, (; amplitude = 0.001, f = 0.2))...)
    Vsine2 = redeclared(mods, :Vsine2, Sine)(; name = :Vsine2, modified(mods, :Vsine2, (; amplitude = 0.001, f = 0.2, startTime = 5, phase = 3.1415926535898))...)
    Psine2 = redeclared(mods, :Psine2, Sine)(; name = :Psine2, modified(mods, :Psine2, (; amplitude = 0.001, f = 0.2, startTime = 10, phase = 3.1415926535898))...)
    Psine1 = redeclared(mods, :Psine1, Sine)(; name = :Psine1, modified(mods, :Psine1, (; amplitude = 0.001, f = 0.2, startTime = 5))...)
    Pstep2 = redeclared(mods, :Pstep2, Step)(; name = :Pstep2, modified(mods, :Pstep2, (; height = -0.0005, startTime = 7.1))...)
    Pstep1 = redeclared(mods, :Pstep1, Step)(; name = :Pstep1, modified(mods, :Pstep1, (; height = 0.0005, startTime = 7))...)
    order3_Inputs_Outputs1 = redeclared(mods, :order3_Inputs_Outputs1, Order3)(; name = :order3_Inputs_Outputs1, modified(mods, :order3_Inputs_Outputs1, (; D = 0.0, M = 10.0, P_0 = 800989.8784778, Q_0 = 570163.38872796, Sn = 20000000.0, T1d0 = 8.0, V_b = 400000.0, Vn = 400000.0, ra = 0.001, x1d = 0.302, xd = 1.9, xq = 1.7, S_b, fn))...)
    sumV = redeclared(mods, :sumV, MultiSum)(; name = :sumV, modified(mods, :sumV, (; nu = 5))...)
    sumP = redeclared(mods, :sumP, MultiSum)(; name = :sumP, modified(mods, :sumP, (; nu = 5))...)
    pwLine1 = redeclared(mods, :pwLine1, PwLine)(; name = :pwLine1, modified(mods, :pwLine1, (; B = 0.001 / 2, G = 0.0, R = 0.01, X = 0.1, S_b, fn))...)
    bus1 = redeclared(mods, :bus1, Bus)(; name = :bus1, modified(mods, :bus1, (; S_b, fn))...)
    bus3 = redeclared(mods, :bus3, Bus)(; name = :bus3, modified(mods, :bus3, (; S_b, fn))...)
    bus2 = redeclared(mods, :bus2, Bus)(; name = :bus2, modified(mods, :bus2, (; S_b, fn))...)
    systems = [pwLine2, pwLine3, pwLine4, Vstep1, Vstep2, Vsine1, Vsine2, Psine2, Psine1, Pstep2, Pstep1, order3_Inputs_Outputs1, sumV, sumP, pwLine1, bus1, bus3, bus2]
    eqs = Equation[
        Vstep1.y ~ sumV.u[1],   # connect(Vstep1.y, sumV.u[1])
        Vstep2.y ~ sumV.u[2],   # connect(Vstep2.y, sumV.u[2])
        Vsine1.y ~ sumV.u[3],   # connect(Vsine1.y, sumV.u[3])
        Vsine2.y ~ sumV.u[4],   # connect(Vsine2.y, sumV.u[4])
        sumV.y ~ order3_Inputs_Outputs1.vf,   # connect(sumV.y, order3_Inputs_Outputs1.vf)
        order3_Inputs_Outputs1.vf0 ~ sumV.u[5],   # connect(order3_Inputs_Outputs1.vf0, sumV.u[5])
        order3_Inputs_Outputs1.pm0 ~ sumP.u[1],   # connect(order3_Inputs_Outputs1.pm0, sumP.u[1])
        Pstep1.y ~ sumP.u[2],   # connect(Pstep1.y, sumP.u[2])
        Pstep2.y ~ sumP.u[3],   # connect(Pstep2.y, sumP.u[3])
        Psine1.y ~ sumP.u[4],   # connect(Psine1.y, sumP.u[4])
        Psine2.y ~ sumP.u[5],   # connect(Psine2.y, sumP.u[5])
        sumP.y ~ order3_Inputs_Outputs1.pm,   # connect(sumP.y, order3_Inputs_Outputs1.pm)
        connect(order3_Inputs_Outputs1.p, bus1.p),
        connect(bus1.p, pwLine2.p),
        connect(bus1.p, pwLine1.p),
        connect(pwLine2.n, bus2.p),
        connect(pwLine1.n, bus2.p),
        connect(bus2.p, pwLine4.p),
        connect(bus2.p, pwLine3.p),
        connect(pwLine4.n, bus3.p),
        connect(pwLine3.n, bus3.p),
    ]
    System(eqs, t, [], []; name, systems)
end
