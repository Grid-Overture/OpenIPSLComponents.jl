# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/ESST1A.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: imDerivativeLag = Derivative(K_F, T_F, y_start = 0, InitialOutput, x_start = Efd0), imLimited = Limiter
# (V_IMAX, V_IMIN), hV_GATE, hV_GATE1 = HV_GATE, lV_GATE = LV_GATE, imGain = Gain(K_LR), Vref1 = Constant(I_LR),
# imLeadLag = LeadLag(K = 1, T_C, T_B, y_start = VA0/K_A, x_start = V_REF - ECOMP0), imLeadLag1 = LeadLag(K = 1,
# T_C1, T_B1, y_start = x_start = VA0/K_A), add3_1 = Add3(k1 = -1), simpleLagLim = SimpleLagLim(K_A, T_A,
# y_start = VA0, V_AMAX, V_AMIN), add2 = Add(k1 = -1), imLimited1 = Limiter(uMax = inf, uMin = 0), add3_2 =
# Add3(k3 = -1), imGain1 = Gain(V_RMIN), imGain2 = Gain(V_RMAX), add3 = Add(k1 = -1), imGain3 = Gain(K_C),
# variableLimiter = VariableLimiter, TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0), Limiters = Add.
# The extra ports VOTHSG2, VUEL2, VUEL3, VT are plain variables; the causal connects are equalities. `IFD0` and
# `VA0` are `fixed = false` resolved from inputs (F-33); the `if IFD0 < I_LR` of the `initial equation` tests an
# initialization unknown and is an `ifelse` in the equation. Omitted: Icons.VerifiedModel, graphical annotations.

