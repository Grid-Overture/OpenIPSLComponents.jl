# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/ESAC2A.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: hV_GATE = HV_GATE, lV_GATE = LV_GATE, imLeadLag = LeadLag(K = 1, T_C, T_B, y_start = x_start = VR0/K_A),
# imSimpleLag = SimpleLag(K = 1, y_start = ECOMP0, T_R), limiter1 = Limiter(V_RMAX, V_RMIN), simpleLagLim =
# SimpleLagLim(K_A, T_A, y_start = VR0, V_AMAX, V_AMIN), derivative = Derivative(K_F, T_F, InitialOutput, y_start = 0,
# x_start = VFE0), rotatingExciterWithDemagnetization = RotatingExciterWithDemagnetizationVarLim(T_E, K_E, E_1, E_2,
# S_EE_1, S_EE_2, K_D, Efd0 = VE0), add3_1 = Add3(k3 = -1), rectifierCommutationVoltageDrop =
# RectifierCommutationVoltageDrop(K_C), lowLim = Constant(0), FEMAX = Constant(V_FEMAX), DiffV1 = Add(k2 = -K_D), se1 =
# ImSE(S_EE_1, S_EE_2, E_1, E_2), const = Constant(K_E) (instance `const_`), DiffV2 = Add, div0block = Div0block,
# DiffV3 = Add(k1 = -1), gain = Gain(K_H), gain1 = Gain(K_B). The causal connects are equalities. The .mo redeclares
# the base's `Efd0` identically (nothing to add); VR0, Ifd0, VE0, VFE0 are `fixed = false` resolved from inputs
# (F-33). First user of IntegratorLimVar through the VarLim exciter (F-22 point 5). Omitted: Icons.VerifiedModel,
# graphical annotations.

