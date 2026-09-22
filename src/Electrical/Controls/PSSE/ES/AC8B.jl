# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/AC8B.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: rotatingExciterWithDemagnetizationVarLim = RotatingExciterWithDemagnetizationVarLim(T_E, K_E, E_1, E_2,
# S_EE_1, S_EE_2, Efd0 = VE0, K_D), lowLim = Constant(VE_MIN), FEMAX = Constant(VFE_MAX), DiffV2 = Add(k2 = -K_D),
# se1 = ImSE, const = Constant(K_E) (instance `const_`), DiffV3 = Add, div0block = Div0block, pID_No_Windup =
# PID_No_Windup(K_PR, K_IR, K_DR, T_DR, VPID_MAX, VPID_MIN, y_start_int), TransducerDelay = SimpleLag(K = 1, T_R,
# y_start = ECOMP0), VS = Add3, DiffV1 = Add(k2 = 1), simpleLagLim = SimpleLagLim(K_A, T_A, y_start = VR0, V_RMAX,
# V_RMIN), rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(K_C). The causal connects are equalities.
# The .mo has no parameter defaults and redeclares the base's `XADIFD` port and `Efd0` identically; the five protected
# `fixed = false` parameters are resolved from inputs (F-33); `V_REF = ECOMP` reads ECOMP itself (sic).
# Omitted: graphical annotations.

