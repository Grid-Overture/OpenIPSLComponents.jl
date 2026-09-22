# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/IEEEX1.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: LL = LeadLag(T_C, T_B, K = 1, y_start = VR0/K_A, x_start = V_REF - ECOMP0), V_Erro1 = Add3(k3 = -1),
# imDerivativeLag = Derivative(K_F, T_F, y_start = 0, InitialOutput, x_start = Efd0), V_Erro2 = Add3, SL =
# SimpleLagLim(K_A, T_A, y_start = VR0, outMax = V_RMAX0, outMin = V_RMIN0), rotatingExciter = RotatingExciter(T_E,
# E_1, E_2, S_EE_1, S_EE_2, Efd0, K_E = K_E0), TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0). The causal
# connects are equalities. The five protected `fixed = false` parameters are resolved from inputs (F-33);
# `SE_Efd0 = SE(EFD0, …)` reads the input EFD0 itself (sic). Omitted: graphical annotations.

@component function IEEEX1(; name, T_R = 0, K_A = 40, T_A = 0.04, T_B = 0, T_C = 0, V_RMAX = 7.3, V_RMIN = -7.3,
        K_E = 1, T_E = 0.8, K_F = 0.03, T_F = 1, E_1 = 2.4, S_EE_1 = 0.03, E_2 = 5.0, S_EE_2 = 0.5)
    T_R, K_A, T_A, T_B, T_C, V_RMAX, V_RMIN, K_E, T_E, K_F, T_F, E_1, S_EE_1, E_2, S_EE_2 =
        float.((T_R, K_A, T_A, T_B, T_C, V_RMAX, V_RMIN, K_E, T_E, K_F, T_F, E_1, S_EE_1, E_2, S_EE_2))
    n = (; T_R, K_A, T_A, T_B, T_C, V_RMAX, V_RMIN, K_E, T_E, K_F, T_F, E_1, S_EE_1, E_2, S_EE_2)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, EFD0, VOTHSG, ECOMP = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        K_A = K_A, [description = "Regulator output gain"]
        T_A = T_A, [description = "Regulator output time constant (s)"]
        T_B = T_B, [description = "Regulator denominator (lag) time constant (s)"]
        T_C = T_C, [description = "Regulator numerator (lead) time constant (s)"]
        V_RMAX = V_RMAX, [description = "Maximum regulator output"]
        V_RMIN = V_RMIN, [description = "Minimum regulator output"]
        K_E = K_E, [description = "Exciter field proportional constant"]
        T_E = T_E, [description = "Exciter field time constant (s)"]
        K_F = K_F, [description = "Rate feedback excitation system stabilizer gain"]
        T_F = T_F, [description = "Rate feedback time constant (s)"]
        E_1 = E_1, [description = "Exciter output voltage for saturation factor S_E(E_1)"]
        S_EE_1 = S_EE_1, [description = "Exciter saturation factor at exciter output voltage E1"]
        E_2 = E_2, [description = "Exciter output voltage for saturation factor S_E(E_2)"]
        S_EE_2 = S_EE_2, [description = "Exciter saturation factor at exciter output voltage E2"]
        SE_Efd0, [guess = 0.0]   # fixed = false, from the initial equations below
        VR0, [guess = 1.0]
        V_RMAX0, [guess = 1.0]
        K_E0, [guess = 1.0]
        V_RMIN0, [guess = -1.0]
    end
    systems = @named begin
        LL = LeadLag(; T1 = n.T_C, T2 = n.T_B, K = 1, y_start = VR0 / n.K_A, x_start = V_REF - ECOMP0)
        V_Erro1 = Add3(; k3 = -1)
        imDerivativeLag = Derivative(; k = n.K_F, T = n.T_F, y_start = 0, initType = :InitialOutput, x_start = Efd0)
        V_Erro2 = Add3()
        SL = SimpleLagLim(; K = n.K_A, T = n.T_A, y_start = VR0, outMax = V_RMAX0, outMin = V_RMIN0)
        rotatingExciter = RotatingExciter(; T_E = n.T_E, E_1 = n.E_1, E_2 = n.E_2, S_EE_1 = n.S_EE_1, S_EE_2 = n.S_EE_2,
            Efd0 = Efd0, K_E = K_E0)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
    end
    eqs = Equation[
        V_Erro1.y ~ LL.u,                        # connect(V_Erro1.y, LL.u)
        LL.y ~ SL.u,                             # connect(LL.y, SL.u)
        DiffV.y ~ V_Erro1.u2,                    # connect(DiffV.y, V_Erro1.u2)
        SL.y ~ rotatingExciter.I_C,              # connect(SL.y, rotatingExciter.I_C)
        rotatingExciter.EFD ~ EFD,               # connect(rotatingExciter.EFD, EFD)
        imDerivativeLag.y ~ V_Erro1.u3,          # connect(imDerivativeLag.y, V_Erro1.u3)
        imDerivativeLag.u ~ EFD,                 # connect(imDerivativeLag.u, EFD)
        VOTHSG ~ V_Erro2.u1,                     # connect(VOTHSG, V_Erro2.u1)
        VUEL ~ V_Erro2.u2,                       # connect(VUEL, V_Erro2.u2)
        VOEL ~ V_Erro2.u3,                       # connect(VOEL, V_Erro2.u3)
        V_Erro2.y ~ V_Erro1.u1,                  # connect(V_Erro2.y, V_Erro1.u1)
        TransducerDelay.y ~ DiffV.u2,            # connect(TransducerDelay.y, DiffV.u2)
        TransducerDelay.u ~ ECOMP,               # connect(TransducerDelay.u, ECOMP)
    ]
    dc = calculate_dc_exciter_params(n.V_RMAX, n.V_RMIN, n.K_E, n.E_2, n.S_EE_2, Efd0, SE_Efd0)
    extend(System(eqs, t, [], pars; name, systems,
            initial_conditions = Dict(SE_Efd0 => missing, VR0 => missing, V_RMAX0 => missing, K_E0 => missing, V_RMIN0 => missing),
            initialization_eqs = [SE_Efd0 ~ SE(EFD0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2),
                V_RMAX0 ~ dc[1], V_RMIN0 ~ dc[2], K_E0 ~ dc[3],
                VR0 ~ Efd0 * (K_E0 + SE_Efd0), V_REF ~ VR0 / K_A + ECOMP0]), base)
end