@component function ESST1A(; name, T_R = 0, V_IMAX = 99, V_IMIN = -99, T_C = 0, T_B = 0, T_C1 = 0, T_B1 = 0, K_A = 400,
        T_A = 0.02, V_AMAX = 9, V_AMIN = -5.43, V_RMAX = 9, V_RMIN = -5.43, K_C = 0.2, K_F = 0.03, T_F = 1, K_LR = 4.54,
        I_LR = 4.4)
    T_R, V_IMAX, V_IMIN, T_C, T_B, T_C1, T_B1, K_A, T_A, V_AMAX, V_AMIN, V_RMAX, V_RMIN, K_C, K_F, T_F, K_LR, I_LR =
        float.((T_R, V_IMAX, V_IMIN, T_C, T_B, T_C1, T_B1, K_A, T_A, V_AMAX, V_AMIN, V_RMAX, V_RMIN, K_C, K_F, T_F, K_LR, I_LR))
    n = (; T_R, V_IMAX, V_IMIN, T_C, T_B, T_C1, T_B1, K_A, T_A, V_AMAX, V_AMIN, V_RMAX, V_RMIN, K_C, K_F, T_F, K_LR, I_LR)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        V_IMAX = V_IMAX, [description = "Maximum voltage error (regulator input)"]
        V_IMIN = V_IMIN, [description = "Minimum voltage error (regulator input)"]
        T_C = T_C, [description = "Regulator numerator (lead) time constant. First lead-lag (s)"]
        T_B = T_B, [description = "Regulator denominator (lag) time constant. First lead-lag (s)"]
        T_C1 = T_C1, [description = "Regulator numerator (lead) time constant. Second lead-lag (s)"]
        T_B1 = T_B1, [description = "Regulator denominator (lag) time constant. Second lead-lag (s)"]
        K_A = K_A, [description = "Voltage regulator gain"]
        T_A = T_A, [description = "Voltage regulator time constant (s)"]
        V_AMAX = V_AMAX, [description = "Maximum regulator output"]
        V_AMIN = V_AMIN, [description = "Minimum regulator output"]
        V_RMAX = V_RMAX, [description = "Maximum exciter output"]
        V_RMIN = V_RMIN, [description = "Minimum exciter output"]
        K_C = K_C, [description = "Rectifier loading factor proportional to commutating reactance"]
        K_F = K_F, [description = "Rate feedback gain"]
        T_F = T_F, [description = "Rate feedback time constant (s)"]
        K_LR = K_LR, [description = "Exciter output current limiter gain"]
        I_LR = I_LR, [description = "Exciter output current limit reference"]
        IFD0, [guess = 1.0]   # fixed = false, from the initial equations below
        VA0, [guess = 1.0]
    end
    systems = @named begin
        imDerivativeLag = Derivative(; y_start = 0, k = n.K_F, T = n.T_F, initType = :InitialOutput, x_start = Efd0)
        imLimited = Limiter(; uMin = n.V_IMIN, uMax = n.V_IMAX)
        hV_GATE = HV_GATE()
        imGain = Gain(; k = n.K_LR)
        hV_GATE1 = HV_GATE()
        lV_GATE = LV_GATE()
        Vref1 = Constant(; k = n.I_LR)
        imLeadLag = LeadLag(; K = 1, T1 = n.T_C, T2 = n.T_B, y_start = VA0 / n.K_A, x_start = V_REF - ECOMP0)
        imLeadLag1 = LeadLag(; K = 1, y_start = VA0 / n.K_A, T1 = n.T_C1, T2 = n.T_B1, x_start = VA0 / n.K_A)
        add3_1 = Add3(; k1 = -1)
        simpleLagLim = SimpleLagLim(; K = n.K_A, T = n.T_A, y_start = VA0, outMax = n.V_AMAX, outMin = n.V_AMIN)
        add2 = Add(; k1 = -1)
        imLimited1 = Limiter(; uMax = Modelica.Constants.inf, uMin = 0)
        add3_2 = Add3(; k3 = -1)
        imGain1 = Gain(; k = n.V_RMIN)
        imGain2 = Gain(; k = n.V_RMAX)
        add3 = Add(; k1 = -1)
        imGain3 = Gain(; k = n.K_C)
        variableLimiter = VariableLimiter()
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        Limiters = Add()
    end
    vars = @variables begin
        VOTHSG2(t), [description = "VOS=2"]
        VUEL3(t), [description = "UEL=3"]
        VUEL2(t), [description = "UEL=2"]
        VT(t), [description = "sensed VT"]
    end
    eqs = Equation[
        add3_1.y ~ imLimited.u,              # connect(add3_1.y, imLimited.u)
        imLeadLag.y ~ imLeadLag1.u,          # connect(imLeadLag.y, imLeadLag1.u)
        simpleLagLim.u ~ imLeadLag1.y,       # connect(simpleLagLim.u, imLeadLag1.y)
        Vref1.y ~ add2.u1,                   # connect(Vref1.y, add2.u1)
        imGain1.y ~ variableLimiter.limit2,  # connect(imGain1.y, variableLimiter.limit2)
        add3_1.u1 ~ imDerivativeLag.y,       # connect(add3_1.u1, imDerivativeLag.y)
        VUEL2 ~ hV_GATE.u2,                  # connect(VUEL2, hV_GATE.u2)
        variableLimiter.y ~ EFD,             # connect(variableLimiter.y, EFD)
        imGain3.y ~ add3.u1,                 # connect(imGain3.y, add3.u1)
        imGain2.y ~ add3.u2,                 # connect(imGain2.y, add3.u2)
        VT ~ imGain2.u,                      # connect(VT, imGain2.u)
        VOEL ~ lV_GATE.u2,                   # connect(VOEL, lV_GATE.u2)
        imGain1.u ~ imGain2.u,               # connect(imGain1.u, imGain2.u)
        ECOMP ~ TransducerDelay.u,           # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,        # connect(TransducerDelay.y, DiffV.u2)
        DiffV.y ~ add3_1.u2,                 # connect(DiffV.y, add3_1.u2)
        VUEL ~ Limiters.u2,                  # connect(VUEL, Limiters.u2)
        VOTHSG ~ Limiters.u1,                # connect(VOTHSG, Limiters.u1)
        Limiters.y ~ add3_1.u3,              # connect(Limiters.y, add3_1.u3)
        imLimited.y ~ hV_GATE.u1,            # connect(imLimited.y, hV_GATE.u1)
        VOTHSG2 ~ add3_2.u1,                 # connect(VOTHSG2, add3_2.u1)
        lV_GATE.y ~ variableLimiter.u,       # connect(lV_GATE.y, variableLimiter.u)
        hV_GATE1.y ~ lV_GATE.u1,             # connect(hV_GATE1.y, lV_GATE.u1)
        imGain.u ~ add2.y,                   # connect(imGain.u, add2.y)
        imLimited1.u ~ imGain.y,             # connect(imLimited1.u, imGain.y)
        imLimited1.y ~ add3_2.u3,            # connect(imLimited1.y, add3_2.u3)
        add3.y ~ variableLimiter.limit1,     # connect(add3.y, variableLimiter.limit1)
        simpleLagLim.y ~ add3_2.u2,          # connect(simpleLagLim.y, add3_2.u2)
        hV_GATE.y ~ imLeadLag.u,             # connect(hV_GATE.y, imLeadLag.u)
        VUEL3 ~ hV_GATE1.u2,                 # connect(VUEL3, hV_GATE1.u2)
        XADIFD ~ add2.u2,                    # connect(XADIFD, add2.u2)
        XADIFD ~ imGain3.u,                  # connect(XADIFD, imGain3.u)
        add3_2.y ~ hV_GATE1.u1,              # connect(add3_2.y, hV_GATE1.u1)
        imDerivativeLag.u ~ add3_2.y,        # connect(imDerivativeLag.u, add3_2.y)
    ]
    extend(System(eqs, t, vars, pars; name, systems, initial_conditions = Dict(IFD0 => missing, VA0 => missing),
            initialization_eqs = [IFD0 ~ XADIFD, VA0 ~ ifelse(IFD0 < I_LR, Efd0, Efd0 + K_LR * (IFD0 - I_LR)),
                V_REF ~ VA0 / K_A + ECOMP0]), base)
end
