# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/IEEET1.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: sum2 = Add3, sum3 = Add(k2 = -1), derivativeLag = Derivative(K_F, T_F, y_start = 0, InitialOutput,
# x_start = Efd0), simpleLagLim = SimpleLagLim(K_A, T_A, y_start = VR0, V_RMAX, V_RMIN), rotatingExciter =
# RotatingExciter(T_E, E_1, E_2, S_EE_1, S_EE_2, Efd0, K_E = KE0), TransducerDelay = SimpleLag(K = 1, T_R,
# y_start = ECOMP0), DiffV1 = Add. The causal connects are equalities. The five protected `fixed = false` parameters
# (SE_Efd0, VRMAX0, VRMIN0, KE0, VR0) are resolved from inputs (F-33): `SE` takes the symbolic Efd0 and the
# 3-tuple of `calculate_dc_exciter_params` is spread over three initialization equations; the .mo uses V_RMAX/V_RMIN
# (not VRMAX0/VRMIN0) as the limits of simpleLagLim (sic). Omitted: Icons.VerifiedModel, graphical annotations.

@component function IEEET1(; name, T_R = 1, K_A = 40, T_A = 0.04, V_RMAX = 7.3, V_RMIN = -7.3, K_E = 1, T_E = 0.8,
        K_F = 0.03, T_F = 1, E_1 = 2.4, S_EE_1 = 0.03, E_2 = 5.0, S_EE_2 = 0.5)
    T_R, K_A, T_A, V_RMAX, V_RMIN, K_E, T_E, K_F, T_F, E_1, S_EE_1, E_2, S_EE_2 =
        float.((T_R, K_A, T_A, V_RMAX, V_RMIN, K_E, T_E, K_F, T_F, E_1, S_EE_1, E_2, S_EE_2))
    n = (; T_R, K_A, T_A, V_RMAX, V_RMIN, K_E, T_E, K_F, T_F, E_1, S_EE_1, E_2, S_EE_2)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        K_A = K_A, [description = "Regulator output gain"]
        T_A = T_A, [description = "Regulator output time constant (s)"]
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
        VRMAX0, [guess = 1.0, description = "Maximum AVR output"]   # fixed = false, from the initial equations below
        VRMIN0, [guess = -1.0, description = "Minimum AVR output"]
        KE0, [guess = 1.0, description = "Exciter field gain"]
        SE_Efd0, [guess = 0.0]
        VR0, [guess = 1.0]
    end
    systems = @named begin
        sum2 = Add3()
        sum3 = Add(; k2 = -1)
        derivativeLag = Derivative(; k = n.K_F, T = n.T_F, y_start = 0, initType = :InitialOutput, x_start = Efd0)
        simpleLagLim = SimpleLagLim(; K = n.K_A, T = n.T_A, y_start = VR0, outMax = n.V_RMAX, outMin = n.V_RMIN)
        rotatingExciter = RotatingExciter(; T_E = n.T_E, E_1 = n.E_1, E_2 = n.E_2, S_EE_1 = n.S_EE_1, S_EE_2 = n.S_EE_2,
            Efd0 = Efd0, K_E = KE0)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        DiffV1 = Add()
    end
    eqs = Equation[
        sum3.u2 ~ derivativeLag.y,               # connect(sum3.u2, derivativeLag.y)
        sum3.y ~ simpleLagLim.u,                 # connect(sum3.y, simpleLagLim.u)
        rotatingExciter.EFD ~ EFD,               # connect(rotatingExciter.EFD, EFD)
        simpleLagLim.y ~ rotatingExciter.I_C,    # connect(simpleLagLim.y, rotatingExciter.I_C)
        derivativeLag.u ~ EFD,                   # connect(derivativeLag.u, EFD)
        ECOMP ~ TransducerDelay.u,               # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,            # connect(TransducerDelay.y, DiffV.u2)
        sum2.y ~ sum3.u1,                        # connect(sum2.y, sum3.u1)
        DiffV.y ~ sum2.u2,                       # connect(DiffV.y, sum2.u2)
        VOTHSG ~ sum2.u1,                        # connect(VOTHSG, sum2.u1)
        DiffV1.u1 ~ VUEL,                        # connect(DiffV1.u1, VUEL)
        DiffV1.u2 ~ VOEL,                        # connect(DiffV1.u2, VOEL)
        DiffV1.y ~ sum2.u3,                      # connect(DiffV1.y, sum2.u3)
    ]
    dc = calculate_dc_exciter_params(n.V_RMAX, n.V_RMIN, n.K_E, n.E_2, n.S_EE_2, Efd0, SE_Efd0)
    extend(System(eqs, t, [], pars; name, systems,
            initial_conditions = Dict(VRMAX0 => missing, VRMIN0 => missing, KE0 => missing, SE_Efd0 => missing, VR0 => missing),
            initialization_eqs = [SE_Efd0 ~ SE(Efd0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2),
                VRMAX0 ~ dc[1], VRMIN0 ~ dc[2], KE0 ~ dc[3],
                VR0 ~ Efd0 * (KE0 + SE_Efd0), V_REF ~ VR0 / K_A + ECOMP0]), base)
end
