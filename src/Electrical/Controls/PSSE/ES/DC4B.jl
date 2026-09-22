# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/DC4B.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: rotatingExciterLimited = RotatingExciterLimited(T_E, K_E = K_E0, E_1, E_2, S_EE_1, S_EE_2, Efd0),
# TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0), Vpss_Add = Add, add3_1 = Add3(k3 = -1), derivativeLag =
# Derivative(K_F, T_F, x_start = Efd0, y_start = 0, InitialOutput), product1 = Product, lV_GATE, hV_GATE,
# switch_VUEL = Switch_VUEL(n = UEL), switch_VOEL = Switch_VOEL(n = OEL), VUEL_VOEL_add = Add, gain = Gain(V_RMIN),
# gain1 = Gain(V_RMAX), pID_No_Windup = PID_No_Windup(K_PR, K_IR, K_DR, T_DR, V_RMAX/K_A, V_RMIN/K_A, y_start_int),
# simpleLagLimVar = SimpleLagLimVar(K_A, T_A, y_start = VR0); the port VT is a plain variable. The causal connects
# are equalities. The seven protected `fixed = false` parameters are resolved from inputs (F-33); `SE_Efd0 =
# SE(EFD0, …)` reads the input EFD0 itself (sic). Omitted: graphical annotations.

