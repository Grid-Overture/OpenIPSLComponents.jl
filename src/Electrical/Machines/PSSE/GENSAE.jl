# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSSE/GENSAE.mo (extends BaseClasses/baseMachine.mo)
# Salient pole generator with exponential saturation on both axes. Same three states as GENSAL (Epq, PSIkd, PSIppq)
# with their literal `initial equation der(.) = 0`, but the rotor angle is initialized as in GENROE (flux angle plus
# the atan of b/a) and the q-axis sub-transient flux carries a saturation term. `dsat` is declared after `a` in the
# .mo and used by it: in Julia it is computed first (a Modelica parameter binding has no order). `SE_exp` gets the
# numeric saturation coefficients and a symbolic argument (F-22). Omitted: Icons.VerifiedModel, graphical annotations.

@component function GENSAE(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq, Xpd, Xppd, Xppq, Xl, S10, S12, R_a = 0, w0 = 0)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq, Xpd, Xppd, Xppq, Xl, S10, S12,
    R_a, w0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq, Xpd, Xppd, Xppq,
        Xl, S10, S12, R_a, w0))   # F-21
    sat = (S10, S12, 1.0, 1.2)   # numeric saturation coefficients for SE_exp inside the equations (F-22)
    CoB = M_b / S_b
    p0 = P_0 / M_b
    q0 = Q_0 / M_b
    Zs = complex(R_a, Xppd)
    VT = complex(v_0 * cos(angle_0), v_0 * sin(angle_0))
    S = complex(p0, q0)
    It = complex(real(S / VT), -imag(S / VT))
    Is = It + VT / Zs
    PSIpp0 = Zs * Is
    ang_PSIpp0 = angle(PSIpp0)
    ang_It = angle(It)
    ang_PSIpp0andIt = ang_PSIpp0 - ang_It
    abs_PSIpp0 = abs(PSIpp0)
    dsat = SE_exp(abs_PSIpp0, sat...)
    a = abs_PSIpp0 + abs_PSIpp0 * dsat * (Xq - Xl) / (Xd - Xl)
    b = (real(It)^2 + imag(It)^2)^0.5 * (Xppd - Xq)
    delta0 = atan(b * cos(ang_PSIpp0andIt) / (b * sin(ang_PSIpp0andIt) - a)) + ang_PSIpp0
    DQ_dq = cos(delta0) - im * sin(delta0)
    I_dq = complex(real(It * DQ_dq), -imag(It * DQ_dq))
    iq0 = real(I_dq)
    id0 = imag(I_dq)
    ud0 = v_0 * cos(angle_0 - delta0 + pi / 2)
    uq0 = v_0 * sin(angle_0 - delta0 + pi / 2)
    PSIpp0_dq = PSIpp0 * DQ_dq
    PSIppq0 = -imag(PSIpp0_dq)
    PSIppd0 = real(PSIpp0_dq)
    K1d = (Xpd - Xppd) * (Xd - Xpd) / (Xpd - Xl)^2
    K2d = (Xpd - Xl) * (Xppd - Xl) / (Xpd - Xppd)
    K3d = (Xppd - Xl) / (Xpd - Xl)
    K4d = (Xpd - Xppd) / (Xpd - Xl)
    PSIkd0 = (PSIppd0 - (Xpd - Xl) * K3d * id0) / (K3d + K4d)
    PSId0 = PSIppd0 - Xppd * id0
    PSIq0 = (-PSIppq0) - Xppq * iq0
    Epq0 = uq0 + Xpd * id0 + R_a * iq0
    efd0 = Epq0 + (Xd - Xpd) * id0 + PSIppd0 * dsat
    pm0 = p0 + R_a * iq0 * iq0 + R_a * id0 * id0
    @named base = PSSE_baseMachine(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq,
        Xpd, Xppd, Xppq, Xl, S10, S12, R_a, w0)
    @unpack Tpd0, Tppd0, Tppq0, Xd, Xq, Xpd, Xppd, Xppq, Xl, R_a = base
    @unpack XADIFD, ISORCE, EFD0, PMECH0, EFD, PMECH, Te, id, iq, ud, uq, delta = base
    pars = @parameters begin
        delta0 = delta0, [description = "initial rotor angle in radians"]
        iq0 = iq0, [description = "q-axis component of initial current"]
        id0 = id0, [description = "d-axis component of initial current"]
        ud0 = ud0, [description = "d-axis component of initial voltage"]
        uq0 = uq0, [description = "q-axis component of initial voltage"]
        PSIppq0 = PSIppq0, [description = "q-axis component of the sub-transient flux linkage"]
        PSIppd0 = PSIppd0, [description = "d-axis component of the sub-transient flux linkage"]
        PSIkd0 = PSIkd0, [description = "d-axis initial rotor flux linkage"]
        PSId0 = PSId0
        PSIq0 = PSIq0
        Epq0 = Epq0
        dsat = dsat, [description = "To include saturation during initialization"]
        efd0 = efd0, [description = "Initial field voltage magnitude"]
        pm0 = pm0, [description = "Initial mechanical power (pu machine base)"]
        K1d = K1d
        K2d = K2d
        K3d = K3d
        K4d = K4d
    end
    vars = @variables begin
        Epq(t), [description = "q-axis voltage behind transient reactance"]
        PSIkd(t), [description = "d-axis rotor flux linkage"]
        PSIppq(t), [description = "q-axis subtransient flux linkage"]
        PSIppd(t), [description = "d-axis subtransient flux linkage"]
        PSId(t), [description = "d-axis flux linkage"]
        PSIq(t), [description = "q-axis flux linkage"]
        XadIfd(t), [description = "Machine field current"]
        PSIpp(t), [description = "Air-gap flux"]
    end
    eqs = Equation[
        XADIFD ~ XadIfd,
        PMECH0 ~ pm0,
        EFD0 ~ efd0,
        ISORCE ~ XadIfd,
        der(Epq) ~ 1 / Tpd0 * (EFD - XadIfd),
        der(PSIkd) ~ 1 / Tppd0 * (Epq - PSIkd - (Xpd - Xl) * id),
        der(PSIppq) ~ 1 / Tppq0 * ((-PSIppq) + (Xq - Xppq) * iq -
                                   PSIppq * (Xq - Xl) / (Xd - Xl) * SE_exp(PSIpp, sat...)),
        PSIppd ~ Epq * K3d + PSIkd * K4d,
        PSId ~ PSIppd - Xppd * id,
        PSIq ~ (-PSIppq) - Xppq * iq,
        PSIpp ~ sqrt(PSIppd * PSIppd + PSIppq * PSIppq),
        XadIfd ~ Epq + K1d * (Epq - PSIkd - (Xpd - Xl) * id) + (Xd - Xpd) * id + (SE_exp(PSIpp, sat...)) * PSIppd,
        Te ~ PSId * iq - PSIq * id,
        ud ~ (-PSIq) - R_a * id,
        uq ~ PSId - R_a * iq,
    ]
    extend(System(eqs, t, vars, pars; name,
            initial_conditions = Dict(delta => delta0),
            initialization_eqs = [der(Epq) ~ 0, der(PSIkd) ~ 0, der(PSIppq) ~ 0],
            guesses = Dict(EFD => efd0, XADIFD => efd0, PMECH => pm0, id => id0, iq => iq0, ud => ud0, uq => uq0,
                Te => pm0, Epq => Epq0, PSIkd => PSIkd0, PSIppq => PSIppq0, PSIppd => PSIppd0, PSId => PSId0,
                PSIq => PSIq0, XadIfd => efd0)),
        base)
end
