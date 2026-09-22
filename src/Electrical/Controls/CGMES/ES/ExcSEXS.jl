# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/CGMES/ES/ExcSEXS.mo (extends PSSE/ES/BaseClasses/BaseExciter.mo)
# Blocks: V_erro = Add3(k1 = k2 = k3 = 1), simpleLagLim = SimpleLagLim(K, T_E, y_start = Efd0, E_MAX, E_MIN),
# DiffV1 = Add, leadLag = LeadLag(K = 1, T1 = T_AT_B*T_B, T2 = T_B, y_start = x_start = 0), limiter = Limiter(EFD_MAX,
# EFD_MIN), transferFunction = TransferFunction(InitialOutput, y_start = Efd0/K, b = {K_C*T_C, K_C}, a = {T_C, 0}).
# The causal connects are equalities; the base's `Efd0` is passed symbolically as a start value (F-33, F-38), the
# coefficient vectors are numbers (F-22). `initial equation V_REF = ECOMP0`. Omitted: graphical annotations.

@component function ExcSEXS(; name, T_AT_B = 0.1, T_B = 10, K = 100, T_E = 0.05, K_C = 0.08, T_C = 0, E_MIN = -5,
        E_MAX = 5, EFD_MAX = 5, EFD_MIN = -5)
    T_AT_B, T_B, K, T_E, K_C, T_C, E_MIN, E_MAX, EFD_MAX, EFD_MIN =
        float.((T_AT_B, T_B, K, T_E, K_C, T_C, E_MIN, E_MAX, EFD_MAX, EFD_MIN))
    n = (; K, T_E, E_MIN, E_MAX, EFD_MAX, EFD_MIN, T1 = T_AT_B * T_B, T2 = T_B, tf_b = [K_C * T_C, K_C], tf_a = [T_C, 0.0])
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP = base
    pars = @parameters begin
        T_AT_B = T_AT_B, [description = "Ta/Tb - gain reduction ratio of lag-lead element"]
        T_B = T_B, [description = "Denominator time constant of lag-lead block (s)"]
        K = K, [description = "Gain (K) (>0)"]
        T_E = T_E, [description = "Time constant of gain block (s)"]
        K_C = K_C, [description = "PI controller gain"]
        T_C = T_C, [description = "PI controller phase lead time constant (s)"]
        E_MIN = E_MIN, [description = "Minimum field voltage output"]
        E_MAX = E_MAX, [description = "Maximum field voltage output"]
        EFD_MAX = EFD_MAX, [description = "Field voltage clipping maximum limit"]
        EFD_MIN = EFD_MIN, [description = "Field voltage clipping minimum limit"]
    end
    systems = @named begin
        V_erro = Add3(; k3 = 1, k1 = 1, k2 = 1)
        simpleLagLim = SimpleLagLim(; K = n.K, T = n.T_E, y_start = Efd0, outMax = n.E_MAX, outMin = n.E_MIN)
        DiffV1 = Add()
        leadLag = LeadLag(; K = 1, T1 = n.T1, T2 = n.T2, y_start = 0, x_start = 0)
        limiter = Limiter(; uMax = n.EFD_MAX, uMin = n.EFD_MIN)
        transferFunction = TransferFunction(; initType = :InitialOutput, y_start = Efd0 / n.K, b = n.tf_b, a = n.tf_a)
    end
    eqs = Equation[
        DiffV1.u1 ~ VUEL,                    # connect(DiffV1.u1, VUEL)
        DiffV1.u2 ~ VOEL,                    # connect(DiffV1.u2, VOEL)
        DiffV1.y ~ V_erro.u3,                # connect(DiffV1.y, V_erro.u3)
        DiffV.y ~ V_erro.u2,                 # connect(DiffV.y, V_erro.u2)
        V_erro.u1 ~ VOTHSG,                  # connect(V_erro.u1, VOTHSG)
        ECOMP ~ DiffV.u2,                    # connect(ECOMP, DiffV.u2)
        leadLag.u ~ V_erro.y,                # connect(leadLag.u, V_erro.y)
        simpleLagLim.y ~ limiter.u,          # connect(simpleLagLim.y, limiter.u)
        limiter.y ~ EFD,                     # connect(limiter.y, EFD)
        leadLag.y ~ transferFunction.u,      # connect(leadLag.y, transferFunction.u)
        transferFunction.y ~ simpleLagLim.u, # connect(transferFunction.y, simpleLagLim.u)
    ]
    extend(System(eqs, t, [], pars; name, systems, initialization_eqs = [V_REF ~ ECOMP0]), base)
end