@component function DC4B(; name, T_R = 0.004, K_PR = 13, K_IR = 4, K_DR = 6, T_DR = 0.03, V_RMAX = 10.8, V_RMIN = -7,
        K_A = 10.8, T_A = 0.01, K_E = 1, T_E = 0.8, K_F = 0.03, T_F = 1, E_1 = 2.4, S_EE_1 = 0.03, E_2 = 5.0,
        S_EE_2 = 0.5, UEL = 1, OEL = 1)
    T_R, K_PR, K_IR, K_DR, T_DR, V_RMAX, V_RMIN, K_A, T_A, K_E, T_E, K_F, T_F, E_1, S_EE_1, E_2, S_EE_2 =
        float.((T_R, K_PR, K_IR, K_DR, T_DR, V_RMAX, V_RMIN, K_A, T_A, K_E, T_E, K_F, T_F, E_1, S_EE_1, E_2, S_EE_2))
    n = (; T_R, K_PR, K_IR, K_DR, T_DR, V_RMAX, V_RMIN, K_A, T_A, K_E, T_E, K_F, T_F, E_1, S_EE_1, E_2, S_EE_2, UEL, OEL)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, EFD0, VOTHSG, ECOMP = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        K_PR = K_PR, [description = "Voltage regulator proportional gain"]
        K_IR = K_IR, [description = "Voltage regulator integral gain"]
        K_DR = K_DR, [description = "Voltage regulator derivative gain"]
        T_DR = T_DR, [description = "Voltage regulator derivative channel time constant (s)"]
        V_RMAX = V_RMAX, [description = "Maximum regulator output"]
        V_RMIN = V_RMIN, [description = "Minimum regulator output"]
        K_A = K_A, [description = "Voltage regulator gain"]
        T_A = T_A, [description = "Voltage regulator time constant (s)"]
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
        VT0, [guess = 1.0]
        y_start_int, [guess = 0.1]
    end
    systems = @named begin
        rotatingExciterLimited = RotatingExciterLimited(; T_E = n.T_E, K_E = K_E0, E_1 = n.E_1, E_2 = n.E_2,
            S_EE_1 = n.S_EE_1, S_EE_2 = n.S_EE_2, Efd0 = Efd0)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        Vpss_Add = Add()
        add3_1 = Add3(; k3 = -1)
        derivativeLag = Derivative(; k = n.K_F, T = n.T_F, x_start = Efd0, y_start = 0, initType = :InitialOutput)
        product1 = Product()
        lV_GATE = LV_GATE()
        hV_GATE = HV_GATE()
        switch_VUEL = Switch_VUEL(; n = n.UEL)
        switch_VOEL = Switch_VOEL(; n = n.OEL)
        VUEL_VOEL_add = Add()
        gain = Gain(; k = n.V_RMIN)
        gain1 = Gain(; k = n.V_RMAX)
        pID_No_Windup = PID_No_Windup(; K_P = n.K_PR, K_I = n.K_IR, K_D = n.K_DR, T_D = n.T_DR, V_RMAX = n.V_RMAX / n.K_A,
            V_RMIN = n.V_RMIN / n.K_A, y_start_int = y_start_int)
        simpleLagLimVar = SimpleLagLimVar(; K = n.K_A, T = n.T_A, y_start = VR0)
    end
    vars = @variables begin
        VT(t)
    end
    eqs = Equation[
        rotatingExciterLimited.EFD ~ EFD,                # connect(rotatingExciterLimited.EFD, EFD)
        ECOMP ~ TransducerDelay.u,                       # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,                    # connect(TransducerDelay.y, DiffV.u2)
        VOTHSG ~ Vpss_Add.u1,                            # connect(VOTHSG, Vpss_Add.u1)
        DiffV.y ~ Vpss_Add.u2,                           # connect(DiffV.y, Vpss_Add.u2)
        Vpss_Add.y ~ add3_1.u1,                          # connect(Vpss_Add.y, add3_1.u1)
        derivativeLag.u ~ rotatingExciterLimited.EFD,    # connect(derivativeLag.u, rotatingExciterLimited.EFD)
        VUEL ~ switch_VUEL.u,                            # connect(VUEL, switch_VUEL.u)
        VOEL ~ switch_VOEL.u,                            # connect(VOEL, switch_VOEL.u)
        switch_VUEL.y1 ~ VUEL_VOEL_add.u1,               # connect(switch_VUEL.y1, VUEL_VOEL_add.u1)
        switch_VOEL.y1 ~ VUEL_VOEL_add.u2,               # connect(switch_VOEL.y1, VUEL_VOEL_add.u2)
        VUEL_VOEL_add.y ~ add3_1.u2,                     # connect(VUEL_VOEL_add.y, add3_1.u2)
        derivativeLag.y ~ add3_1.u3,                     # connect(derivativeLag.y, add3_1.u3)
        VT ~ gain.u,                                     # connect(VT, gain.u)
        gain1.u ~ gain.u,                                # connect(gain1.u, gain.u)
        product1.u1 ~ gain.u,                            # connect(product1.u1, gain.u)
        add3_1.y ~ pID_No_Windup.u,                      # connect(add3_1.y, pID_No_Windup.u)
        pID_No_Windup.y ~ hV_GATE.u2,                    # connect(pID_No_Windup.y, hV_GATE.u2)
        switch_VUEL.y2 ~ hV_GATE.u1,                     # connect(switch_VUEL.y2, hV_GATE.u1)
        hV_GATE.y ~ lV_GATE.u2,                          # connect(hV_GATE.y, lV_GATE.u2)
        switch_VOEL.y2 ~ lV_GATE.u1,                     # connect(switch_VOEL.y2, lV_GATE.u1)
        lV_GATE.y ~ product1.u2,                         # connect(lV_GATE.y, product1.u2)
        gain.y ~ simpleLagLimVar.outMin,                 # connect(gain.y, simpleLagLimVar.outMin)
        gain1.y ~ simpleLagLimVar.outMax,                # connect(gain1.y, simpleLagLimVar.outMax)
        product1.y ~ simpleLagLimVar.u,                  # connect(product1.y, simpleLagLimVar.u)
        simpleLagLimVar.y ~ rotatingExciterLimited.I_C,  # connect(simpleLagLimVar.y, rotatingExciterLimited.I_C)
    ]
    dc = calculate_dc_exciter_params(n.V_RMAX, n.V_RMIN, n.K_E, n.E_2, n.S_EE_2, Efd0, SE_Efd0)
    extend(System(eqs, t, vars, pars; name, systems,
            initial_conditions = Dict(SE_Efd0 => missing, VR0 => missing, V_RMAX0 => missing, K_E0 => missing,
                V_RMIN0 => missing, VT0 => missing, y_start_int => missing),
            initialization_eqs = [SE_Efd0 ~ SE(EFD0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2),
                V_RMAX0 ~ dc[1], V_RMIN0 ~ dc[2], K_E0 ~ dc[3],
                VR0 ~ Efd0 * (K_E0 + SE_Efd0), V_REF ~ ECOMP0, VT0 ~ VT, y_start_int ~ VR0 / (K_A * VT0)]), base)
end
