# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/URST5T.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: VERR1 = Add, lV_Gate = LV_GATE, hV_Gate = HV_GATE, LL1, LL2 = LeadLagLim(K = 1, outMax = V_RMAX/KR,
# outMin = V_RMIN/KR, T_C/T_B pairs, y_start = VR0/KR), K_R = Gain(KR), limiter = Limiter(V_RMAX, V_RMIN),
# VERR2 = Add(k1 = -1, k2 = 1), K_c = Gain(K_C), Vmin = Gain(V_RMIN), Vmax = Gain(V_RMAX), simpleLagLimVar =
# SimpleLagLimVar(K = 1, T_1, y_start = VR0), TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0); the port VT
# is a plain variable. The causal connects are equalities. `VR0` is `fixed = false` resolved from inputs (F-33);
# `V_REF = VR0/KR + ECOMP` reads ECOMP itself (sic, as ST5B). Omitted: graphical annotations.

@component function URST5T(; name, T_R = 0.025, T_C1 = 0.1, T_B1 = 0.2, T_C2 = 1, T_B2 = 1, KR = 1, V_RMAX = 10,
        V_RMIN = -10, T_1 = 0.58, K_C = 0.3)
    T_R, T_C1, T_B1, T_C2, T_B2, KR, V_RMAX, V_RMIN, T_1, K_C = float.((T_R, T_C1, T_B1, T_C2, T_B2, KR, V_RMAX, V_RMIN, T_1, K_C))
    n = (; T_R, T_C1, T_B1, T_C2, T_B2, KR, V_RMAX, V_RMIN, T_1, K_C, outMax = V_RMAX / KR, outMin = V_RMIN / KR)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        T_C1 = T_C1, [description = "Voltage regulator numerator (lead) time constant (first block) (s)"]
        T_B1 = T_B1, [description = "Voltage regulator denominator (lag) time constant (first block) (s)"]
        T_C2 = T_C2, [description = "Voltage regulator numerator (lead) time constant (second block) (s)"]
        T_B2 = T_B2, [description = "Voltage regulator denominator (lag) time constant (second block) (s)"]
        KR = KR, [description = "Voltage regulator gain"]
        V_RMAX = V_RMAX, [description = "Maximum regulator output"]
        V_RMIN = V_RMIN, [description = "Minimum regulator output"]
        T_1 = T_1, [description = "Thyristor bridge firing control equivalent time constant (s)"]
        K_C = K_C, [description = "Rectifier loading factor proportional to commutating reactance"]
        VR0, [guess = 1.0]   # fixed = false, from the initial equation below
    end
    systems = @named begin
        VERR1 = Add()
        lV_Gate = LV_GATE()
        hV_Gate = HV_GATE()
        LL1 = LeadLagLim(; K = 1, outMax = n.outMax, outMin = n.outMin, T1 = n.T_C1, T2 = n.T_B1, y_start = VR0 / n.KR)
        LL2 = LeadLagLim(; K = 1, outMax = n.outMax, outMin = n.outMin, T1 = n.T_C2, T2 = n.T_B2, y_start = VR0 / n.KR)
        K_R = Gain(; k = n.KR)
        limiter = Limiter(; uMax = n.V_RMAX, uMin = n.V_RMIN)
        VERR2 = Add(; k1 = -1, k2 = 1)
        K_c = Gain(; k = n.K_C)
        Vmin = Gain(; k = n.V_RMIN)
        Vmax = Gain(; k = n.V_RMAX)
        simpleLagLimVar = SimpleLagLimVar(; K = 1, T = n.T_1, y_start = VR0)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
    end
    vars = @variables begin
        VT(t)
    end
    eqs = Equation[
        LL1.u ~ VERR1.y,                       # connect(LL1.u, VERR1.y)
        LL1.y ~ LL2.u,                         # connect(LL1.y, LL2.u)
        ECOMP ~ TransducerDelay.u,             # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,          # connect(TransducerDelay.y, DiffV.u2)
        VOEL ~ lV_Gate.u2,                     # connect(VOEL, lV_Gate.u2)
        hV_Gate.y ~ lV_Gate.u1,                # connect(hV_Gate.y, lV_Gate.u1)
        LL2.y ~ K_R.u,                         # connect(LL2.y, K_R.u)
        K_R.y ~ limiter.u,                     # connect(K_R.y, limiter.u)
        limiter.y ~ simpleLagLimVar.u,         # connect(limiter.y, simpleLagLimVar.u)
        VERR2.y ~ EFD,                         # connect(VERR2.y, EFD)
        K_c.y ~ VERR2.u1,                      # connect(K_c.y, VERR2.u1)
        simpleLagLimVar.y ~ VERR2.u2,          # connect(simpleLagLimVar.y, VERR2.u2)
        VT ~ Vmax.u,                           # connect(VT, Vmax.u)
        Vmin.u ~ Vmax.u,                       # connect(Vmin.u, Vmax.u)
        Vmin.y ~ simpleLagLimVar.outMin,       # connect(Vmin.y, simpleLagLimVar.outMin)
        Vmax.y ~ simpleLagLimVar.outMax,       # connect(Vmax.y, simpleLagLimVar.outMax)
        K_c.u ~ XADIFD,                        # connect(K_c.u, XADIFD)
        VUEL ~ hV_Gate.u2,                     # connect(VUEL, hV_Gate.u2)
        DiffV.y ~ hV_Gate.u1,                  # connect(DiffV.y, hV_Gate.u1)
        lV_Gate.y ~ VERR1.u2,                  # connect(lV_Gate.y, VERR1.u2)
        VERR1.u1 ~ VOTHSG,                     # connect(VERR1.u1, VOTHSG)
    ]
    extend(System(eqs, t, vars, pars; name, systems, initial_conditions = Dict(VR0 => missing),
            initialization_eqs = [VR0 ~ Efd0 + K_C * XADIFD, V_REF ~ VR0 / KR + ECOMP]), base)
end
