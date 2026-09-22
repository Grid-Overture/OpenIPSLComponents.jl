# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/SEXS.mo (extends ES/BaseClasses/BaseExciter.mo)
# Blocks: V_erro = Add3(k1 = k2 = k3 = 1), simpleLagLim = SimpleLagLim(K, T_E, y_start = Efd0, E_MAX, E_MIN),
# DiffV1 = Add, leadLag = LeadLag(K = 1, T1 = T_AT_B*T_B, T2 = T_B, y_start = x_start = Efd0/K). The causal connects
# are equalities. The base's `Efd0` (a `fixed = false` parameter resolved from the input EFD0, F-33) is passed
# symbolically as the start value of the two blocks; the time constants and limits are numbers (F-22).
# `initial equation V_REF = Efd0/K + ECOMP0` closes the base's third `fixed = false` parameter.
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function SEXS(; name, T_AT_B = 0.1, T_B = 1, K = 100, T_E = 0.1, E_MIN = -10, E_MAX = 10)
    T_AT_B, T_B, K, T_E, E_MIN, E_MAX = float.((T_AT_B, T_B, K, T_E, E_MIN, E_MAX))
    n = (; K, T_E, E_MIN, E_MAX, T1 = T_AT_B * T_B, T2 = T_B)   # numeric copies for the sub-blocks (F-22)
    @named base = BaseExciter()
    @unpack Efd0, V_REF, ECOMP0, DiffV, VUEL, VOEL, EFD, VOTHSG, ECOMP = base
    pars = @parameters begin
        T_AT_B = T_AT_B, [description = "Ratio between regulator numerator (lead) and denominator (lag) time constants"]
        T_B = T_B, [description = "Regulator denominator (lag) time constant (s)"]
        K = K, [description = "Excitation power source output gain"]
        T_E = T_E, [description = "Excitation power source output time constant (s)"]
        E_MIN = E_MIN, [description = "Minimum exciter output"]
        E_MAX = E_MAX, [description = "Maximum exciter output"]
    end
    systems = @named begin
        V_erro = Add3(; k3 = 1, k1 = 1, k2 = 1)
        simpleLagLim = SimpleLagLim(; K = n.K, T = n.T_E, y_start = Efd0, outMax = n.E_MAX, outMin = n.E_MIN)
        DiffV1 = Add()
        leadLag = LeadLag(; K = 1, T1 = n.T1, T2 = n.T2, y_start = Efd0 / n.K, x_start = Efd0 / n.K)
    end
    eqs = Equation[
        simpleLagLim.y ~ EFD,        # connect(simpleLagLim.y, EFD)
        DiffV1.u1 ~ VUEL,            # connect(DiffV1.u1, VUEL)
        DiffV1.u2 ~ VOEL,            # connect(DiffV1.u2, VOEL)
        DiffV1.y ~ V_erro.u3,        # connect(DiffV1.y, V_erro.u3)
        DiffV.y ~ V_erro.u2,         # connect(DiffV.y, V_erro.u2)
        V_erro.u1 ~ VOTHSG,          # connect(V_erro.u1, VOTHSG)
        ECOMP ~ DiffV.u2,            # connect(ECOMP, DiffV.u2)
        leadLag.y ~ simpleLagLim.u,  # connect(leadLag.y, simpleLagLim.u)
        leadLag.u ~ V_erro.y,        # connect(leadLag.u, V_erro.y)
    ]
    extend(System(eqs, t, [], pars; name, systems, initialization_eqs = [V_REF ~ Efd0 / K + ECOMP0]), base)
end
