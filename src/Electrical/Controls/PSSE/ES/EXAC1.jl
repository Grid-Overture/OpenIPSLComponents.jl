# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/EXAC1.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: imLimitedSimpleLag = SimpleLagLim(K_A, T_A, V_RMIN, V_RMAX, y_start = VR0), imDerivativeLag = Derivative(K_F,
# T_F, y_start = 0, InitialOutput, x_start = VFE0), leadLag = LeadLag(K = 1, T_C, T_B, y_start = x_start = VR0/K_A),
# add3_1 = Add3(k3 = -1), rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(K_C),
# rotatingExciterWithDemagnetizationLimited = RotatingExciterWithDemagnetizationLimited(T_E, K_E, E_1, E_2, S_EE_1,
# S_EE_2, K_D, Efd0 = VE0), TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0), add3_2 = Add3. The causal
# connects are equalities. The four protected `fixed = false` parameters (VR0, Ifd0, VE0, VFE0) are resolved from
# inputs (F-33) with `invFEX` and `SE` on symbolic arguments. Omitted: Icons.VerifiedModel, graphical annotations.

@component function EXAC1(; name, T_R = 0, T_B = 0, T_C = 0, K_A = 400, T_A = 0.02, V_RMAX = 9, V_RMIN = -5.43,
        T_E = 0.8, K_F = 0.03, T_F = 1, K_C = 0.2, K_D = 0.48, K_E = 1, E_1 = 5.25, E_2 = 7, S_EE_1 = 0.03, S_EE_2 = 0.1)
    T_R, T_B, T_C, K_A, T_A, V_RMAX, V_RMIN, T_E, K_F, T_F, K_C, K_D, K_E, E_1, E_2, S_EE_1, S_EE_2 =
        float.((T_R, T_B, T_C, K_A, T_A, V_RMAX, V_RMIN, T_E, K_F, T_F, K_C, K_D, K_E, E_1, E_2, S_EE_1, S_EE_2))
    n = (; T_R, T_B, T_C, K_A, T_A, V_RMAX, V_RMIN, T_E, K_F, T_F, K_C, K_D, K_E, E_1, E_2, S_EE_1, S_EE_2)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        T_B = T_B, [description = "Regulator denominator (lag) time constant (s)"]
        T_C = T_C, [description = "Regulator numerator (lead) time constant (s)"]
        K_A = K_A, [description = "Regulator output gain"]
        T_A = T_A, [description = "Regulator output time constant (s)"]
        V_RMAX = V_RMAX, [description = "Maximum regulator output"]
        V_RMIN = V_RMIN, [description = "Minimum regulator output"]
        T_E = T_E, [description = "Exciter field time constant (s)"]
        K_F = K_F, [description = "Rate feedback excitation system stabilizer gain"]
        T_F = T_F, [description = "Rate feedback time constant (s)"]
        K_C = K_C, [description = "Rectifier loading factor proportional to commutating reactance"]
        K_D = K_D, [description = "Demagnetizing factor, function of exciter alternator reactances"]
        K_E = K_E, [description = "Exciter field proportional constant"]
        E_1 = E_1, [description = "Exciter output voltage for saturation factor S_E(E_1)"]
        E_2 = E_2, [description = "Exciter output voltage for saturation factor S_E(E_2)"]
        S_EE_1 = S_EE_1, [description = "Exciter saturation factor at exciter output voltage E1"]
        S_EE_2 = S_EE_2, [description = "Exciter saturation factor at exciter output voltage E2"]
        VR0, [guess = 1.0]   # fixed = false, from the initial equations below
        Ifd0, [guess = 1.0]
        VE0, [guess = 1.0]
        VFE0, [guess = 1.0]
    end
    systems = @named begin
        imLimitedSimpleLag = SimpleLagLim(; K = n.K_A, T = n.T_A, outMin = n.V_RMIN, outMax = n.V_RMAX, y_start = VR0)
        imDerivativeLag = Derivative(; k = n.K_F, T = n.T_F, y_start = 0, initType = :InitialOutput, x_start = VFE0)
        leadLag = LeadLag(; K = 1, T1 = n.T_C, T2 = n.T_B, y_start = VR0 / n.K_A, x_start = VR0 / n.K_A)
        add3_1 = Add3(; k3 = -1)
        rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(; K_C = n.K_C)
        rotatingExciterWithDemagnetizationLimited = RotatingExciterWithDemagnetizationLimited(; T_E = n.T_E, K_E = n.K_E,
            E_1 = n.E_1, E_2 = n.E_2, S_EE_1 = n.S_EE_1, S_EE_2 = n.S_EE_2, K_D = n.K_D, Efd0 = VE0)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        add3_2 = Add3()
    end
    rex = rotatingExciterWithDemagnetizationLimited
    rcv = rectifierCommutationVoltageDrop
    eqs = Equation[
        leadLag.y ~ imLimitedSimpleLag.u,   # connect(leadLag.y, imLimitedSimpleLag.u)
        add3_1.y ~ leadLag.u,               # connect(add3_1.y, leadLag.u)
        rcv.XADIFD ~ XADIFD,                # connect(rectifierCommutationVoltageDrop.XADIFD, XADIFD)
        rex.EFD ~ rcv.V_EX,                 # connect(rotatingExciterWithDemagnetizationLimited.EFD, rectifierCommutationVoltageDrop.V_EX)
        imLimitedSimpleLag.y ~ rex.I_C,     # connect(imLimitedSimpleLag.y, rotatingExciterWithDemagnetizationLimited.I_C)
        rcv.EFD ~ EFD,                      # connect(rectifierCommutationVoltageDrop.EFD, EFD)
        rex.XADIFD ~ XADIFD,                # connect(rotatingExciterWithDemagnetizationLimited.XADIFD, XADIFD)
        imDerivativeLag.u ~ rex.V_FE,       # connect(imDerivativeLag.u, rotatingExciterWithDemagnetizationLimited.V_FE)
        DiffV.y ~ add3_1.u2,                # connect(DiffV.y, add3_1.u2)
        ECOMP ~ TransducerDelay.u,          # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,       # connect(TransducerDelay.y, DiffV.u2)
        VOEL ~ add3_2.u3,                   # connect(VOEL, add3_2.u3)
        VUEL ~ add3_2.u2,                   # connect(VUEL, add3_2.u2)
        VOTHSG ~ add3_2.u1,                 # connect(VOTHSG, add3_2.u1)
        add3_2.y ~ add3_1.u1,               # connect(add3_2.y, add3_1.u1)
        imDerivativeLag.y ~ add3_1.u3,      # connect(imDerivativeLag.y, add3_1.u3)
    ]
    extend(System(eqs, t, [], pars; name, systems,
            initial_conditions = Dict(VR0 => missing, Ifd0 => missing, VE0 => missing, VFE0 => missing),
            initialization_eqs = [Ifd0 ~ XADIFD, VE0 ~ invFEX(K_C, Efd0, Ifd0),
                VFE0 ~ VE0 * (SE(VE0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2) + K_E) + Ifd0 * K_D,
                VR0 ~ VFE0, V_REF ~ VR0 / K_A + ECOMP0]), base)
end
