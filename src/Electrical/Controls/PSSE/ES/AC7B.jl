# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/AC7B.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: imDerivativeLag = Derivative(K_F3, T_F3, y_start = 0, InitialOutput), add3_2 = Add3, TransducerDelay =
# SimpleLag(K = 1, T_R, y_start = ECOMP0), add1 = Add(k2 = -1), add = Add, gain1 = Gain(K_F2), gain2 = Gain(K_F1),
# product = Product, gain4 = Gain(K_P), rotatingExciterWithDemagnetizationVarLim = RotatingExciterWithDemagnetizationVarLim
# (T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, Efd0 = VE0, K_D, EFD(start = VE0), outMax(start = max_lim0)), lowLim = Constant
# (VE_MIN), FEMAX = Constant(VFE_MAX), DiffV2 = Add(k2 = -1), se1 = ImSE, const = Constant(K_E) (instance `const_`),
# DiffV3 = Add, division = Division, gain5 = Gain(K_D), add3 = Add(k2 = -1), pID_No_Windup = PID_No_Windup(K_PR, K_IR,
# K_DR, T_DR, V_RMAX, V_RMIN, y_start_int_PID), variableLimiter = VariableLimiter, Upper_Limit = Constant(inf), gain =
# Gain(-K_L), rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(K_C), pI_No_Windup = PI_No_Windup(K_PA,
# K_IA, VA_MAX, VA_MIN, y_start_int_PI); the port VT is a plain variable. The causal connects are equalities. The .mo
# has no parameter defaults and redeclares the base's `Efd0` identically; the nine protected `fixed = false`
# parameters are resolved from inputs (F-33), and the two `start` modifiers of the sub-model are this parent's
# `guesses` (PLAN-00 point 3). Omitted: graphical annotations.

