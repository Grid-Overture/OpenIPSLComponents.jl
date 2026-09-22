# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/EXBAS.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: simpleLag = SimpleLag(K = 1, T_R, y_start = ECOMP0), add3_1 = Add3, add3_2 = Add3(k3 = -1), leadLag =
# LeadLag(K = 1, T_C, T_B, y_start = x_start = VR0/K_A), simpleLagLim = SimpleLagLim(K_A, T_A, V_RMAX, V_RMIN,
# y_start = VR0), rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(K_C),
# rotatingExciterWithDemagnetizationLimited = RotatingExciterWithDemagnetization(T_E, K_E, E_1, E_2, S_EE_1, S_EE_2,
# K_D, Efd0 = VE0) (the UNlimited class under a "Limited" instance name, sic), leadLag1 = LeadLag(K = 1, T_F1, T_F2,
# y_start = x_start = VR0), imDerivativeLag = Derivative(K_F, T_F, y_start = 0, InitialOutput, x_start = VR0),
# integrator = Integrator(k = K_IR, y_start = VR0/K_A) (MSL default InitialState), gain = Gain(K_PR), add = Add.
# The causal connects are equalities; VR0, VFE0, Ifd0, VE0 are `fixed = false` resolved from inputs (F-33).
# Omitted: graphical annotations.

