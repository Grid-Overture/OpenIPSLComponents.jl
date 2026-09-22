# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/ST5B.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: VERR1 = Add, lV_Gate = LV_GATE, hV_Gate = HV_GATE, six LeadLagLim (imLimitedLeadLag, imLimitedLeadLag1..5;
# K = 1, outMax = V_RMAX/K_R, outMin = V_RMIN/K_R, y_start = VR0/K_R, with the T_C/T_B, T_UC/T_UB and T_OC/T_OB
# pairs), K_r = Gain(K_R), limiter = Limiter(V_RMAX, V_RMIN), VERR2 = Add(k1 = -1, k2 = 1), K_c = Gain(K_C),
# simpleLagLimVar = SimpleLagLimVar(K = 1, T_1, y_start = Efd0), high = Gain(V_RMAX), low = Gain(V_RMIN),
# TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0). The causal connects are equalities; the UEL and OEL
# chains end in imLimitedLeadLag3/5, whose outputs the .mo leaves unconnected. `VR0` is `fixed = false` resolved
# from inputs (F-33); `V_REF = VR0/K_R + ECOMP` reads ECOMP itself (sic), kept literal. Omitted: graphical annotations.

@component function ST5B(; name, T_R = 0.025, T_C1 = 0.1, T_B1 = 0.2, T_C2 = 1, T_B2 = 1, K_R = 1, V_RMAX = 10,
        V_RMIN = -10, T_1 = 0.58, K_C = 0.3, T_UC1 = 1, T_UB1 = 1, T_UC2 = 1, T_UB2 = 1, T_OC1 = 1, T_OB1 = 1,
        T_OC2 = 1, T_OB2 = 1)
    T_R, T_C1, T_B1, T_C2, T_B2, K_R, V_RMAX, V_RMIN, T_1, K_C, T_UC1, T_UB1, T_UC2, T_UB2, T_OC1, T_OB1, T_OC2, T_OB2 =
        float.((T_R, T_C1, T_B1, T_C2, T_B2, K_R, V_RMAX, V_RMIN, T_1, K_C, T_UC1, T_UB1, T_UC2, T_UB2, T_OC1, T_OB1, T_OC2, T_OB2))
    n = (; T_R, T_C1, T_B1, T_C2, T_B2, K_R, V_RMAX, V_RMIN, T_1, K_C, T_UC1, T_UB1, T_UC2, T_UB2, T_OC1, T_OB1, T_OC2, T_OB2,
        outMax = V_RMAX / K_R, outMin = V_RMIN / K_R)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        T_C1 = T_C1, [description = "Voltage regulator numerator (lead) time constant (first block) (s)"]
        T_B1 = T_B1, [description = "Voltage regulator denominator (lag) time constant (first block) (s)"]
        T_C2 = T_C2, [description = "Voltage regulator numerator (lead) time constant (second block) (s)"]
        T_B2 = T_B2, [description = "Voltage regulator denominator (lag) time constant (second block) (s)"]
        K_R = K_R, [description = "Voltage regulator gain"]
        V_RMAX = V_RMAX, [description = "Maximum regulator output"]
        V_RMIN = V_RMIN, [description = "Minimum regulator output"]
        T_1 = T_1, [description = "Thyristor bridge firing control equivalent time constant (s)"]
        K_C = K_C, [description = "Rectifier loading factor proportional to commutating reactance"]
        T_UC1 = T_UC1, [description = "UEL regulator numerator (lead) time constant (first block) (s)"]
        T_UB1 = T_UB1, [description = "UEL regulator denominator (lag) time constant (first block) (s)"]
        T_UC2 = T_UC2, [description = "UEL regulator numerator (lead) time constant (second block) (s)"]
        T_UB2 = T_UB2, [description = "UEL regulator denominator (lag) time constant (second block) (s)"]
        T_OC1 = T_OC1, [description = "OEL regulator numerator (lead) time constant (first block) (s)"]
        T_OB1 = T_OB1, [description = "OEL regulator denominator (lag) time constant (first block) (s)"]
        T_OC2 = T_OC2, [description = "OEL regulator numerator (lead) time constant (second block) (s)"]
        T_OB2 = T_OB2, [description = "OEL regulator denominator (lag) time constant (second block) (s)"]
        VR0, [guess = 1.0]   # fixed = false, from the initial equation below
    end
    systems = @named begin
        VERR1 = Add()
        lV_Gate = LV_GATE()
        hV_Gate = HV_GATE()
        imLimitedLeadLag = LeadLagLim(; K = 1, outMax = n.outMax, T1 = n.T_C1, T2 = n.T_B1, outMin = n.outMin, y_start = VR0 / n.K_R)
        imLimitedLeadLag2 = LeadLagLim(; K = 1, outMax = n.outMax, T1 = n.T_C2, T2 = n.T_B2, outMin = n.outMin, y_start = VR0 / n.K_R)
        K_r = Gain(; k = n.K_R)
        limiter = Limiter(; uMax = n.V_RMAX, uMin = n.V_RMIN)
        VERR2 = Add(; k1 = -1, k2 = 1)
        K_c = Gain(; k = n.K_C)
        imLimitedLeadLag1 = LeadLagLim(; K = 1, T1 = n.T_UC1, T2 = n.T_UB1, outMin = n.outMin, y_start = VR0 / n.K_R, outMax = n.outMax)
        imLimitedLeadLag3 = LeadLagLim(; K = 1, outMax = n.outMax, T1 = n.T_UC1, T2 = n.T_UB1, outMin = n.outMin, y_start = VR0 / n.K_R)
        imLimitedLeadLag4 = LeadLagLim(; K = 1, outMax = n.outMax, T1 = n.T_OC1, T2 = n.T_OB1, outMin = n.outMin, y_start = VR0 / n.K_R)
        imLimitedLeadLag5 = LeadLagLim(; K = 1, outMax = n.outMax, T1 = n.T_OC1, T2 = n.T_OB1, outMin = n.outMin, y_start = VR0 / n.K_R)
        simpleLagLimVar = SimpleLagLimVar(; K = 1, T = n.T_1, y_start = Efd0)
        high = Gain(; k = n.V_RMAX)
        low = Gain(; k = n.V_RMIN)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
    end
    eqs = Equation[
        VERR1.y ~ imLimitedLeadLag.u,                # connect(VERR1.y, imLimitedLeadLag.u)
        imLimitedLeadLag.y ~ imLimitedLeadLag2.u,    # connect(imLimitedLeadLag.y, imLimitedLeadLag2.u)
        imLimitedLeadLag1.u ~ imLimitedLeadLag.u,    # connect(imLimitedLeadLag1.u, imLimitedLeadLag.u)
        imLimitedLeadLag1.y ~ imLimitedLeadLag3.u,   # connect(imLimitedLeadLag1.y, imLimitedLeadLag3.u)
        imLimitedLeadLag4.u ~ imLimitedLeadLag.u,    # connect(imLimitedLeadLag4.u, imLimitedLeadLag.u)
        VERR2.y ~ simpleLagLimVar.u,                 # connect(VERR2.y, simpleLagLimVar.u)
        low.y ~ simpleLagLimVar.outMin,              # connect(low.y, simpleLagLimVar.outMin)
        high.y ~ simpleLagLimVar.outMax,             # connect(high.y, simpleLagLimVar.outMax)
        K_c.y ~ VERR2.u1,                            # connect(K_c.y, VERR2.u1)
        imLimitedLeadLag4.y ~ imLimitedLeadLag5.u,   # connect(imLimitedLeadLag4.y, imLimitedLeadLag5.u)
        imLimitedLeadLag2.y ~ K_r.u,                 # connect(imLimitedLeadLag2.y, K_r.u)
        lV_Gate.y ~ VERR1.u2,                        # connect(lV_Gate.y, VERR1.u2)
        K_r.y ~ limiter.u,                           # connect(K_r.y, limiter.u)
        limiter.y ~ VERR2.u2,                        # connect(limiter.y, VERR2.u2)
        simpleLagLimVar.y ~ EFD,                     # connect(simpleLagLimVar.y, EFD)
        ECOMP ~ TransducerDelay.u,                   # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,                # connect(TransducerDelay.y, DiffV.u2)
        high.u ~ TransducerDelay.u,                  # connect(high.u, TransducerDelay.u)
        low.u ~ TransducerDelay.u,                   # connect(low.u, TransducerDelay.u)
        VOTHSG ~ VERR1.u1,                           # connect(VOTHSG, VERR1.u1)
        XADIFD ~ K_c.u,                              # connect(XADIFD, K_c.u)
        hV_Gate.y ~ lV_Gate.u1,                      # connect(hV_Gate.y, lV_Gate.u1)
        lV_Gate.u2 ~ VOEL,                           # connect(lV_Gate.u2, VOEL)
        hV_Gate.u2 ~ VUEL,                           # connect(hV_Gate.u2, VUEL)
        DiffV.y ~ hV_Gate.u1,                        # connect(DiffV.y, hV_Gate.u1)
    ]
    extend(System(eqs, t, [], pars; name, systems, initial_conditions = Dict(VR0 => missing),
            initialization_eqs = [VR0 ~ Efd0 + K_C * XADIFD, V_REF ~ VR0 / K_R + ECOMP]), base)
end
