# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSSE/GENROU.mo (extends BaseClasses/baseMachine.mo)
# Round rotor generator, quadratic saturation. The protected `Complex` chain of the .mo (Zs, VT, S, It, Is, PSIpp0,
# DQ_dq, PSIpp0_dq, I_dq) is Julia complex arithmetic before `@parameters` (arg -> angle, j -> im, conj -> conj);
# only the real scalars the equations or the start values need become symbolic parameters. `SE` gets the numeric
# saturation coefficients (`sat`, captured before the base's `@unpack` rebinds S10/S12 to symbols) and a symbolic
# argument, as ImSE does (F-22). The four `initial equation der(.) = 0` are `initialization_eqs` (F-26) and the
# states they determine keep their `start` as guesses (F-20); `delta(start = delta0, fixed = true)` of the extends
# modifier is the child's initial condition. CoB, p0, q0, vr0, vi0, ir0, ii0 are redeclared identically in the .mo
# and come from the base. Omitted: Icons.VerifiedModel, graphical annotations.

@component function GENROU(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq, Xpd, Xppd, Xppq, Xl, S10, S12, R_a = 0, w0 = 0,
        Xpq, Tpq0, Xpp = Xppd)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq, Xpd, Xppd, Xppq, Xl, S10, S12,
    R_a, w0, Xpq, Tpq0, Xpp = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq,
        Xpd, Xppd, Xppq, Xl, S10, S12, R_a, w0, Xpq, Tpq0, Xpp))   # F-21
    sat = (S10, S12, 1.0, 1.2)   # numeric saturation coefficients for SE inside the equations (F-22)
    CoB = M_b / S_b
    p0 = P_0 / M_b
    q0 = Q_0 / M_b
    Zs = complex(R_a, Xpp)
    VT = complex(v_0 * cos(angle_0), v_0 * sin(angle_0))
    S = complex(p0, q0)
    It = complex(real(S / VT), -imag(S / VT))
    Is = It + VT / Zs
    PSIpp0 = Zs * Is
    ang_PSIpp0 = angle(PSIpp0)
    ang_It = angle(It)
    ang_PSIpp0andIt = ang_PSIpp0 - ang_It
    abs_PSIpp0 = abs(PSIpp0)
    dsat = SE(abs_PSIpp0, sat...)
    a = abs_PSIpp0 + abs_PSIpp0 * dsat * (Xq - Xl) / (Xd - Xl)
    b = (real(It)^2 + imag(It)^2)^0.5 * (Xpp - Xq)
    delta0 = atan(b * cos(ang_PSIpp0andIt) / (b * sin(ang_PSIpp0andIt) - a)) + ang_PSIpp0
    DQ_dq = cos(delta0) - im * sin(delta0)
    PSIpp0_dq = PSIpp0 * DQ_dq
    I_dq = conj(It * DQ_dq)
    PSIppq0 = imag(PSIpp0_dq)
    PSIppd0 = real(PSIpp0_dq)
    iq0 = real(I_dq)
    id0 = imag(I_dq)
    ud0 = (-(PSIppq0 - Xppq * iq0)) - R_a * id0
    uq0 = PSIppd0 - Xppd * id0 - R_a * iq0
    pm0 = p0 + R_a * iq0 * iq0 + R_a * id0 * id0
    efd0 = dsat * PSIppd0 + PSIppd0 + (Xpd - Xpp) * id0 + (Xd - Xpd) * id0
    K1d = (Xpd - Xppd) * (Xd - Xpd) / (Xpd - Xl)^2
    K2d = (Xpd - Xl) * (Xppd - Xl) / (Xpd - Xppd)
    K1q = (Xpq - Xppq) * (Xq - Xpq) / (Xpq - Xl)^2
    K2q = (Xpq - Xl) * (Xppq - Xl) / (Xpq - Xppq)
    K3d = (Xppd - Xl) / (Xpd - Xl)
    K4d = (Xpd - Xppd) / (Xpd - Xl)
    K3q = (Xppq - Xl) / (Xpq - Xl)
    K4q = (Xpq - Xppq) / (Xpq - Xl)
    PSIkd0 = (PSIppd0 - (Xpd - Xl) * K3d * id0) / (K3d + K4d)
    PSIkq0 = ((-PSIppq0) + (Xpq - Xl) * K3q * iq0) / (K3q + K4q)
    Epq0 = PSIkd0 + (Xpd - Xl) * id0
    Epd0 = PSIkq0 - (Xpq - Xl) * iq0
    PSId0 = PSIppd0 - Xppd * id0
    PSIq0 = (-PSIppq0) - Xppq * iq0
    @named base = PSSE_baseMachine(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq,
        Xpd, Xppd, Xppq, Xl, S10, S12, R_a, w0)
    @unpack Tpd0, Tppd0, Tppq0, Xd, Xq, Xpd, Xppd, Xppq, Xl, R_a = base
    @unpack XADIFD, ISORCE, EFD0, PMECH0, EFD, Te, id, iq, ud, uq, delta = base
    pars = @parameters begin
        Xpq = Xpq, [description = "q-axis transient reactance (pu)"]
        Tpq0 = Tpq0, [description = "q-axis transient open-circuit time constant (s)"]
        Xpp = Xpp, [description = "Sub-transient reactance (pu)"]
        dsat = dsat, [description = "To include saturation during initialization"]
        delta0 = delta0, [description = "initial rotor angle in radians"]
        PSIppq0 = PSIppq0, [description = "q-axis component of the sub-transient flux linkage"]
        PSIppd0 = PSIppd0, [description = "d-axis component of the sub-transient flux linkage"]
        iq0 = iq0, [description = "q-axis component of initial current"]
        id0 = id0, [description = "d-axis component of initial current"]
        ud0 = ud0, [description = "d-axis component of initial voltage"]
        uq0 = uq0, [description = "q-axis component of initial voltage"]
        pm0 = pm0, [description = "Initial mechanical power (machine base)"]
        efd0 = efd0, [description = "Initial field voltage magnitude"]
        Epq0 = Epq0
        Epd0 = Epd0
        PSIkd0 = PSIkd0, [description = "d-axis initial rotor flux linkage"]
        PSIkq0 = PSIkq0, [description = "q-axis initial rotor flux linkage"]
        PSId0 = PSId0
        PSIq0 = PSIq0
        K1d = K1d
        K2d = K2d
        K1q = K1q
        K2q = K2q
        K3d = K3d
        K4d = K4d
        K3q = K3q
        K4q = K4q
    end
    vars = @variables begin
        Epd(t), [description = "d-axis voltage behind transient reactance"]
        Epq(t), [description = "q-axis voltage behind transient reactance"]
        PSIkd(t), [description = "d-axis rotor flux linkage"]
        PSIkq(t), [description = "q-axis rotor flux linkage"]
        PSId(t), [description = "d-axis flux linkage"]
        PSIq(t), [description = "q-axis flux linkage"]
        PSIppd(t), [description = "d-axis subtransient flux linkage"]
        PSIppq(t), [description = "q-axis subtransient flux linkage"]
        PSIpp(t), [description = "Air-gap flux"]
        XadIfd(t), [description = "d-axis machine field current"]
        XaqIlq(t), [description = "q-axis Machine field current"]
    end
    eqs = Equation[
        XADIFD ~ XadIfd,
        ISORCE ~ XadIfd,
        EFD0 ~ efd0,
        PMECH0 ~ pm0,
        der(Epq) ~ 1 / Tpd0 * (EFD - XadIfd),
        der(Epd) ~ 1 / Tpq0 * (-1) * XaqIlq,
        der(PSIkd) ~ 1 / Tppd0 * (Epq - PSIkd - (Xpd - Xl) * id),
        der(PSIkq) ~ 1 / Tppq0 * (Epd - PSIkq + (Xpq - Xl) * iq),
        Te ~ PSId * iq - PSIq * id,
        PSId ~ PSIppd - Xppd * id,
        PSIq ~ (-PSIppq) - Xppq * iq,
        PSIppd ~ Epq * K3d + PSIkd * K4d,
        -PSIppq ~ (-Epd * K3q) - PSIkq * K4q,
        PSIpp ~ sqrt(PSIppd * PSIppd + PSIppq * PSIppq),
        XadIfd ~ K1d * (Epq - PSIkd - (Xpd - Xl) * id) + Epq + id * (Xd - Xpd) + SE(PSIpp, sat...) * PSIppd,
        XaqIlq ~ K1q * (Epd - PSIkq + (Xpq - Xl) * iq) + Epd - iq * (Xq - Xpq) -
                 SE(PSIpp, sat...) * (-1) * PSIppq * (Xq - Xl) / (Xd - Xl),
        ud ~ (-PSIq) - R_a * id,
        uq ~ PSId - R_a * iq,
    ]
    extend(System(eqs, t, vars, pars; name,
            initial_conditions = Dict(delta => delta0),
            initialization_eqs = [der(Epd) ~ 0, der(Epq) ~ 0, der(PSIkd) ~ 0, der(PSIkq) ~ 0],
            guesses = Dict(XADIFD => efd0, id => id0, iq => iq0, ud => ud0, uq => uq0, Te => pm0,
                Epd => Epd0, Epq => Epq0, PSIkd => PSIkd0, PSIkq => PSIkq0, PSId => PSId0, PSIq => PSIq0,
                PSIppd => PSIppd0, PSIppq => PSIppq0, XadIfd => efd0, XaqIlq => 0.0)),
        base)
end