@component function AC7B(; name, T_R, K_PR, K_IR, K_DR, T_DR, V_RMIN, V_RMAX, K_PA, K_IA, VA_MIN, VA_MAX, K_P, K_L, T_E,
        K_C, K_D, K_E, K_F1, K_F2, K_F3, T_F3, VE_MIN, VFE_MAX, E_1, S_EE_1, E_2, S_EE_2)
    T_R, K_PR, K_IR, K_DR, T_DR, V_RMIN, V_RMAX, K_PA, K_IA, VA_MIN, VA_MAX, K_P, K_L, T_E, K_C, K_D, K_E, K_F1, K_F2, K_F3, T_F3, VE_MIN, VFE_MAX, E_1, S_EE_1, E_2, S_EE_2 =
        float.((T_R, K_PR, K_IR, K_DR, T_DR, V_RMIN, V_RMAX, K_PA, K_IA, VA_MIN, VA_MAX, K_P, K_L, T_E, K_C, K_D, K_E, K_F1, K_F2, K_F3, T_F3, VE_MIN, VFE_MAX, E_1, S_EE_1, E_2, S_EE_2))
    n = (; T_R, K_PR, K_IR, K_DR, T_DR, V_RMIN, V_RMAX, K_PA, K_IA, VA_MIN, VA_MAX, K_P, K_L, T_E, K_C, K_D, K_E, K_F1, K_F2, K_F3, T_F3, VE_MIN, VFE_MAX, E_1, S_EE_1, E_2, S_EE_2)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Filter time constant (s)"]
        K_PR = K_PR, [description = "Voltage regulator proportional gain"]
        K_IR = K_IR, [description = "Voltage regulator integral gain"]
        K_DR = K_DR, [description = "Voltage regulator derivative gain"]
        T_DR = T_DR, [description = "Lag time constant (s)"]
        V_RMIN = V_RMIN, [description = "Minimum voltage regulator output"]
        V_RMAX = V_RMAX, [description = "Maximum voltage regulator output"]
        K_PA = K_PA, [description = "Voltage regulator proportional gain"]
        K_IA = K_IA, [description = "Voltage regulator integral gain"]
        VA_MIN = VA_MIN, [description = "Minimum voltage regulator output"]
        VA_MAX = VA_MAX, [description = "Maximum voltage regulator output"]
        K_P = K_P, [description = "Potential circuit gain coefficient"]
        K_L = K_L, [description = "Exciter field voltage lower limit parameter"]
        T_E = T_E, [description = "Exciter time constant, integration rate associated with exciter control (s)"]
        K_C = K_C, [description = "Rectifier loading factor proportional to commutating reactance"]
        K_D = K_D, [description = "Demagnetizing factor, a function of exciter alternator reactances"]
        K_E = K_E, [description = "Exciter constant related to self-excited field"]
        K_F1 = K_F1, [description = "Excitation control system stabilizer gain"]
        K_F2 = K_F2, [description = "Excitation control system stabilizer gain"]
        K_F3 = K_F3, [description = "Excitation control system stabilizer gain"]
        T_F3 = T_F3, [description = "Excitation control system stabilizer time constant (s)"]
        VE_MIN = VE_MIN, [description = "Minimum exciter voltage output"]
        VFE_MAX = VFE_MAX, [description = "Exciter field current limit reference"]
        E_1 = E_1, [description = "Exciter alternator output voltage 1 at which saturation is defined"]
        S_EE_1 = S_EE_1, [description = "Exciter saturation function value at E1"]
        E_2 = E_2, [description = "Exciter alternator output voltage 2 at which saturation is defined"]
        S_EE_2 = S_EE_2, [description = "Exciter saturation function value at E2"]
        VA0, [guess = 1.0]   # fixed = false, from the initial equations below
        VR0, [guess = 1.0]
        VFE0, [guess = 1.0]
        Ifd0, [guess = 1.0]
        VE0, [guess = 1.0]
        VT0, [guess = 1.0]
        max_lim0, [guess = 5.0]
        y_start_int_PID, [guess = 1.0]
        y_start_int_PI, [guess = 1.0]
    end
    systems = @named begin
        imDerivativeLag = Derivative(; k = n.K_F3, T = n.T_F3, y_start = 0, initType = :InitialOutput)
        add3_2 = Add3()
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        add1 = Add(; k2 = -1)
        add = Add()
        gain1 = Gain(; k = n.K_F2)
        gain2 = Gain(; k = n.K_F1)
        product = Product()
        gain4 = Gain(; k = n.K_P)
        rotatingExciterWithDemagnetizationVarLim = RotatingExciterWithDemagnetizationVarLim(; T_E = n.T_E, K_E = n.K_E,
            E_1 = n.E_1, E_2 = n.E_2, S_EE_1 = n.S_EE_1, S_EE_2 = n.S_EE_2, Efd0 = VE0, K_D = n.K_D)
        lowLim = Constant(; k = n.VE_MIN)
        FEMAX = Constant(; k = n.VFE_MAX)
        DiffV2 = Add(; k2 = -1)
        se1 = ImSE(; SE1 = n.S_EE_1, SE2 = n.S_EE_2, E1 = n.E_1, E2 = n.E_2)
        const_ = Constant(; k = n.K_E)   # `const` in the .mo
        DiffV3 = Add()
        division = Division()
        gain5 = Gain(; k = n.K_D)
        add3 = Add(; k2 = -1)
        pID_No_Windup = PID_No_Windup(; K_P = n.K_PR, K_I = n.K_IR, K_D = n.K_DR, T_D = n.T_DR, V_RMAX = n.V_RMAX,
            V_RMIN = n.V_RMIN, y_start_int = y_start_int_PID)
        variableLimiter = VariableLimiter()
        Upper_Limit = Constant(; k = Modelica.Constants.inf)
        gain = Gain(; k = -n.K_L)
        rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(; K_C = n.K_C)
        pI_No_Windup = PI_No_Windup(; K_P = n.K_PA, K_I = n.K_IA, V_RMAX = n.VA_MAX, V_RMIN = n.VA_MIN,
            y_start_int = y_start_int_PI)
    end
    vars = @variables begin
        VT(t)
    end
    rex = rotatingExciterWithDemagnetizationVarLim
    rcv = rectifierCommutationVoltageDrop
    eqs = Equation[
        DiffV.u2 ~ TransducerDelay.y,            # connect(DiffV.u2, TransducerDelay.y)
        TransducerDelay.u ~ ECOMP,               # connect(TransducerDelay.u, ECOMP)
        gain1.y ~ add.u2,                        # connect(gain1.y, add.u2)
        add.y ~ add1.u2,                         # connect(add.y, add1.u2)
        product.u1 ~ gain4.y,                    # connect(product.u1, gain4.y)
        gain2.y ~ add.u1,                        # connect(gain2.y, add.u1)
        FEMAX.y ~ DiffV2.u1,                     # connect(FEMAX.y, DiffV2.u1)
        gain5.y ~ DiffV2.u2,                     # connect(gain5.y, DiffV2.u2)
        se1.VE_OUT ~ DiffV3.u1,                  # connect(se1.VE_OUT, DiffV3.u1)
        const_.y ~ DiffV3.u2,                    # connect(const.y, DiffV3.u2)
        DiffV2.y ~ division.u1,                  # connect(DiffV2.y, division.u1)
        DiffV3.y ~ division.u2,                  # connect(DiffV3.y, division.u2)
        rcv.V_EX ~ rex.EFD,                      # connect(rectifierCommutationVoltageDrop.V_EX, rotatingExciterWithDemagnetizationVarLim.EFD)
        gain2.u ~ EFD,                           # connect(gain2.u, EFD)
        rex.V_FE ~ gain1.u,                      # connect(rotatingExciterWithDemagnetizationVarLim.V_FE, gain1.u)
        VOTHSG ~ add3_2.u1,                      # connect(VOTHSG, add3_2.u1)
        VUEL ~ add3_2.u2,                        # connect(VUEL, add3_2.u2)
        DiffV.y ~ add3_2.u3,                     # connect(DiffV.y, add3_2.u3)
        add3_2.y ~ add3.u1,                      # connect(add3_2.y, add3.u1)
        imDerivativeLag.y ~ add3.u2,             # connect(imDerivativeLag.y, add3.u2)
        VT ~ gain4.u,                            # connect(VT, gain4.u)
        gain.u ~ rex.V_FE,                       # connect(gain.u, rotatingExciterWithDemagnetizationVarLim.V_FE)
        product.y ~ variableLimiter.u,           # connect(product.y, variableLimiter.u)
        pID_No_Windup.y ~ add1.u1,               # connect(pID_No_Windup.y, add1.u1)
        imDerivativeLag.u ~ gain1.u,             # connect(imDerivativeLag.u, gain1.u)
        Upper_Limit.y ~ variableLimiter.limit1,  # connect(Upper_Limit.y, variableLimiter.limit1)
        gain.y ~ variableLimiter.limit2,         # connect(gain.y, variableLimiter.limit2)
        se1.VE_IN ~ rex.EFD,                     # connect(se1.VE_IN, rotatingExciterWithDemagnetizationVarLim.EFD)
        lowLim.y ~ rex.outMin,                   # connect(lowLim.y, rotatingExciterWithDemagnetizationVarLim.outMin)
        division.y ~ rex.outMax,                 # connect(division.y, rotatingExciterWithDemagnetizationVarLim.outMax)
        rcv.EFD ~ EFD,                           # connect(rectifierCommutationVoltageDrop.EFD, EFD)
        gain5.u ~ XADIFD,                        # connect(gain5.u, XADIFD)
        rex.XADIFD ~ XADIFD,                     # connect(rotatingExciterWithDemagnetizationVarLim.XADIFD, XADIFD)
        rcv.XADIFD ~ XADIFD,                     # connect(rectifierCommutationVoltageDrop.XADIFD, XADIFD)
        variableLimiter.y ~ rex.I_C,             # connect(variableLimiter.y, rotatingExciterWithDemagnetizationVarLim.I_C)
        pI_No_Windup.y ~ product.u2,             # connect(pI_No_Windup.y, product.u2)
        add1.y ~ pI_No_Windup.u,                 # connect(add1.y, pI_No_Windup.u)
        add3.y ~ pID_No_Windup.u,                # connect(add3.y, pID_No_Windup.u)
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            initial_conditions = Dict(VA0 => missing, VR0 => missing, VFE0 => missing, Ifd0 => missing, VE0 => missing,
                VT0 => missing, max_lim0 => missing, y_start_int_PID => missing, y_start_int_PI => missing),
            guesses = Dict(rex.EFD => VE0, rex.outMax => max_lim0),   # EFD(start = VE0), outMax(start = max_lim0)
            initialization_eqs = [VE0 ~ invFEX(K_C, Efd0, Ifd0),
                VFE0 ~ VE0 * (SE(VE0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2) + K_E) + Ifd0 * K_D,
                VA0 ~ VFE0 / (K_P * VT0), VR0 ~ Efd0 * K_F1 + VFE0 * K_F2, V_REF ~ ECOMP0, VT0 ~ VT, Ifd0 ~ XADIFD,
                max_lim0 ~ (VFE_MAX - K_D * Ifd0) / (K_E + SE(VE0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2)),
                y_start_int_PID ~ VR0, y_start_int_PI ~ VA0]), base)
end
