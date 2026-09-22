# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/ESST2A.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: product = Product, add3_1 = Add3(k3 = -1), TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0),
# rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(K_C), imDerivativeLag = Derivative(y_start = 0,
# K_F, T_F, InitialOutput, x_start = 0), hV_GATE = HV_GATE, simpleLagLim = SimpleLagLim(K_A, T_A, y_start = VA0,
# V_RMAX, V_RMIN), feedback = Feedback, gain = Gain(K_E), add1 = Add, vB_default = Constant(1), booleanConstant =
# BooleanConstant(bypass_vb), swith_vb = Switch (sic), integratorLimVar = IntegratorLimVar(K = 1/T_E, y_start = Efd0),
# MaxOutput = Constant(EFD_MAX), MinOutput = Constant(0); two PwPin (Gen_terminal, Bus) connected to each other inside
# the model (pass-through). The protected RealOutput VE is a plain variable; V_T, I_T are aliases of the Gen_terminal
# pin and VE = |K_P V_T + j K_I I_T| is expanded by hand. `K_P == 0 and K_I == 0` tests parameters: decided in Julia,
# it selects `VE = 1`, `VB0 = 1` and the Boolean `bypass_vb` (a `fixed = false` Boolean that depends on parameters
# only). The other five protected `fixed = false` parameters are resolved from inputs (F-33), the `if` chain on IN0
# as an `ifelse` chain. No OpenIPSL Test instantiates this model: hand test (PLAN-04). Omitted: graphical annotations.

