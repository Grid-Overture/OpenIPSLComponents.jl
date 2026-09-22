# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/ESURRY.mo (extends ES/BaseClasses/BaseExciter(VoltageReference(k = V_REF)),
# the base's own modifier)
# Blocks: simpleLag = SimpleLag(K = 1, T_R, y_start = ECOMP0), leadLag = LeadLag(K = 1, T_A, T_B), leadLag1 =
# LeadLag(K = 1, T_C, T_D), both with y_start = x_start = (VR0 - (I_REF - K_16 VFE0))/K_10, gain = Gain(K_10), add3_2 =
# Add3(k3 = -1), limiter = Limiter(V_RMAX, V_RMIN), rotatingExciterWithDemagnetization =
# RotatingExciterWithDemagnetizationLimited(T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, K_D, Efd0 = VE0, Sum(k3 = K_D): the
# parent's own redeclare, a no-op), rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(K_C), simpleLag1
# = SimpleLag(K = 1, T_1, y_start = VFE0), gain1 = Gain(K_16), const = Constant(I_REF) (instance `const_`), add3_3 =
# Add3(k2 = -1), washout = Derivative(K_F, T_F, InitialOutput, x_start = VFE0), add = Add. The causal connects are
# equalities. The .mo redeclares the base's Efd0, V_REF, ECOMP0 and repeats `Efd0 = EFD0`, `ECOMP0 = ECOMP` in its
# `initial equation`: the duplicates are not written (Modelica merges the declarations and the repeated equations
# over-determine the initialization, F-37); I_REF, VR0, Ifd0, VE0, VFE0 are resolved from inputs (F-33). Its OpenIPSL
# Test does not initialize in OpenModelica 1.25 (F-37): hand test. Omitted: Icons.VerifiedModel, graphical annotations.

