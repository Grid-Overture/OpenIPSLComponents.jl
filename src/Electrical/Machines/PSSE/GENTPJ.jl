# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSSE/GENTPJ.mo (extends BaseClasses/baseMachine.mo)
# WECC type J generator: round rotor with saturation on both axes, the saturation a function of the air-gap flux
# *and* of the armature current magnitude (Kis). Its protected parameters form a cycle that Modelica solves as a
# nonlinear parameter system: delta0 -> id0, iq0 -> dsat0, qsat0 -> Xppdsat0, Xppqsat0 -> Zs, PSIpp0 -> delta0. In
# Julia the constructor closes it with a fixed-point iteration from the unsaturated point (dsat0 = qsat0 = 1,
# id0 = iq0 = 0) until delta0 stops moving (F-34). Everything else follows GENROU.jl: complex arithmetic before
# `@parameters`, numeric saturation coefficients into SE (F-22), the four `initial equation der(.) = 0` as
# `initialization_eqs`. Omitted: Icons.VerifiedModel, graphical annotations.

@component function GENTPJ(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq, Xpd, Xppd, Xppq, Xl, S10, S12, R_a = 0, w0 = 0, Xpq, Tpq0, Kis)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq, Xpd, Xppd, Xppq, Xl, S10, S12,
    R_a, w0, Xpq, Tpq0, Kis = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq,
        Xpd, Xppd, Xppq, Xl, S10, S12, R_a, w0, Xpq, Tpq0, Kis))   # F-21
    sat = (S10, S12, 1.0, 1.2)   # numeric saturation coefficients for SE inside the equations (F-22)
    CoB = M_b / S_b
    p0 = P_0 / M_b
    q0 = Q_0 / M_b
    VT = complex(v_0 * cos(angle_0), v_0 * sin(angle_0))
    S = complex(p0, q0)
    It = complex(real(S / VT), -imag(S / VT))
    ang_It = angle(It)
    Z = complex(R_a, Xl)
    PSIag = VT + Z * It
    # Fixed point of the cyclic protected parameters (F-34); OpenModelica solves the same set as one nonlinear system
    dsat0 = qsat0 = 1.0
    id0 = iq0 = 0.0
    Xppdsat0 = Xppqsat0 = delta0 = 0.0
    PSIpp0 = DQ_dq = complex(0.0, 0.0)
    converged = false
    for _ in 1:100
        delta0_prev = delta0
        Xppdsat0 = ((Xppd - Xl) / dsat0) + Xl
        Xppqsat0 = ((Xppq - Xl) / qsat0) + Xl
        Zs = complex(R_a, Xppqsat0)
        Is = It + VT / Zs
        PSIpp0 = complex(real(Zs * Is), imag(Zs * Is) - id0 * (Xppqsat0 - Xppdsat0))
        ang_PSIpp0 = angle(PSIpp0)
        ang_PSIpp0andIt = ang_PSIpp0 - ang_It
        dsat0 = 1 + SE(abs(PSIag) + Kis * sqrt(id0 * id0 + iq0 * iq0), sat...)
        qsat0 = 1 + (Xq / Xd) * SE(abs(PSIag) + Kis * sqrt(id0 * id0 + iq0 * iq0), sat...)
        a = (abs(PSIag)) * dsat0
        b = (real(It)^2 + imag(It)^2)^0.5 * (Xppdsat0 - Xq)
        delta0 = ang_PSIpp0 + atan(b * cos(ang_PSIpp0andIt) / (b * sin(ang_PSIpp0andIt) - a))
        DQ_dq = complex(cos(delta0), -sin(delta0))
        I_dq = conj(It * DQ_dq)
        iq0 = real(I_dq)
        id0 = imag(I_dq)
        if abs(delta0 - delta0_prev) < 1e-14
            converged = true
            break
        end
    end
    converged || error("GENTPJ: the cyclic protected parameters did not converge in 100 iterations")
    PSIpp0_dq = PSIpp0 * DQ_dq
    PSIppq0 = imag(PSIpp0_dq)
    PSIppd0 = real(PSIpp0_dq)
    PSId0 = PSIppd0 - Xppdsat0 * id0
    PSIq0 = PSIppq0 - Xppqsat0 * iq0
    ud0 = (-PSIq0) - R_a * id0
    uq0 = PSId0 - R_a * iq0
    pm0 = p0 + R_a * iq0 * iq0 + R_a * id0 * id0
    Epq0 = PSIppd0 + id0 * (Xpd - Xppd) / dsat0
    Epd0 = -PSIppq0 - iq0 * (Xpq - Xppq) / qsat0
    Eq10 = ((-1) * PSIppd0 * (Xd - Xpd) + Epq0 * (Xd - Xppd)) / (Xpd - Xppd)
    Ed10 = (PSIppq0 * (Xq - Xpq) + Epd0 * (Xq - Xppq)) / (Xpq - Xppq)
    Eq20 = (PSIppd0 - Epq0 + id0 * ((Xpd - Xppd) / dsat0)) * ((Xd - Xppd) / (Xpd - Xppd))
    Ed20 = (-PSIppq0 - Epd0 - iq0 * ((Xpq - Xppq) / qsat0)) * ((Xq - Xppq) / (Xpq - Xppq))
    efd0 = dsat0 * Eq10
    @named base = PSSE_baseMachine(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq,
        Xpd, Xppd, Xppq, Xl, S10, S12, R_a, w0)
    @unpack Tpd0, Tppd0, Tppq0, Xd, Xq, Xpd, Xppd, Xppq, Xl, R_a = base
    @unpack XADIFD, ISORCE, EFD0, PMECH0, EFD, Te, id, iq, ud, uq, delta = base
    pars = @parameters begin
        Xpq = Xpq, [description = "q-axis transient reactance (pu)"]
        Tpq0 = Tpq0, [description = "q-axis transient open-circuit time constant (s)"]
        Kis = Kis, [description = "Current multiplier for saturation calculation"]
        dsat0 = dsat0, [description = "To include saturation during initialization"]
        qsat0 = qsat0, [description = "To include saturation during initialization"]
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
        Eq10 = Eq10
        Ed10 = Ed10
        Eq20 = Eq20
        Ed20 = Ed20
        Xppdsat0 = Xppdsat0
        Xppqsat0 = Xppqsat0
        PSId0 = PSId0
        PSIq0 = PSIq0
    end
    vars = @variables begin
        Epd(t), [description = "d-axis voltage behind transient reactance"]
        Epq(t), [description = "q-axis voltage behind transient reactance"]
        Eq1(t)
        Eq2(t)
        Ed1(t)
        Ed2(t)
        Xppdsat(t)
        Xppqsat(t)
        dsat(t)
        qsat(t)
        PSId(t), [description = "d-axis flux linkage"]
        PSIq(t), [description = "q-axis flux linkage"]
        PSIppd(t), [description = "d-axis subtransient flux linkage"]
        PSIppq(t), [description = "q-axis subtransient flux linkage"]
        PSIpp(t), [description = "Air-gap flux"]
        XadIfd(t), [description = "d-axis machine field current"]
    end
    eqs = Equation[
        XADIFD ~ XadIfd,
        ISORCE ~ XadIfd,
        EFD0 ~ efd0,
        PMECH0 ~ pm0,
        der(Epq) ~ (1 / Tpd0) * (EFD - XadIfd),
        der(Epd) ~ (1 / Tpq0) * (-1) * qsat * Ed1,
        der(PSIppd) ~ -(dsat) * ((Xpd - Xppd) / (Xd - Xppd)) * (Eq2 / Tppd0),
        der(PSIppq) ~ (qsat) * ((Xpq - Xppq) / (Xq - Xppq)) * (Ed2 / Tppq0),
        Te ~ PSId * iq - PSIq * id,
        PSIpp ~ sqrt((uq + iq * R_a + id * Xl) * (uq + iq * R_a + id * Xl) +
                     (ud + id * R_a - iq * Xl) * (ud + id * R_a - iq * Xl)),
        dsat ~ 1 + SE(((PSIpp + Kis * sqrt(id * id + iq * iq))), sat...),
        qsat ~ 1 + (Xq / Xd) * SE(((PSIpp + Kis * sqrt(id * id + iq * iq))), sat...),
        Eq1 ~ ((-1) * PSIppd * (Xd - Xpd) + Epq * (Xd - Xppd)) / (Xpd - Xppd),
        Ed1 ~ (PSIppq * (Xq - Xpq) + Epd * (Xq - Xppq)) / (Xpq - Xppq),
        Eq2 ~ (PSIppd - Epq + id * ((Xpd - Xppd) / dsat)) * ((Xd - Xppd) / (Xpd - Xppd)),
        Ed2 ~ -(Epd + PSIppq) * ((Xq - Xppq) / (Xpq - Xppq)) - iq * ((Xq - Xppq) / qsat),
        XadIfd ~ dsat * Eq1,
        Xppdsat ~ ((Xppd - Xl) / dsat) + Xl,
        Xppqsat ~ ((Xppq - Xl) / qsat) + Xl,
        PSId ~ PSIppd - Xppdsat * id,
        PSIq ~ PSIppq - Xppqsat * iq,
        ud ~ (-PSIq) - R_a * id,
        uq ~ PSId - R_a * iq,
    ]
    extend(System(eqs, t, vars, pars; name,
            initial_conditions = Dict(delta => delta0),
            initialization_eqs = [der(Epd) ~ 0, der(Epq) ~ 0, der(PSIppd) ~ 0, der(PSIppq) ~ 0],
            guesses = Dict(XADIFD => efd0, id => id0, iq => iq0, ud => ud0, uq => uq0, Te => pm0,
                Epd => Epd0, Epq => Epq0, Eq1 => Eq10, Eq2 => Eq20, Ed1 => Ed10, Ed2 => Ed20,
                Xppdsat => Xppdsat0, Xppqsat => Xppqsat0, dsat => dsat0, qsat => qsat0,
                PSId => PSId0, PSIq => PSIq0, PSIppd => PSIppd0, PSIppq => PSIppq0, XadIfd => efd0)),
        base)
end