@component function ESST2A(; name, T_R = 0.01, V_RMAX = 4.5, V_RMIN = -4.5, K_A = 240, T_A = 0.01, K_P = 0.7, K_I = 1,
        K_C = 0.03, K_F = 0.05, T_F = 0.7, K_E = 1, T_E = 0.5, EFD_MAX = 5)
    T_R, V_RMAX, V_RMIN, K_A, T_A, K_P, K_I, K_C, K_F, T_F, K_E, T_E, EFD_MAX =
        float.((T_R, V_RMAX, V_RMIN, K_A, T_A, K_P, K_I, K_C, K_F, T_F, K_E, T_E, EFD_MAX))
    n = (; T_R, V_RMAX, V_RMIN, K_A, T_A, K_P, K_I, K_C, K_F, T_F, K_E, T_E, EFD_MAX)
    bypass_vb = K_P == 0 && K_I == 0
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        V_RMAX = V_RMAX, [description = "Maximum regulator output"]
        V_RMIN = V_RMIN, [description = "Minimum regulator output"]
        K_A = K_A, [description = "Voltage regulator gain"]
        T_A = T_A, [description = "Voltage regulator time constant (s)"]
        K_P = K_P, [description = "Potential circuit (voltage) gain coefficient"]
        K_I = K_I, [description = "Compound circuit (current) gain coefficient"]
        K_C = K_C, [description = "Rectifier loading factor proportional to commutating reactance"]
        K_F = K_F, [description = "Rate feedback gain"]
        T_F = T_F, [description = "Rate feedback time constant (s)"]
        K_E = K_E, [description = "Excitation power source output gain"]
        T_E = T_E, [description = "Excitation power source output time constant (s)"]
        EFD_MAX = EFD_MAX, [description = "Maximum exciter output"]
        Ifd0, [guess = 1.0]   # fixed = false, from the initial equations below
        IN0, [guess = 0.1]
        VB0, [guess = 1.0]
        VA0, [guess = 1.0]
        VE0, [guess = 1.0]
    end
    systems = @named begin
        product = Product()
        Gen_terminal = PwPin()
        Bus = PwPin()
        add3_1 = Add3(; k3 = -1)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        rectifierCommutationVoltageDrop = RectifierCommutationVoltageDrop(; K_C = n.K_C)
        imDerivativeLag = Derivative(; y_start = 0, k = n.K_F, T = n.T_F, initType = :InitialOutput, x_start = 0)
        hV_GATE = HV_GATE()
        simpleLagLim = SimpleLagLim(; K = n.K_A, T = n.T_A, y_start = VA0, outMax = n.V_RMAX, outMin = n.V_RMIN)
        feedback = Feedback()
        gain = Gain(; k = n.K_E)
        add1 = Add()
        vB_default = Constant(; k = 1)
        booleanConstant = BooleanConstant(; k = bypass_vb)
        swith_vb = Switch()
        integratorLimVar = IntegratorLimVar(; K = 1 / n.T_E, y_start = Efd0)
        MaxOutput = Constant(; k = n.EFD_MAX)
        MinOutput = Constant(; k = 0)
    end
    vars = @variables begin
        VE(t)
    end
    vr, vi, ir, ii = Gen_terminal.vr, Gen_terminal.vi, Gen_terminal.ir, Gen_terminal.ii
    rcv = rectifierCommutationVoltageDrop
    eqs = Equation[
        # if K_P == 0 and K_I == 0 then VE = 1 else VE = abs(K_P*V_T + j*K_I*I_T)
        VE ~ (bypass_vb ? 1 : sqrt((K_P * vr - K_I * ii)^2 + (K_P * vi + K_I * ir)^2)),
        ECOMP ~ TransducerDelay.u,           # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,        # connect(TransducerDelay.y, DiffV.u2)
        DiffV.y ~ add3_1.u2,                 # connect(DiffV.y, add3_1.u2)
        VE ~ rcv.V_EX,                       # connect(VE, rectifierCommutationVoltageDrop.V_EX)
        connect(Gen_terminal, Bus),
        XADIFD ~ rcv.XADIFD,                 # connect(XADIFD, rectifierCommutationVoltageDrop.XADIFD)
        imDerivativeLag.y ~ add3_1.u3,       # connect(imDerivativeLag.y, add3_1.u3)
        simpleLagLim.y ~ product.u1,         # connect(simpleLagLim.y, product.u1)
        feedback.u1 ~ product.y,             # connect(feedback.u1, product.y)
        gain.y ~ feedback.u2,                # connect(gain.y, feedback.u2)
        gain.u ~ EFD,                        # connect(gain.u, EFD)
        imDerivativeLag.u ~ EFD,             # connect(imDerivativeLag.u, EFD)
        VOTHSG ~ add1.u1,                    # connect(VOTHSG, add1.u1)
        VOEL ~ add1.u2,                      # connect(VOEL, add1.u2)
        add1.y ~ add3_1.u1,                  # connect(add1.y, add3_1.u1)
        booleanConstant.y ~ swith_vb.u2,     # connect(booleanConstant.y, swith_vb.u2)
        swith_vb.y ~ product.u2,             # connect(swith_vb.y, product.u2)
        feedback.y ~ integratorLimVar.u,     # connect(feedback.y, integratorLimVar.u)
        integratorLimVar.y ~ EFD,            # connect(integratorLimVar.y, EFD)
        MaxOutput.y ~ integratorLimVar.outMax, # connect(MaxOutput.y, integratorLimVar.outMax)
        MinOutput.y ~ integratorLimVar.outMin, # connect(MinOutput.y, integratorLimVar.outMin)
        add3_1.y ~ hV_GATE.u1,               # connect(add3_1.y, hV_GATE.u1)
        VUEL ~ hV_GATE.u2,                   # connect(VUEL, hV_GATE.u2)
        hV_GATE.y ~ simpleLagLim.u,          # connect(hV_GATE.y, simpleLagLim.u)
        rcv.EFD ~ swith_vb.u3,               # connect(rectifierCommutationVoltageDrop.EFD, swith_vb.u3)
        vB_default.y ~ swith_vb.u1,          # connect(vB_default.y, swith_vb.u1)
    ]
    VB0_eq = bypass_vb ? 1 : ifelse(IN0 <= 0, VE0 * 1,
        ifelse((IN0 > 0) & (IN0 <= 0.433), VE0 * (1 - 0.577 * IN0),
            ifelse((IN0 > 0.433) & (IN0 < 0.75), VE0 * sqrt(max(0.75 - IN0^2, 0)),
                ifelse((IN0 >= 0.75) & (IN0 <= 1), VE0 * 1.732 * (1 - IN0), VE0 * 0))))
    extend(System(eqs, t, vars, pars; name, systems,
            initial_conditions = Dict(Ifd0 => missing, IN0 => missing, VB0 => missing, VA0 => missing, VE0 => missing),
            initialization_eqs = [Ifd0 ~ XADIFD, VE0 ~ VE, IN0 ~ K_C * Ifd0 / VE0, VB0 ~ VB0_eq,
                VA0 ~ Efd0 * K_E / VB0, V_REF ~ ECOMP0 + VA0 / K_A]), base)
end