@component function ESURRY(; name, T_R = 0, T_1 = 0, T_A = 0, T_B = 0, T_C = 0, T_D = 0, T_E = 0.8, K_10 = 1, K_16 = 1,
        K_F = 0.03, T_F = 1, K_C = 0.2, K_D = 0.48, K_E = 1, E_1 = 5.25, E_2 = 7, S_EE_1 = 0.03, S_EE_2 = 0.1,
        V_RMAX = 6.03, V_RMIN = -5.43)
    T_R, T_1, T_A, T_B, T_C, T_D, T_E, K_10, K_16, K_F, T_F, K_C, K_D, K_E, E_1, E_2, S_EE_1, S_EE_2, V_RMAX, V_RMIN =
        float.((T_R, T_1, T_A, T_B, T_C, T_D, T_E, K_10, K_16, K_F, T_F, K_C, K_D, K_E, E_1, E_2, S_EE_1, S_EE_2, V_RMAX, V_RMIN))
    n = (; T_R, T_1, T_A, T_B, T_C, T_D, T_E, K_10, K_16, K_F, T_F, K_C, K_D, K_E, E_1, E_2, S_EE_1, S_EE_2, V_RMAX, V_RMIN)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Transducer time constant (s)"]
        T_1 = T_1, [description = "Time constant (s)"]
        T_A = T_A, [description = "Lead-lag numerator time constant (s)"]
        T_B = T_B, [description = "Lead-lag denominator time constant (s)"]
        T_C = T_C, [description = "Lead-lag numerator time constant (s)"]
        T_D = T_D, [description = "Lead-lag denominator time constant (s)"]
        T_E = T_E, [description = "Exciter time constant (s)"]
        K_10 = K_10, [description = "Gain"]
        K_16 = K_16, [description = "Gain"]
        K_F = K_F, [description = "Rate feedback gain"]
        T_F = T_F, [description = "Rate feedback time constant (s)"]
        K_C = K_C, [description = "Rectifier regulation factor"]
        K_D = K_D, [description = "Exciter internal reactance"]
        K_E = K_E, [description = "Exciter field resistance constant"]
        E_1 = E_1, [description = "Field voltage value, 1"]
        E_2 = E_2, [description = "Field voltage value, 2"]
        S_EE_1 = S_EE_1, [description = "Saturation factor at E1"]
        S_EE_2 = S_EE_2, [description = "Saturation factor at E2"]
        V_RMAX = V_RMAX, [description = "Voltage regulator maximum output"]
        V_RMIN = V_RMIN, [description = "Voltage regulator minimum output"]
        I_REF, [guess = 1.0]   # fixed = false, from the initial equations below
        VR0, [guess = 1.0]
        Ifd0, [guess = 1.0]
        VE0, [guess = 1.0]
        VFE0, [guess = 1.0]
    end
    ll_start = (VR0 - (I_REF - K_16 * VFE0)) / n.K_10
    systems = @named begin
        simpleLag = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        leadLag = LeadLag(; K = 1, T1 = n.T_A, T2 = n.T_B, y_start = ll_start, x_start = ll_start)
        leadLag1 = LeadLag(; K = 1, T1 = n.T_C, T2 = n.T_D, y_start = ll_start, x_start = ll_start)
        gain = Gain(; k = n.K_10)
        add3_2 = Add3(; k3 = -1)
        limiter = Limiter(; uMax = n.V_RMAX, uMin = n.V_RMIN)
        rotatingExciterWithDemagnetization = RotatingExciterWithDemagnetizationLimited(; T_E = n.T_E, K_E = n.K_E,
            E_1 = n.E_1, E_2 = n.E_2, S_EE_1 = n.S_EE_1, S_EE_2 = n.S_EE_2, K_D = n.K_D, Efd0 = VE0)
        rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(; K_C = n.K_C)
        simpleLag1 = SimpleLag(; K = 1, T = n.T_1, y_start = VFE0)
        gain1 = Gain(; k = n.K_16)
        const_ = Constant(; k = I_REF)   # `const` in the .mo
        add3_3 = Add3(; k2 = -1)
        washout = Derivative(; k = n.K_F, T = n.T_F, initType = :InitialOutput, x_start = VFE0)
        add = Add()
    end
    rex = rotatingExciterWithDemagnetization
    rcv = rectifierCommutationVoltageDrop
    eqs = Equation[
        ECOMP ~ simpleLag.u,                 # connect(ECOMP, simpleLag.u)
        simpleLag.y ~ DiffV.u2,              # connect(simpleLag.y, DiffV.u2)
        leadLag.y ~ leadLag1.u,              # connect(leadLag.y, leadLag1.u)
        leadLag1.y ~ gain.u,                 # connect(leadLag1.y, gain.u)
        gain.y ~ add3_2.u1,                  # connect(gain.y, add3_2.u1)
        add3_2.y ~ limiter.u,                # connect(add3_2.y, limiter.u)
        limiter.y ~ rex.I_C,                 # connect(limiter.y, rotatingExciterWithDemagnetization.I_C)
        rex.EFD ~ rcv.V_EX,                  # connect(rotatingExciterWithDemagnetization.EFD, rectifierCommutationVoltageDrop.V_EX)
        rcv.EFD ~ EFD,                       # connect(rectifierCommutationVoltageDrop.EFD, EFD)
        gain1.y ~ add3_3.u2,                 # connect(gain1.y, add3_3.u2)
        const_.y ~ add3_3.u1,                # connect(const.y, add3_3.u1)
        simpleLag1.y ~ gain1.u,              # connect(simpleLag1.y, gain1.u)
        add3_3.y ~ add3_2.u2,                # connect(add3_3.y, add3_2.u2)
        washout.u ~ gain1.u,                 # connect(washout.u, gain1.u)
        washout.y ~ add3_2.u3,               # connect(washout.y, add3_2.u3)
        rex.V_FE ~ simpleLag1.u,             # connect(rotatingExciterWithDemagnetization.V_FE, simpleLag1.u)
        XADIFD ~ rex.XADIFD,                 # connect(XADIFD, rotatingExciterWithDemagnetization.XADIFD)
        rcv.XADIFD ~ rex.XADIFD,             # connect(rectifierCommutationVoltageDrop.XADIFD, rotatingExciterWithDemagnetization.XADIFD)
        VUEL ~ add3_3.u3,                    # connect(VUEL, add3_3.u3)
        DiffV.y ~ add.u2,                    # connect(DiffV.y, add.u2)
        VOTHSG ~ add.u1,                     # connect(VOTHSG, add.u1)
        add.y ~ leadLag.u,                   # connect(add.y, leadLag.u)
    ]
    extend(System(eqs, t, [], pars; name, systems,
            initial_conditions = Dict(I_REF => missing, VR0 => missing, Ifd0 => missing, VE0 => missing, VFE0 => missing),
            initialization_eqs = [Ifd0 ~ XADIFD, VE0 ~ invFEX(K_C, Efd0, Ifd0),
                VFE0 ~ VE0 * (SE(VE0, n.S_EE_1, n.S_EE_2, n.E_1, n.E_2) + K_E) + Ifd0 * K_D, VR0 ~ VFE0,
                V_REF ~ (VR0 - (I_REF - K_16 * VFE0)) / K_10 + ECOMP0, I_REF ~ K_16 * VFE0]), base)
end
