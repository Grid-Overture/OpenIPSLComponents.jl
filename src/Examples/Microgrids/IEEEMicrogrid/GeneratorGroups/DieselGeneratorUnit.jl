# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Microgrids/IEEEMicrogrid/GeneratorGroups/DieselGeneratorUnit.mo, transcribed automatically (2026-09-17); reviewed by hand.
# extends: OpenIPSL.Interfaces.Generator(V_b = 400). The diesel unit of `IEEEMicrogrid`: a `GENROE` with a `SEXS`
# and a `DEGOV`. `zero` is a `Base` function in Julia, so the Constant instance is `zero_` (the `Plant.jl`
# precedent); no oracle column refers to it.
# `DEGOV` carries a real `FixedDelay(TD = 0.024)` and `IEEEMicrogrid` has events, so the DDE path of F-20 cannot be
# used: the case passes `pade = 8` down to it through `mods` (F-51). That deviation lives in the case's script and
# test, not here.
# Omitted: graphical annotations, displayPF.
@component function DieselGeneratorUnit(; name, S_b = 100e6, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        mods = (;))
    @named base = Generator(; S_b, fn, V_b = 400, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    gENROE = redeclared(mods, :gENROE, GENROE)(; name = :gENROE, modified(mods, :gENROE, (; V_b = 400.0, P_0 = P_0, Q_0 = Q_0, v_0 = v_0, angle_0 = angle_0, M_b = 50000.0, Tpd0 = 3.7, Tppd0 = 0.05, Tppq0 = 0.05, H = 1.07, D = 0.0, Xd = 1.0, Xq = 1.0, Xpd = 0.296, Xppd = 0.177, Xppq = 0.177, Xl = 0.052, S10 = 0.12, S12 = 0.4, R_a = 0.0, Xpq = 0.4610, Tpq0 = 0.391, S_b, fn))...)
    sEXS = redeclared(mods, :sEXS, SEXS)(; name = :sEXS, modified(mods, :sEXS, (; ))...)
    zero_ = redeclared(mods, :zero, Constant)(; name = :zero_, modified(mods, :zero, (; k = 0))...)   # `zero` in the .mo
    dEGOV = redeclared(mods, :dEGOV, DEGOV)(; name = :dEGOV, modified(mods, :dEGOV, (; T1 = 0.01, T2 = 0.02, T3 = 0.2, K = 40.0, T4 = 0.25, T5 = 0.009, T6 = 0.0384, TD = 0.024, TMAX = 1.1, TMIN = 0.0))...)
    systems = [gENROE, sEXS, zero_, dEGOV]
    eqs = Equation[
        connect(gENROE.p, pwPin),
        sEXS.EFD ~ gENROE.EFD,   # connect(sEXS.EFD, gENROE.EFD)
        zero_.y ~ sEXS.VOTHSG,   # connect(zero.y, sEXS.VOTHSG)
        sEXS.XADIFD ~ gENROE.XADIFD,   # connect(sEXS.XADIFD, gENROE.XADIFD)
        sEXS.EFD0 ~ gENROE.EFD0,   # connect(sEXS.EFD0, gENROE.EFD0)
        sEXS.ECOMP ~ gENROE.ETERM,   # connect(sEXS.ECOMP, gENROE.ETERM)
        dEGOV.PMECH ~ gENROE.PMECH,   # connect(dEGOV.PMECH, gENROE.PMECH)
        gENROE.SPEED ~ dEGOV.SPEED,   # connect(gENROE.SPEED, dEGOV.SPEED)
        gENROE.PMECH0 ~ dEGOV.PMECH0,   # connect(gENROE.PMECH0, dEGOV.PMECH0)
        sEXS.VUEL ~ zero_.y,   # connect(sEXS.VUEL, zero.y)
        sEXS.VOEL ~ zero_.y,   # connect(sEXS.VOEL, zero.y)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
