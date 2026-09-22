# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/BaseClasses/SMIBRenewable.mo, transcribed automatically --kind base
# (2026-09-17); reviewed by hand. extends: Modelica.Icons.Example (nothing to port).
# The single test network of batch 7: GEN1 - pwVoltage / pwCurrent (sensors on GEN1) - pwLine2 - FAULT - two
# parallel lines pwLine / pwLine1 - GEN2 - gENCLS2_1, with pwFault at FAULT between 2.00 and 2.15 s.
# The plant under test hangs from GEN1 and reads `freq.y`, `pwVoltage.vr/vi` and `pwCurrent.ir/ii`; the three Tests
# that extend this base add it and the six equalities, so this file has no @testset of its own.
# PwVoltage / PwCurrent (batch 2) already expose vr, vi, ir, ii as plain variables.
# `freq(k = SysData.fn)` is the kwarg `fn` here: PVPlant passes `SysData(fn = 60), freq(k = SysData.fn)`, which is
# just `fn = 60`. Omitted: graphical annotations, displayPF.
@component function SMIBRenewable(; name, S_b = 100e6, fn = 50, mods = (;))
    pwLine = redeclared(mods, :pwLine, PwLine)(; name = :pwLine, modified(mods, :pwLine, (; R = 2.5e-2, X = 2.5e-2, G = 0.0, B = 0.05 / 2, S_b, fn))...)
    pwLine1 = redeclared(mods, :pwLine1, PwLine)(; name = :pwLine1, modified(mods, :pwLine1, (; R = 2.5e-2, X = 2.5e-2, G = 0.0, B = 0.05 / 2, S_b, fn))...)
    gENCLS2_1 = redeclared(mods, :gENCLS2_1, GENCLS)(; name = :gENCLS2_1, modified(mods, :gENCLS2_1, (; angle_0 = -1.570655e-05, R_a = 0.0, X_d = 2.0e-1, M_b = 100e6, V_b = 100e3, P_0 = -1498800.0, Q_0 = -4334000.0, v_0 = 1.0, S_b, fn))...)
    pwLine2 = redeclared(mods, :pwLine2, PwLine)(; name = :pwLine2, modified(mods, :pwLine2, (; G = 0.0, B = 0.0, R = 2.5e-3, X = 2.5e-3, S_b, fn))...)
    pwFault = redeclared(mods, :pwFault, PwFault)(; name = :pwFault, modified(mods, :pwFault, (; R = 0.5, X = 0.5, t1 = 2.00, t2 = 2.15))...)
    GEN1 = redeclared(mods, :GEN1, Bus)(; name = :GEN1, modified(mods, :GEN1, (; S_b, fn))...)
    FAULT = redeclared(mods, :FAULT, Bus)(; name = :FAULT, modified(mods, :FAULT, (; S_b, fn))...)
    GEN2 = redeclared(mods, :GEN2, Bus)(; name = :GEN2, modified(mods, :GEN2, (; S_b, fn))...)
    freq = redeclared(mods, :freq, Constant)(; name = :freq, modified(mods, :freq, (; k = fn))...)
    pwCurrent = redeclared(mods, :pwCurrent, PwCurrent)(; name = :pwCurrent, modified(mods, :pwCurrent, (;))...)
    pwVoltage = redeclared(mods, :pwVoltage, PwVoltage)(; name = :pwVoltage, modified(mods, :pwVoltage, (;))...)
    systems = [pwLine, pwLine1, gENCLS2_1, pwLine2, pwFault, GEN1, FAULT, GEN2, freq, pwCurrent, pwVoltage]
    eqs = Equation[
        connect(FAULT.p, pwLine.p),
        connect(pwLine1.p, pwLine.p),
        connect(pwFault.p, FAULT.p),
        connect(pwLine.n, GEN2.p),
        connect(pwLine1.n, GEN2.p),
        connect(GEN2.p, gENCLS2_1.p),
        connect(pwLine2.n, FAULT.p),
        connect(pwCurrent.n, pwLine2.p),
        connect(pwCurrent.p, GEN1.p),
        connect(pwVoltage.p, GEN1.p),
    ]
    System(eqs, t, [], []; name, systems)
end
