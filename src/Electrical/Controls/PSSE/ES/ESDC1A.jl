# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/ESDC1A.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: imDerivativeLag = Derivative(K_F, T_F1, y_start = 0, InitialOutput, x_start = Efd0), hV_GATE = HV_GATE,
# imLeadLag = LeadLag(K = 1, T_C, T_B, y_start = V_R0/K_A), add3_1 = Add3(k3 = -1), simpleLagLim = SimpleLagLim(K_A,
# T_A, y_start = V_R0, outMax = V_RMAX0, outMin = V_RMIN0), rotatingExciterLimited = RotatingExciterLimited(T_E, E_1,
# E_2, S_EE_1, S_EE_2, Efd0, K_E = K_E0), TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0), DiffV1 = Add.
# The causal connects are equalities. The five protected `fixed = false` parameters are resolved from inputs (F-33);
# with V_RMAX = 0 and K_E = 0 (the Test) both automatic branches of `calculate_dc_exciter_params` are active.
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function ESDC1A(; name, T_R = 0, K_A = 400, T_A = 0.02, T_B = 0, T_C = 0, V_RMAX = 9, V_RMIN = -5.43,
        K_E = 1, T_E = 0.8, K_F = 0.03, T_F1 = 1, E_1 = 5.25, E_2 = 7, S_EE_1 = 0.03, S_EE_2 = 0.1)
    T_R, K_A, T_A, T_B, T_C, V_RMAX, V_RMIN, K_E, T_E, K_F, T_F1, E_1, E_2, S_EE_1, S_EE_2 =
        float.((T_R, K_A, T_A, T_B, T_C, V_RMAX, V_RMIN, K_E, T_E, K_F, T_F1, E_1, E_2, S_EE_1, S_EE_2))
    n = (; T_R, K_A, T_A, T_B, T_C, V_RMAX, V_RMIN, K_E, T_E, K_F, T_F1, E_1, E_2, S_EE_1, S_EE_2)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        K_A = K_A, [description = "Regulator output gain"]
        T_A = T_A, [description = "Regulator time constant (s)"]
        T_B = T_B, [description = "Regulator denominator (lag) time constant (s)"]
        T_C = T_C, [description = "Regulator numerator (lead) time constant (s)"]
        V_RMAX = V_RMAX, [description = "Maximum controller output"]
        V_RMIN = V_RMIN, [description = "Minimum controller output"]
        K_E = K_E, [description = "Exciter field proportional constant"]
        T_E = T_E, [description = "Exciter field time constant (s)"]
        K_F = K_F, [description = "Rate feedback gain"]
        T_F1 = T_F1, [description = "Rate feedback time constant (s)"]
        E_1 = E_1, [description = "Exciter output voltage for saturation factor S_E(E_1)"]
        E_2 = E_2, [description = "Exciter output voltage for saturation factor S_E(E_2)"]
        S_EE_1 = S_EE_1, [description = "Exciter saturation factor at exciter output voltage E_1"]
        S_EE_2 = S_EE_2, [description = "Exciter saturation factor at exciter output voltage E_2"]
        V_R0, [guess = 1.0]   # fixed = false, from the initial equations below
        V_RMAX0, [guess = 1.0]
        K_E0, [guess = 1.0]
        V_RMIN0, [guess = -1.0]
        SE_Efd0, [guess = 0.0]
    end
    systems = @named begin
        imDerivativeLag = Derivative(; k = n.K_F, T = n.T_F1, y_start = 0, initType = :InitialOutput, x_start = Efd0)
        hV_GATE = HV_GATE()
        imLeadLag = LeadLag(; K = 1, T1 = n.T_C, T2 = n.T_B, y_start = V_R0 / n.K_A)
        add3_1 = Add3(; k3 = -1)
        simpleLagLim = SimpleLagLim(; K = n.K_A, T = n.T_A, y_start = V_R0, outMax = V_RMAX0, outMin = V_RMIN0)
        rotatingExciterLimited = RotatingExciterLimited(; T_E = n.T_E, E_1 = n.E_1, E_2 = n.E_2, S_EE_1 = n.S_EE_1,
            S_EE_2 = n.S_EE_2, Efd0 = Efd0, K_E = K_E0)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        DiffV1 = Add()
    end
    eqs = Equation[
        add3_1.y ~ imLeadLag.u,                          # connect(add3_1.y, imLeadLag.u)
        hV_GATE.y ~ simpleLagLim.u,                      # connect(hV_GATE.y, simpleLagLim.u)
        simpleLagLim.y ~ rotatingExciterLimited.I_C,     # connect(simpleLagLim.y, rotatingExciterLimited.I_C)
        ECOMP ~ TransducerDelay.u,                       # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,                    # connect(TransducerDelay.y, DiffV.u2)
        rotatingExciterLimited.EFD ~ EFD,                # connect(rotatingExciterLimited.EFD, EFD)
        imLeadLag.y ~ hV_GATE.u1,                        # connect(imLeadLag.y, hV_GATE.u1)
        VUEL ~ hV_GATE.u2,                               # connect(VUEL, hV_GATE.u2)
        imDerivativeLag.u ~ EFD,                         # connect(imDerivativeLag.u, EFD)
        imDerivativeLag.y ~ add3_1.u3,                   # connect(imDerivativeLag.y, add3_1.u3)
        DiffV.y ~ add3_1.u2,                             # connect(DiffV.y, add3_1.u2)
        VOTHSG ~ DiffV1.u1,                              # connect(VOTHSG, DiffV1.u1)
        VOEL ~ DiffV1.u2,                                # connect(VOEL, DiffV1.u2)
        DiffV1.y ~ add3_1.u1,                            # connect(DiffV1.y, add3_1.u1)
    ]
    dc = calculate_dc_exciter_params(n.V_RMAX, n.V_RMIN, n.K_E, n.E_2, n.S_EE_2, Efd0, SE_Efd0)
    extend(System(eqs, t, [], pars; name, systems,
            initial_conditions = Dict(V_R0 => missing, V_RMAX0 => missing, K_E0 => missing, V_RMIN0 => missing, SE_Efd0 => missing),
            initialization_eqs = [SE_Efd0 ~ SE(Efd0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2),
                V_RMAX0 ~ dc[1], V_RMIN0 ~ dc[2], K_E0 ~ dc[3],
                V_R0 ~ Efd0 * (K_E0 + SE_Efd0), V_REF ~ V_R0 / K_A + ECOMP0]), base)
end