@component function EXBAS(; name, T_R = 0, K_PR = 140, K_IR = 20, K_A = 7, T_A = 0, T_B = 0.03, T_C = 0.214,
        V_RMAX = 12.546, V_RMIN = -11.282, K_F = 0, T_F = 1, T_F1 = 0, T_F2 = 0, K_E = 1, T_E = 4.5, K_C = 0.2540,
        K_D = 0.463, E_1 = 2.925, S_EE_1 = 0.53, E_2 = 3.9, S_EE_2 = 0.67)
    T_R, K_PR, K_IR, K_A, T_A, T_B, T_C, V_RMAX, V_RMIN, K_F, T_F, T_F1, T_F2, K_E, T_E, K_C, K_D, E_1, S_EE_1, E_2, S_EE_2 =
        float.((T_R, K_PR, K_IR, K_A, T_A, T_B, T_C, V_RMAX, V_RMIN, K_F, T_F, T_F1, T_F2, K_E, T_E, K_C, K_D, E_1, S_EE_1, E_2, S_EE_2))
    n = (; T_R, K_PR, K_IR, K_A, T_A, T_B, T_C, V_RMAX, V_RMIN, K_F, T_F, T_F1, T_F2, K_E, T_E, K_C, K_D, E_1, S_EE_1, E_2, S_EE_2)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        K_PR = K_PR, [description = "Voltage regulator proportional gain"]
        K_IR = K_IR, [description = "Voltage regulator integral gain (1/s)"]
        K_A = K_A, [description = "Regulator output gain"]
        T_A = T_A, [description = "Regulator output time constant (s)"]
        T_B = T_B, [description = "Regulator denominator (lag) time constant (s)"]
        T_C = T_C, [description = "Regulator numerator (lead) time constant (s)"]
        V_RMAX = V_RMAX, [description = "Maximum exciter field voltage"]
        V_RMIN = V_RMIN, [description = "Minimum exciter field voltage"]
        K_F = K_F, [description = "Rate feedback excitation system stabilizer gain"]
        T_F = T_F, [description = "Rate feedback time const (s)"]
        T_F1 = T_F1, [description = "Feedback lead time const (s)"]
        T_F2 = T_F2, [description = "Feedback lag time const (s)"]
        K_E = K_E, [description = "Exciter field proportional constant"]
        T_E = T_E, [description = "Exciter field time constant (s)"]
        K_C = K_C, [description = "Rectifier loading factor proportional to commutating reactance"]
        K_D = K_D, [description = "Demagnetizing factor, function of exciter alternator reactances"]
        E_1 = E_1, [description = "Exciter output voltage for saturation factor S_E(E_1)"]
        S_EE_1 = S_EE_1, [description = "Exciter saturation factor at exciter output voltage E1"]
        E_2 = E_2, [description = "Exciter output voltage for saturation factor S_E(E_2)"]
        S_EE_2 = S_EE_2, [description = "Exciter saturation factor at exciter output voltage E2"]
        VR0, [guess = 1.0]   # fixed = false, from the initial equations below
        VFE0, [guess = 1.0]
        Ifd0, [guess = 1.0]
        VE0, [guess = 1.0]
    end
    systems = @named begin
        simpleLag = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        add3_1 = Add3()
        add3_2 = Add3(; k3 = -1)
        leadLag = LeadLag(; K = 1, T1 = n.T_C, T2 = n.T_B, y_start = VR0 / n.K_A, x_start = VR0 / n.K_A)
        simpleLagLim = SimpleLagLim(; K = n.K_A, T = n.T_A, outMax = n.V_RMAX, outMin = n.V_RMIN, y_start = VR0)
        rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(; K_C = n.K_C)
        rotatingExciterWithDemagnetizationLimited = RotatingExciterWithDemagnetization(; T_E = n.T_E, K_E = n.K_E,
            E_1 = n.E_1, E_2 = n.E_2, S_EE_1 = n.S_EE_1, S_EE_2 = n.S_EE_2, K_D = n.K_D, Efd0 = VE0)
        leadLag1 = LeadLag(; K = 1, T1 = n.T_F1, T2 = n.T_F2, y_start = VR0, x_start = VR0)
        imDerivativeLag = Derivative(; k = n.K_F, T = n.T_F, y_start = 0, initType = :InitialOutput, x_start = VR0)
        integrator = Integrator(; k = n.K_IR, y_start = VR0 / n.K_A)
        gain = Gain(; k = n.K_PR)
        add = Add()
    end
    rex = rotatingExciterWithDemagnetizationLimited
    rcv = rectifierCommutationVoltageDrop
    eqs = Equation[
        ECOMP ~ simpleLag.u,                # connect(ECOMP, simpleLag.u)
        DiffV.u2 ~ simpleLag.y,             # connect(DiffV.u2, simpleLag.y)
        DiffV.y ~ add3_1.u1,                # connect(DiffV.y, add3_1.u1)
        VOEL ~ add3_1.u3,                   # connect(VOEL, add3_1.u3)
        add3_1.u2 ~ VUEL,                   # connect(add3_1.u2, VUEL)
        add3_1.y ~ add3_2.u2,               # connect(add3_1.y, add3_2.u2)
        VOTHSG ~ add3_2.u1,                 # connect(VOTHSG, add3_2.u1)
        leadLag.y ~ simpleLagLim.u,         # connect(leadLag.y, simpleLagLim.u)
        EFD ~ rcv.EFD,                      # connect(EFD, rectifierCommutationVoltageDrop.EFD)
        rcv.V_EX ~ rex.EFD,                 # connect(rectifierCommutationVoltageDrop.V_EX, rotatingExciterWithDemagnetizationLimited.EFD)
        XADIFD ~ rex.XADIFD,                # connect(XADIFD, rotatingExciterWithDemagnetizationLimited.XADIFD)
        rcv.XADIFD ~ rex.XADIFD,            # connect(rectifierCommutationVoltageDrop.XADIFD, rotatingExciterWithDemagnetizationLimited.XADIFD)
        simpleLagLim.y ~ rex.I_C,           # connect(simpleLagLim.y, rotatingExciterWithDemagnetizationLimited.I_C)
        leadLag1.u ~ rex.I_C,               # connect(leadLag1.u, rotatingExciterWithDemagnetizationLimited.I_C)
        leadLag1.y ~ imDerivativeLag.u,     # connect(leadLag1.y, imDerivativeLag.u)
        imDerivativeLag.y ~ add3_2.u3,      # connect(imDerivativeLag.y, add3_2.u3)
        add.u2 ~ gain.y,                    # connect(add.u2, gain.y)
        add.u1 ~ integrator.y,              # connect(add.u1, integrator.y)
        leadLag.u ~ add.y,                  # connect(leadLag.u, add.y)
        integrator.u ~ add3_2.y,            # connect(integrator.u, add3_2.y)
        gain.u ~ add3_2.y,                  # connect(gain.u, add3_2.y)
    ]
    extend(System(eqs, t, [], pars; name, systems,
            initial_conditions = Dict(VR0 => missing, VFE0 => missing, Ifd0 => missing, VE0 => missing),
            initialization_eqs = [Ifd0 ~ XADIFD, VE0 ~ invFEX(K_C, Efd0, Ifd0),
                VFE0 ~ VE0 * (SE(VE0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2) + K_E) + Ifd0 * K_D,
                VR0 ~ VFE0, V_REF ~ ECOMP0]), base)
end
