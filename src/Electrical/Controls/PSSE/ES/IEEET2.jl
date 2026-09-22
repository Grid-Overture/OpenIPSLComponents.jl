# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/IEEET2.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: add3_1 = Add3, add = Add(k2 = -1), simpleLag = SimpleLag(K = 1, T_F2, y_start = 0), derivativeLag =
# Derivative(K_F, y_start = 0, T_F1, InitialOutput, x_start = VR0), simpleLagLim = SimpleLagLim(K_A, T_A, y_start =
# VR0, outMax = V_RMAX0, outMin = V_RMIN0), rotatingExciter = RotatingExciter(T_E, K_E = K_E0, E_1, E_2, S_EE_1,
# S_EE_2, Efd0), TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0), Limiters = Add. The causal connects are
# equalities. The five protected `fixed = false` parameters are resolved from inputs (F-33); `SE_Efd0 = SE(EFD0, …)`
# reads the input EFD0 itself (sic). Omitted: Icons.VerifiedModel, graphical annotations.

@component function IEEET2(; name, T_R = 0.02, K_A = 200.0, T_A = 0.001, V_RMAX = 6.08, V_RMIN = -6.08, K_E = 1,
        T_E = 0.55, K_F = 0.06, T_F1 = 0.3, T_F2 = 0.6, E_1 = 2.85, S_EE_1 = 0.3, E_2 = 3.8, S_EE_2 = 0.6)
    T_R, K_A, T_A, V_RMAX, V_RMIN, K_E, T_E, K_F, T_F1, T_F2, E_1, S_EE_1, E_2, S_EE_2 =
        float.((T_R, K_A, T_A, V_RMAX, V_RMIN, K_E, T_E, K_F, T_F1, T_F2, E_1, S_EE_1, E_2, S_EE_2))
    n = (; T_R, K_A, T_A, V_RMAX, V_RMIN, K_E, T_E, K_F, T_F1, T_F2, E_1, S_EE_1, E_2, S_EE_2)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, EFD0, VOTHSG, ECOMP = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        K_A = K_A, [description = "Regulator output gain"]
        T_A = T_A, [description = "Regulator output time constant (s)"]
        V_RMAX = V_RMAX, [description = "Maximum regulator output"]
        V_RMIN = V_RMIN, [description = "Minimum regulator output"]
        K_E = K_E, [description = "Exciter field proportional constant"]
        T_E = T_E, [description = "Exciter field time constant (s)"]
        K_F = K_F, [description = "Rate feedback excitation system stabilizer gain"]
        T_F1 = T_F1, [description = "Rate feedback excitation system stabilizer first time constant (s)"]
        T_F2 = T_F2, [description = "Rate feedback excitation system stabilizer second time constant (s)"]
        E_1 = E_1, [description = "Exciter output voltage for saturation factor S_E(E_1)"]
        S_EE_1 = S_EE_1, [description = "Exciter saturation factor at exciter output voltage E1"]
        E_2 = E_2, [description = "Exciter output voltage for saturation factor S_E(E_2)"]
        S_EE_2 = S_EE_2, [description = "Exciter saturation factor at exciter output voltage E2"]
        V_RMAX0, [guess = 1.0]   # fixed = false, from the initial equations below
        V_RMIN0, [guess = -1.0]
        K_E0, [guess = 1.0]
        SE_Efd0, [guess = 0.0]
        VR0, [guess = 1.0]
    end
    systems = @named begin
        add3_1 = Add3()
        add = Add(; k2 = -1)
        simpleLag = SimpleLag(; K = 1, T = n.T_F2, y_start = 0)
        derivativeLag = Derivative(; k = n.K_F, y_start = 0, T = n.T_F1, initType = :InitialOutput, x_start = VR0)
        simpleLagLim = SimpleLagLim(; K = n.K_A, T = n.T_A, y_start = VR0, outMax = V_RMAX0, outMin = V_RMIN0)
        rotatingExciter = RotatingExciter(; T_E = n.T_E, K_E = K_E0, E_1 = n.E_1, E_2 = n.E_2, S_EE_1 = n.S_EE_1,
            S_EE_2 = n.S_EE_2, Efd0 = Efd0)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        Limiters = Add()
    end
    eqs = Equation[
        add3_1.y ~ add.u1,                       # connect(add3_1.y, add.u1)
        simpleLag.y ~ add.u2,                    # connect(simpleLag.y, add.u2)
        simpleLag.u ~ derivativeLag.y,           # connect(simpleLag.u, derivativeLag.y)
        add.y ~ simpleLagLim.u,                  # connect(add.y, simpleLagLim.u)
        rotatingExciter.EFD ~ EFD,               # connect(rotatingExciter.EFD, EFD)
        ECOMP ~ TransducerDelay.u,               # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,            # connect(TransducerDelay.y, DiffV.u2)
        simpleLagLim.y ~ rotatingExciter.I_C,    # connect(simpleLagLim.y, rotatingExciter.I_C)
        DiffV.y ~ add3_1.u2,                     # connect(DiffV.y, add3_1.u2)
        VOTHSG ~ add3_1.u1,                      # connect(VOTHSG, add3_1.u1)
        VUEL ~ Limiters.u1,                      # connect(VUEL, Limiters.u1)
        Limiters.u2 ~ VOEL,                      # connect(Limiters.u2, VOEL)
        Limiters.y ~ add3_1.u3,                  # connect(Limiters.y, add3_1.u3)
        derivativeLag.u ~ rotatingExciter.I_C,   # connect(derivativeLag.u, rotatingExciter.I_C)
    ]
    dc = calculate_dc_exciter_params(n.V_RMAX, n.V_RMIN, n.K_E, n.E_2, n.S_EE_2, Efd0, SE_Efd0)
    extend(System(eqs, t, [], pars; name, systems,
            initial_conditions = Dict(V_RMAX0 => missing, V_RMIN0 => missing, K_E0 => missing, SE_Efd0 => missing, VR0 => missing),
            initialization_eqs = [SE_Efd0 ~ SE(EFD0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2),
                V_RMAX0 ~ dc[1], V_RMIN0 ~ dc[2], K_E0 ~ dc[3],
                VR0 ~ Efd0 * (K_E0 + SE_Efd0), V_REF ~ VR0 / K_A + ECOMP0]), base)
end