@component function AC8B(; name, T_R, K_PR, K_IR, K_DR, T_DR, VPID_MAX, VPID_MIN, K_A, T_A, V_RMAX, V_RMIN, T_E, K_C, K_D,
        K_E, E_1, S_EE_1, E_2, S_EE_2, VFE_MAX, VE_MIN)
    T_R, K_PR, K_IR, K_DR, T_DR, VPID_MAX, VPID_MIN, K_A, T_A, V_RMAX, V_RMIN, T_E, K_C, K_D, K_E, E_1, S_EE_1, E_2, S_EE_2, VFE_MAX, VE_MIN =
        float.((T_R, K_PR, K_IR, K_DR, T_DR, VPID_MAX, VPID_MIN, K_A, T_A, V_RMAX, V_RMIN, T_E, K_C, K_D, K_E, E_1, S_EE_1, E_2, S_EE_2, VFE_MAX, VE_MIN))
    n = (; T_R, K_PR, K_IR, K_DR, T_DR, VPID_MAX, VPID_MIN, K_A, T_A, V_RMAX, V_RMIN, T_E, K_C, K_D, K_E, E_1, S_EE_1, E_2, S_EE_2, VFE_MAX, VE_MIN)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Filter time constant (s)"]
        K_PR = K_PR, [description = "Voltage regulator proportional gain"]
        K_IR = K_IR, [description = "Voltage regulator integral gain"]
        K_DR = K_DR, [description = "Voltage regulator derivative gain"]
        T_DR = T_DR, [description = "Regulator derivative block time constant (s)"]
        VPID_MAX = VPID_MAX, [description = "PID maximum limit"]
        VPID_MIN = VPID_MIN, [description = "PID minimum limit"]
        K_A = K_A, [description = "Voltage regulator gain"]
        T_A = T_A, [description = "Voltage regulator time constant (s)"]
        V_RMAX = V_RMAX, [description = "Maximum voltage regulator output"]
        V_RMIN = V_RMIN, [description = "Minimum voltage regulator output"]
        T_E = T_E, [description = "Exciter time constant, integration rate associated with exciter control (s)"]
        K_C = K_C, [description = "Rectifier loading factor proportional to commutating reactance"]
        K_D = K_D, [description = "Demagnetizing factor, a function of exciter alternator reactances"]
        K_E = K_E, [description = "Exciter constant related to self-excited field"]
        E_1 = E_1, [description = "Exciter alternator output voltage 1 at which saturation is defined"]
        S_EE_1 = S_EE_1, [description = "Exciter saturation function value at E1"]
        E_2 = E_2, [description = "Exciter alternator output voltage 2 at which saturation is defined"]
        S_EE_2 = S_EE_2, [description = "Exciter saturation function value at E2"]
        VFE_MAX = VFE_MAX, [description = "Exciter field current limit reference"]
        VE_MIN = VE_MIN, [description = "Minimum exciter voltage output"]
        VR0, [guess = 1.0]   # fixed = false, from the initial equations below
        Ifd0, [guess = 1.0]
        VE0, [guess = 1.0]
        VFE0, [guess = 1.0]
        y_start_int, [guess = 1.0]
    end
    systems = @named begin
        rotatingExciterWithDemagnetizationVarLim = RotatingExciterWithDemagnetizationVarLim(; T_E = n.T_E, K_E = n.K_E,
            E_1 = n.E_1, E_2 = n.E_2, S_EE_1 = n.S_EE_1, S_EE_2 = n.S_EE_2, Efd0 = VE0, K_D = n.K_D)
        lowLim = Constant(; k = n.VE_MIN)
        FEMAX = Constant(; k = n.VFE_MAX)
        DiffV2 = Add(; k2 = -n.K_D)
        se1 = ImSE(; SE1 = n.S_EE_1, SE2 = n.S_EE_2, E1 = n.E_1, E2 = n.E_2)
        const_ = Constant(; k = n.K_E)   # `const` in the .mo
        DiffV3 = Add()
        div0block = Div0block()
        pID_No_Windup = PID_No_Windup(; K_P = n.K_PR, K_I = n.K_IR, K_D = n.K_DR, T_D = n.T_DR, V_RMAX = n.VPID_MAX,
            V_RMIN = n.VPID_MIN, y_start_int = y_start_int)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        VS = Add3()
        DiffV1 = Add(; k2 = +1)
        simpleLagLim = SimpleLagLim(; K = n.K_A, T = n.T_A, y_start = VR0, outMax = n.V_RMAX, outMin = n.V_RMIN)
        rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(; K_C = n.K_C)
    end
    rex = rotatingExciterWithDemagnetizationVarLim
    rcv = rectifierCommutationVoltageDrop
    eqs = Equation[
        TransducerDelay.u ~ ECOMP,               # connect(TransducerDelay.u, ECOMP)
        DiffV.u2 ~ TransducerDelay.y,            # connect(DiffV.u2, TransducerDelay.y)
        VOTHSG ~ VS.u1,                          # connect(VOTHSG, VS.u1)
        rcv.EFD ~ EFD,                           # connect(rectifierCommutationVoltageDrop.EFD, EFD)
        rcv.V_EX ~ rex.EFD,                      # connect(rectifierCommutationVoltageDrop.V_EX, rotatingExciterWithDemagnetizationVarLim.EFD)
        FEMAX.y ~ DiffV2.u1,                     # connect(FEMAX.y, DiffV2.u1)
        DiffV3.u1 ~ const_.y,                    # connect(DiffV3.u1, const.y)
        DiffV3.u2 ~ se1.VE_OUT,                  # connect(DiffV3.u2, se1.VE_OUT)
        rex.I_C ~ simpleLagLim.y,                # connect(rotatingExciterWithDemagnetizationVarLim.I_C, simpleLagLim.y)
        VUEL ~ VS.u2,                            # connect(VUEL, VS.u2)
        VOEL ~ VS.u3,                            # connect(VOEL, VS.u3)
        DiffV.y ~ DiffV1.u1,                     # connect(DiffV.y, DiffV1.u1)
        VS.y ~ DiffV1.u2,                        # connect(VS.y, DiffV1.u2)
        div0block.y ~ rex.outMax,                # connect(div0block.y, rotatingExciterWithDemagnetizationVarLim.outMax)
        rex.outMin ~ lowLim.y,                   # connect(rotatingExciterWithDemagnetizationVarLim.outMin, lowLim.y)
        XADIFD ~ DiffV2.u2,                      # connect(XADIFD, DiffV2.u2)
        rex.XADIFD ~ DiffV2.u2,                  # connect(rotatingExciterWithDemagnetizationVarLim.XADIFD, DiffV2.u2)
        rcv.XADIFD ~ DiffV2.u2,                  # connect(rectifierCommutationVoltageDrop.XADIFD, DiffV2.u2)
        se1.VE_IN ~ rex.EFD,                     # connect(se1.VE_IN, rotatingExciterWithDemagnetizationVarLim.EFD)
        DiffV1.y ~ pID_No_Windup.u,              # connect(DiffV1.y, pID_No_Windup.u)
        pID_No_Windup.y ~ simpleLagLim.u,        # connect(pID_No_Windup.y, simpleLagLim.u)
        DiffV2.y ~ div0block.u1,                 # connect(DiffV2.y, div0block.u1)
        DiffV3.y ~ div0block.u2,                 # connect(DiffV3.y, div0block.u2)
    ]
    extend(System(eqs, t, [], pars; name, systems,
            initial_conditions = Dict(VR0 => missing, Ifd0 => missing, VE0 => missing, VFE0 => missing, y_start_int => missing),
            initialization_eqs = [VE0 ~ invFEX(K_C, Efd0, Ifd0),
                VFE0 ~ VE0 * (SE(VE0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2) + K_E) + Ifd0 * K_D,
                VR0 ~ VFE0, V_REF ~ ECOMP, y_start_int ~ VR0 / K_A, Ifd0 ~ XADIFD]), base)
end
