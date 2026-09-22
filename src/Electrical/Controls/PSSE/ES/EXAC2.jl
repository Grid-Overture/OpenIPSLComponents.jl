# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/EXAC2.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: imLimitedSimpleLag = SimpleLagLim(K_A, T_A, V_AMAX, V_AMIN, y_start = VA0), imDerivativeLag = Derivative(K_F,
# T_F, y_start = 0, InitialOutput, x_start = VFE0), leadLag = LeadLag(K = 1, T_C, T_B, y_start = x_start = VA0/K_A),
# add3_1 = Add3(k3 = -1), rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(K_C),
# rotatingExciterWithDemagnetizationLimited = RotatingExciterWithDemagnetizationLimited(T_E, K_E, E_1, E_2, S_EE_1,
# S_EE_2, K_D, Efd0 = VE0), TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0), add3_2 = Add3, DiffV1 =
# Add(k2 = -1), gain = Gain(K_H), lV_GATE = LV_GATE, gain1 = Gain(K_B), limiter = Limiter(V_RMAX, V_RMIN), gain3 =
# Gain(K_L), add3 = Add(k1 = -1, k2 = 1), Vref1 = Constant(V_LR). The causal connects are equalities. The five
# protected `fixed = false` parameters (VA0, VR0, VFE0, Ifd0, VE0) are resolved from inputs (F-33).
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function EXAC2(; name, T_R = 0, T_B = 0, T_C = 0, K_A = 400, T_A = 0.02, K_B = 1, V_RMAX = 9, V_RMIN = -5.43,
        V_AMAX = 9, V_AMIN = -5.43, T_E = 0.8, K_L = 0, K_H = 0, K_F = 0.03, T_F = 1, K_C = 0.2, K_D = 0.48, K_E = 1,
        V_LR = 9, E_1 = 5.25, E_2 = 7, S_EE_1 = 0.03, S_EE_2 = 0.1)
    T_R, T_B, T_C, K_A, T_A, K_B, V_RMAX, V_RMIN, V_AMAX, V_AMIN, T_E, K_L, K_H, K_F, T_F, K_C, K_D, K_E, V_LR, E_1, E_2, S_EE_1, S_EE_2 =
        float.((T_R, T_B, T_C, K_A, T_A, K_B, V_RMAX, V_RMIN, V_AMAX, V_AMIN, T_E, K_L, K_H, K_F, T_F, K_C, K_D, K_E, V_LR, E_1, E_2, S_EE_1, S_EE_2))
    n = (; T_R, T_B, T_C, K_A, T_A, K_B, V_RMAX, V_RMIN, V_AMAX, V_AMIN, T_E, K_L, K_H, K_F, T_F, K_C, K_D, K_E, V_LR, E_1, E_2, S_EE_1, S_EE_2)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        T_B = T_B, [description = "Regulator denominator (lag) time constant (s)"]
        T_C = T_C, [description = "Regulator numerator (lead) time constant (s)"]
        K_A = K_A, [description = "Regulator output gain"]
        T_A = T_A, [description = "Regulator output time constant (s)"]
        K_B = K_B, [description = "Second stage regulator gain"]
        V_RMAX = V_RMAX, [description = "Maximum exciter field voltage"]
        V_RMIN = V_RMIN, [description = "Minimum exciter field voltage"]
        V_AMAX = V_AMAX, [description = "Maximum regulator output"]
        V_AMIN = V_AMIN, [description = "Minimum regulator output"]
        T_E = T_E, [description = "Exciter field time constant (s)"]
        K_L = K_L, [description = "Limiter control circuitry gain"]
        K_H = K_H, [description = "Exciter field current regulator feedback gain"]
        K_F = K_F, [description = "Rate feedback excitation system stabilizer gain"]
        T_F = T_F, [description = "Rate feedback time const (s)"]
        K_C = K_C, [description = "Rectifier loading factor proportional to commutating reactance"]
        K_D = K_D, [description = "Demagnetizing factor, function of exciter alternator reactances"]
        K_E = K_E, [description = "Exciter field proportional constant"]
        V_LR = V_LR, [description = "Limit value reference of exciter field voltage"]
        E_1 = E_1, [description = "Exciter output voltage for saturation factor S_E(E_1)"]
        E_2 = E_2, [description = "Exciter output voltage for saturation factor S_E(E_2)"]
        S_EE_1 = S_EE_1, [description = "Exciter saturation factor at exciter output voltage E1"]
        S_EE_2 = S_EE_2, [description = "Exciter saturation factor at exciter output voltage E2"]
        VA0, [guess = 1.0]   # fixed = false, from the initial equations below
        VR0, [guess = 1.0]
        VFE0, [guess = 1.0]
        Ifd0, [guess = 1.0]
        VE0, [guess = 1.0]
    end
    systems = @named begin
        imLimitedSimpleLag = SimpleLagLim(; K = n.K_A, T = n.T_A, outMax = n.V_AMAX, outMin = n.V_AMIN, y_start = VA0)
        imDerivativeLag = Derivative(; k = n.K_F, T = n.T_F, y_start = 0, initType = :InitialOutput, x_start = VFE0)
        leadLag = LeadLag(; K = 1, T1 = n.T_C, T2 = n.T_B, y_start = VA0 / n.K_A, x_start = VA0 / n.K_A)
        add3_1 = Add3(; k3 = -1)
        rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(; K_C = n.K_C)
        rotatingExciterWithDemagnetizationLimited = RotatingExciterWithDemagnetizationLimited(; T_E = n.T_E, K_E = n.K_E,
            E_1 = n.E_1, E_2 = n.E_2, S_EE_1 = n.S_EE_1, S_EE_2 = n.S_EE_2, K_D = n.K_D, Efd0 = VE0)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        add3_2 = Add3()
        DiffV1 = Add(; k2 = -1)
        gain = Gain(; k = n.K_H)
        lV_GATE = LV_GATE()
        gain1 = Gain(; k = n.K_B)
        limiter = Limiter(; uMax = n.V_RMAX, uMin = n.V_RMIN)
        gain3 = Gain(; k = n.K_L)
        add3 = Add(; k1 = -1, k2 = +1)
        Vref1 = Constant(; k = n.V_LR)
    end
    rex = rotatingExciterWithDemagnetizationLimited
    rcv = rectifierCommutationVoltageDrop
    eqs = Equation[
        rcv.XADIFD ~ XADIFD,                # connect(rectifierCommutationVoltageDrop.XADIFD, XADIFD)
        rex.XADIFD ~ XADIFD,                # connect(rotatingExciterWithDemagnetizationLimited.XADIFD, XADIFD)
        leadLag.y ~ imLimitedSimpleLag.u,   # connect(leadLag.y, imLimitedSimpleLag.u)
        add3_1.y ~ leadLag.u,               # connect(add3_1.y, leadLag.u)
        rex.EFD ~ rcv.V_EX,                 # connect(rotatingExciterWithDemagnetizationLimited.EFD, rectifierCommutationVoltageDrop.V_EX)
        rcv.EFD ~ EFD,                      # connect(rectifierCommutationVoltageDrop.EFD, EFD)
        imDerivativeLag.u ~ rex.V_FE,       # connect(imDerivativeLag.u, rotatingExciterWithDemagnetizationLimited.V_FE)
        DiffV.y ~ add3_1.u2,                # connect(DiffV.y, add3_1.u2)
        ECOMP ~ TransducerDelay.u,          # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,       # connect(TransducerDelay.y, DiffV.u2)
        VOEL ~ add3_2.u3,                   # connect(VOEL, add3_2.u3)
        VUEL ~ add3_2.u2,                   # connect(VUEL, add3_2.u2)
        VOTHSG ~ add3_2.u1,                 # connect(VOTHSG, add3_2.u1)
        add3_2.y ~ add3_1.u1,               # connect(add3_2.y, add3_1.u1)
        imDerivativeLag.y ~ add3_1.u3,      # connect(imDerivativeLag.y, add3_1.u3)
        imLimitedSimpleLag.y ~ DiffV1.u1,   # connect(imLimitedSimpleLag.y, DiffV1.u1)
        gain.y ~ DiffV1.u2,                 # connect(gain.y, DiffV1.u2)
        gain.u ~ rex.V_FE,                  # connect(gain.u, rotatingExciterWithDemagnetizationLimited.V_FE)
        limiter.y ~ rex.I_C,                # connect(limiter.y, rotatingExciterWithDemagnetizationLimited.I_C)
        add3.u1 ~ rex.V_FE,                 # connect(add3.u1, rotatingExciterWithDemagnetizationLimited.V_FE)
        gain3.u ~ add3.y,                   # connect(gain3.u, add3.y)
        Vref1.y ~ add3.u2,                  # connect(Vref1.y, add3.u2)
        gain1.y ~ limiter.u,                # connect(gain1.y, limiter.u)
        lV_GATE.y ~ gain1.u,                # connect(lV_GATE.y, gain1.u)
        gain3.y ~ lV_GATE.u2,               # connect(gain3.y, lV_GATE.u2)
        DiffV1.y ~ lV_GATE.u1,              # connect(DiffV1.y, lV_GATE.u1)
    ]
    extend(System(eqs, t, [], pars; name, systems,
            initial_conditions = Dict(VA0 => missing, VR0 => missing, VFE0 => missing, Ifd0 => missing, VE0 => missing),
            initialization_eqs = [Ifd0 ~ XADIFD, VE0 ~ invFEX(K_C, Efd0, Ifd0),
                VFE0 ~ VE0 * (SE(VE0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2) + K_E) + Ifd0 * K_D,
                VR0 ~ VFE0, VA0 ~ VR0 / K_B + VFE0 * K_H, V_REF ~ VA0 / K_A + ECOMP0]), base)
end
