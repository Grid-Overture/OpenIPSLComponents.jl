# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/EXST1.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: imLeadLag = LeadLag(K = 1, T_C, T_B, y_start = x_start = Efd0/K_A), limiter = Limiter(V_IMAX, V_IMIN),
# Vm1 = SimpleLag(y_start = Efd0, K = 1, T_A), K_a = Gain(K_A), imDerivativeLag = Derivative(K_F, T_F, y_start = 0,
# InitialOutput), TransducerDelay = SimpleLag(K = 1, T_R, y_start = ECOMP0), add3_2 = Add3, Limiters = Add,
# feedback = Feedback; the protected RealOutput EFD1 is a plain variable. The causal connects are equalities; Efd0 and
# ECOMP0 are passed symbolically as start values (F-33, F-38). `initial equation V_REF = Efd0/K_A + ECOMP0`.
# The .mo's `if EFD > ECOMP*V_RMAX - K_C*XADIFD then EFD = ECOMP*V_RMAX - K_C*XADIFD elseif EFD < ECOMP*V_RMIN -
# K_C*XADIFD then EFD = ... else EFD = EFD1` is self-referential and has no root when EFD1 leaves the band; it is
# written as the limiter it means, EFD = min(max(EFD1, lo), hi), which is what OpenModelica's trajectory shows on
# every saturated row of the Test (PLAN-04, decision "EXST1"). Omitted: graphical annotations.

@component function EXST1(; name, T_R = 0.02, V_IMAX = 0.2, V_IMIN = 0, T_C = 1, T_B = 1, K_A = 80, T_A = 0.05,
        V_RMAX = 8, V_RMIN = -3, K_C = 0.2, K_F = 0.1, T_F = 1)
    T_R, V_IMAX, V_IMIN, T_C, T_B, K_A, T_A, V_RMAX, V_RMIN, K_C, K_F, T_F =
        float.((T_R, V_IMAX, V_IMIN, T_C, T_B, K_A, T_A, V_RMAX, V_RMIN, K_C, K_F, T_F))
    n = (; T_R, V_IMAX, V_IMIN, T_C, T_B, K_A, T_A, K_F, T_F)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP, XADIFD = base
    pars = @parameters begin
        T_R = T_R, [description = "Regulator input filter time constant (s)"]
        V_IMAX = V_IMAX, [description = "Maximum voltage error (regulator input)"]
        V_IMIN = V_IMIN, [description = "Minimum voltage error (regulator input)"]
        T_C = T_C, [description = "Regulator numerator (lead) time constant (s)"]
        T_B = T_B, [description = "Regulator denominator (lag) time constant (s)"]
        K_A = K_A, [description = "Voltage regulator gain"]
        T_A = T_A, [description = "Voltage regulator time constant (s)"]
        V_RMAX = V_RMAX, [description = "Maximum exciter output"]
        V_RMIN = V_RMIN, [description = "Minimum exciter output"]
        K_C = K_C, [description = "Rectifier loading factor proportional to commutating reactance"]
        K_F = K_F, [description = "Rate feedback gain"]
        T_F = T_F, [description = "Rate feedback time constant (s)"]
    end
    systems = @named begin
        imLeadLag = LeadLag(; K = 1, T1 = n.T_C, T2 = n.T_B, y_start = Efd0 / n.K_A, x_start = Efd0 / n.K_A)
        limiter = Limiter(; uMax = n.V_IMAX, uMin = n.V_IMIN)
        Vm1 = SimpleLag(; y_start = Efd0, K = 1, T = n.T_A)
        K_a = Gain(; k = n.K_A)
        imDerivativeLag = Derivative(; k = n.K_F, T = n.T_F, y_start = 0, initType = :InitialOutput)
        TransducerDelay = SimpleLag(; K = 1, T = n.T_R, y_start = ECOMP0)
        add3_2 = Add3()
        Limiters = Add()
        feedback = Feedback()
    end
    vars = @variables begin
        EFD1(t)
    end
    eqs = Equation[
        EFD ~ min(max(EFD1, ECOMP * V_RMIN - K_C * XADIFD), ECOMP * V_RMAX - K_C * XADIFD),
        imLeadLag.y ~ K_a.u,                 # connect(imLeadLag.y, K_a.u)
        imLeadLag.u ~ limiter.y,             # connect(imLeadLag.u, limiter.y)
        K_a.y ~ Vm1.u,                       # connect(K_a.y, Vm1.u)
        Vm1.y ~ EFD1,                        # connect(Vm1.y, EFD1)
        imDerivativeLag.u ~ EFD1,            # connect(imDerivativeLag.u, EFD1)
        ECOMP ~ TransducerDelay.u,           # connect(ECOMP, TransducerDelay.u)
        TransducerDelay.y ~ DiffV.u2,        # connect(TransducerDelay.y, DiffV.u2)
        VOTHSG ~ add3_2.u1,                  # connect(VOTHSG, add3_2.u1)
        DiffV.y ~ add3_2.u2,                 # connect(DiffV.y, add3_2.u2)
        VUEL ~ Limiters.u1,                  # connect(VUEL, Limiters.u1)
        Limiters.u2 ~ VOEL,                  # connect(Limiters.u2, VOEL)
        Limiters.y ~ add3_2.u3,              # connect(Limiters.y, add3_2.u3)
        feedback.y ~ limiter.u,              # connect(feedback.y, limiter.u)
        feedback.u1 ~ add3_2.y,              # connect(feedback.u1, add3_2.y)
        feedback.u2 ~ imDerivativeLag.y,     # connect(feedback.u2, imDerivativeLag.y)
    ]
    extend(System(eqs, t, vars, pars; name, systems, initialization_eqs = [V_REF ~ Efd0 / K_A + ECOMP0]), base)
end