@component function ESAC2A(; name, T_R = 0, T_B = 0, T_C = 0, K_A = 400, T_A = 0.02, V_AMAX = 9, V_AMIN = -5.43, K_B = 1,
        V_RMAX = 9, V_RMIN = -5.43, T_E = 0.8, V_FEMAX = 4.4, K_H = 0, K_F = 0.03, T_F = 1, K_C = 0.2, K_D = 0.48, K_E = 1,
        E_1 = 5.25, E_2 = 7, S_EE_1 = 0.03, S_EE_2 = 0.1)
    T_R, T_B, T_C, K_A, T_A, V_AMAX, V_AMIN, K_B, V_RMAX, V_RMIN, T_E, V_FEMAX, K_H, K_F, T_F, K_C, K_D, K_E, E_1, E_2, S_EE_1, S_EE_2 =
        float.((T_R, T_B, T_C, K_A, T_A, V_AMAX, V_AMIN, K_B, V_RMAX, V_RMIN, T_E, V_FEMAX, K_H, K_F, T_F, K_C, K_D, K_E, E_1, E_2, S_EE_1, S_EE_2))
    n = (; T_R, T_B, T_C, K_A, T_A, V_AMAX, V_AMIN, K_B, V_RMAX, V_RMIN, T_E, V_FEMAX, K_H, K_F, T_F, K_C, K_D, K_E, E_1, E_2, S_EE_1, S_EE_2)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        T_B = T_B, [description = "Regulator denominator (lag) time constant (s)"]
        T_C = T_C, [description = "Regulator numerator (lead) time constant (s)"]
        K_A = K_A, [description = "Regulator output gain"]
        T_A = T_A, [description = "Regulator output time constant (s)"]
        V_AMAX = V_AMAX, [description = "Maximum regulator output"]
        V_AMIN = V_AMIN, [description = "Minimum regulator output"]
        K_B = K_B, [description = "Second stage regulator gain"]
        V_RMAX = V_RMAX, [description = "Maximum exciter field output"]
        V_RMIN = V_RMIN, [description = "Minimum exciter field output"]
        T_E = T_E, [description = "Exciter field time constant (s)"]
        V_FEMAX = V_FEMAX, [description = "Maximum exciter field current limit reference"]
        K_H = K_H, [description = "Exciter field current regulator feedback gain"]
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
        hV_GATE = HV_GATE()
        lV_GATE = LV_GATE()
        imLeadLag = LeadLag(; K = 1, T1 = n.T_C, T2 = n.T_B, y_start = VR0 / n.K_A, x_start = VR0 / n.K_A)
        imSimpleLag = SimpleLag(; K = 1, y_start = ECOMP0, T = n.T_R)
        limiter1 = Limiter(; uMax = n.V_RMAX, uMin = n.V_RMIN)
        simpleLagLim = SimpleLagLim(; K = n.K_A, T = n.T_A, y_start = VR0, outMax = n.V_AMAX, outMin = n.V_AMIN)
        derivative = Derivative(; k = n.K_F, T = n.T_F, initType = :InitialOutput, y_start = 0, x_start = VFE0)
        rotatingExciterWithDemagnetization = RotatingExciterWithDemagnetizationVarLim(; T_E = n.T_E, K_E = n.K_E,
            E_1 = n.E_1, E_2 = n.E_2, S_EE_1 = n.S_EE_1, S_EE_2 = n.S_EE_2, K_D = n.K_D, Efd0 = VE0)
        add3_1 = Add3(; k3 = -1)
        rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(; K_C = n.K_C)
        lowLim = Constant(; k = 0)
        FEMAX = Constant(; k = n.V_FEMAX)
        DiffV1 = Add(; k2 = -n.K_D)
        se1 = ImSE(; SE1 = n.S_EE_1, SE2 = n.S_EE_2, E1 = n.E_1, E2 = n.E_2)
        const_ = Constant(; k = n.K_E)   # `const` in the .mo
        DiffV2 = Add()
        div0block = Div0block()
        DiffV3 = Add(; k1 = -1)
        gain = Gain(; k = n.K_H)
        gain1 = Gain(; k = n.K_B)
    end
    rex = rotatingExciterWithDemagnetization
    rcv = rectifierCommutationVoltageDrop
    eqs = Equation[
        imLeadLag.y ~ simpleLagLim.u,       # connect(imLeadLag.y, simpleLagLim.u)
        limiter1.y ~ rex.I_C,               # connect(limiter1.y, rotatingExciterWithDemagnetization.I_C)
        ECOMP ~ imSimpleLag.u,              # connect(ECOMP, imSimpleLag.u)
        VUEL ~ hV_GATE.u2,                  # connect(VUEL, hV_GATE.u2)
        imSimpleLag.y ~ DiffV.u2,           # connect(imSimpleLag.y, DiffV.u2)
        add3_1.y ~ imLeadLag.u,             # connect(add3_1.y, imLeadLag.u)
        DiffV.y ~ add3_1.u2,                # connect(DiffV.y, add3_1.u2)
        VOTHSG ~ add3_1.u1,                 # connect(VOTHSG, add3_1.u1)
        derivative.y ~ add3_1.u3,           # connect(derivative.y, add3_1.u3)
        derivative.u ~ rex.V_FE,            # connect(derivative.u, rotatingExciterWithDemagnetization.V_FE)
        rex.EFD ~ rcv.V_EX,                 # connect(rotatingExciterWithDemagnetization.EFD, rectifierCommutationVoltageDrop.V_EX)
        rcv.XADIFD ~ rex.XADIFD,            # connect(rectifierCommutationVoltageDrop.XADIFD, rotatingExciterWithDemagnetization.XADIFD)
        rcv.EFD ~ EFD,                      # connect(rectifierCommutationVoltageDrop.EFD, EFD)
        lV_GATE.y ~ limiter1.u,             # connect(lV_GATE.y, limiter1.u)
        lowLim.y ~ rex.outMin,              # connect(lowLim.y, rotatingExciterWithDemagnetization.outMin)
        FEMAX.y ~ DiffV1.u1,                # connect(FEMAX.y, DiffV1.u1)
        DiffV1.u2 ~ rex.XADIFD,             # connect(DiffV1.u2, rotatingExciterWithDemagnetization.XADIFD)
        se1.VE_IN ~ EFD,                    # connect(se1.VE_IN, EFD)
        DiffV2.u1 ~ const_.y,               # connect(DiffV2.u1, const.y)
        DiffV2.u2 ~ se1.VE_OUT,             # connect(DiffV2.u2, se1.VE_OUT)
        div0block.u1 ~ DiffV1.y,            # connect(div0block.u1, DiffV1.y)
        DiffV2.y ~ div0block.u2,            # connect(DiffV2.y, div0block.u2)
        div0block.y ~ rex.outMax,           # connect(div0block.y, rotatingExciterWithDemagnetization.outMax)
        XADIFD ~ rex.XADIFD,                # connect(XADIFD, rotatingExciterWithDemagnetization.XADIFD)
        simpleLagLim.y ~ DiffV3.u2,         # connect(simpleLagLim.y, DiffV3.u2)
        gain.u ~ rex.V_FE,                  # connect(gain.u, rotatingExciterWithDemagnetization.V_FE)
        gain.y ~ DiffV3.u1,                 # connect(gain.y, DiffV3.u1)
        DiffV3.y ~ gain1.u,                 # connect(DiffV3.y, gain1.u)
        gain1.y ~ hV_GATE.u1,               # connect(gain1.y, hV_GATE.u1)
        VOEL ~ lV_GATE.u2,                  # connect(VOEL, lV_GATE.u2)
        hV_GATE.y ~ lV_GATE.u1,             # connect(hV_GATE.y, lV_GATE.u1)
    ]
    extend(System(eqs, t, [], pars; name, systems,
            initial_conditions = Dict(VR0 => missing, Ifd0 => missing, VE0 => missing, VFE0 => missing),
            initialization_eqs = [Ifd0 ~ XADIFD, VE0 ~ invFEX(K_C, Efd0, Ifd0),
                VFE0 ~ VE0 * (SE(VE0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2) + K_E) + Ifd0 * K_D,
                VR0 ~ VFE0, V_REF ~ VR0 / K_A + ECOMP0]), base)
end
