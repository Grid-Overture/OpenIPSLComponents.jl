# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/BaseClasses/SMIB.mo, transcribed automatically (2026-09-13); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
@component function SMIB(; name, S_b = 100e6, fn = 50, mods = (;))
    pwLine = redeclared(mods, :pwLine, PwLine)(; name = :pwLine, modified(mods, :pwLine, (; R = 0.001, X = 0.2, G = 0.0, B = 0.0, S_b, fn))...)
    pwLine3 = redeclared(mods, :pwLine3, PwLine)(; name = :pwLine3, modified(mods, :pwLine3, (; R = 0.0005, X = 0.1, G = 0.0, B = 0.0, S_b, fn))...)
    pwLine4 = redeclared(mods, :pwLine4, PwLine)(; name = :pwLine4, modified(mods, :pwLine4, (; R = 0.0005, X = 0.1, G = 0.0, B = 0.0, S_b, fn))...)
    gENCLS = redeclared(mods, :gENCLS, GENCLS)(; name = :gENCLS, modified(mods, :gENCLS, (; M_b = 100e6, D = 0.0, angle_0 = 0.0, X_d = 0.2, H = 0.0, P_0 = 10017110.0, Q_0 = 8006544.0, v_0 = 1.0, S_b, fn))...)
    constantLoad = redeclared(mods, :constantLoad, Load_variation)(; name = :constantLoad, modified(mods, :constantLoad, (; PQBRAK = 0.7, d_t = 0.0, d_P = 0.0, angle_0 = -0.5762684, t1 = 0.0, characteristic = 2, P_0 = 50000000.0, Q_0 = 10000000.0, v_0 = 0.9919935, S_b, fn))...)
    pwFault = redeclared(mods, :pwFault, PwFault)(; name = :pwFault, modified(mods, :pwFault, (; t1 = 2.0, t2 = 2.15, R = OpenIPSLComponents.Modelica.Constants.eps, X = OpenIPSLComponents.Modelica.Constants.eps))...)
    GEN1 = redeclared(mods, :GEN1, Bus)(; name = :GEN1, modified(mods, :GEN1, (; S_b, fn))...)
    LOAD = redeclared(mods, :LOAD, Bus)(; name = :LOAD, modified(mods, :LOAD, (; v_0 = (0.9919935), angle_0 = (-0.5762684), S_b, fn))...)
    GEN2 = redeclared(mods, :GEN2, Bus)(; name = :GEN2, modified(mods, :GEN2, (; S_b, fn))...)
    FAULT = redeclared(mods, :FAULT, Bus)(; name = :FAULT, modified(mods, :FAULT, (; S_b, fn))...)
    pwLine1 = redeclared(mods, :pwLine1, PwLine)(; name = :pwLine1, modified(mods, :pwLine1, (; R = 0.0005, G = 0.0, B = 0.0, X = 0.1, S_b, fn))...)
    pwLine2 = redeclared(mods, :pwLine2, PwLine)(; name = :pwLine2, modified(mods, :pwLine2, (; R = 0.0005, G = 0.0, B = 0.0, X = 0.1, S_b, fn))...)
    SHUNT = redeclared(mods, :SHUNT, Bus)(; name = :SHUNT, modified(mods, :SHUNT, (; S_b, fn))...)
    systems = [pwLine, pwLine3, pwLine4, gENCLS, constantLoad, pwFault, GEN1, LOAD, GEN2, FAULT, pwLine1, pwLine2, SHUNT]
    eqs = Equation[
        connect(GEN1.p, pwLine.p),
        connect(pwLine.n, LOAD.p),
        connect(pwLine3.p, LOAD.p),
        connect(constantLoad.p, LOAD.p),
        connect(GEN2.p, gENCLS.p),
        connect(pwLine4.n, GEN2.p),
        connect(FAULT.p, pwLine4.p),
        connect(FAULT.p, pwLine3.n),
        connect(pwFault.p, pwLine4.p),
        connect(pwLine1.p, LOAD.p),
        connect(pwLine1.n, SHUNT.p),
        connect(pwLine2.p, SHUNT.p),
        connect(pwLine2.n, GEN2.p),
    ]
    System(eqs, t, [], []; name, systems)
end
