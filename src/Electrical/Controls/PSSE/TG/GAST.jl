# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/GAST.mo (extends TG/BaseClasses/BaseGovernor.mo)
# Blocks: add = Add(k1 = -1), add1 = Add(k2 = -1), add2 = Add(k2 = +1), add3 = Add(k1 = -1), gDturb = Gain(D_turb),
# gKt = Gain(K_T), g1_R = Gain(1/R), lV_Gate = LV_GATE, transferFunction1 = TransferFunction(a = {T_2, 1},
# InitialOutput, y_start = pm0), transferFunction2 = TransferFunction(a = {T_3, 1}, InitialOutput, y_start = pm0),
# const = Constant(AT) (instance `const_`: `const` is a Julia keyword), simpleLagLim = SimpleLagLim(K = 1, T = T_1,
# y_start = pm0, V_MAX, V_MIN). The causal connects are equalities.
# `pm0(fixed = false)` comes from the `initial algorithm` `pm0 := PMECH0`, an input: a `missing` parameter with its
# equation in `initialization_eqs` (F-33), passed symbolically to the three blocks that start from it (F-38).
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function GAST(; name, R = 0.05, T_1 = 0.4, T_2 = 0.1, T_3 = 3.0, AT = 0.9, K_T = 2.0, V_MAX = 1.0,
        V_MIN = -0.05, D_turb = 0.0)
    R, T_1, T_2, T_3, AT, K_T, V_MAX, V_MIN, D_turb = float.((R, T_1, T_2, T_3, AT, K_T, V_MAX, V_MIN, D_turb))
    n = (; R, T_1, T_2, T_3, AT, K_T, V_MAX, V_MIN, D_turb)   # numeric copies for the sub-blocks (F-22)
    @named base = BaseGovernor()
    @unpack SPEED, PMECH0, PMECH = base
    pars = @parameters begin
        R = R, [description = "Speed droop gain"]
        T_1 = T_1, [description = "Valve response time constant"]
        T_2 = T_2, [description = "Turbine response time constant"]
        T_3 = T_3, [description = "Load limit response time constant"]
        AT = AT, [description = "Ambient temperature load limit"]
        K_T = K_T, [description = "Load-limited feedback path adjustment gain"]
        V_MAX = V_MAX, [description = "Operational control high limit on fuel valve opening"]
        V_MIN = V_MIN, [description = "Low output control limit on fuel valve opening"]
        D_turb = D_turb, [description = "Turbine damping"]
        pm0, [guess = 1.0]
    end
    systems = @named begin
        add = Add(; k1 = -1)
        add1 = Add(; k2 = -1)
        add2 = Add(; k2 = +1)
        add3 = Add(; k1 = -1)
        gDturb = Gain(; k = n.D_turb)
        gKt = Gain(; k = n.K_T)
        g1_R = Gain(; k = 1 / n.R)
        lV_Gate = LV_GATE()
        transferFunction1 = TransferFunction(; a = [n.T_2, 1.0], initType = :InitialOutput, y_start = pm0)
        transferFunction2 = TransferFunction(; a = [n.T_3, 1.0], initType = :InitialOutput, y_start = pm0)
        const_ = Constant(; k = n.AT)
        simpleLagLim = SimpleLagLim(; outMax = n.V_MAX, outMin = n.V_MIN, K = 1, T = n.T_1, y_start = pm0)
    end
    eqs = Equation[
        gDturb.y ~ add3.u1,                        # connect(gDturb.y, add3.u1)
        g1_R.y ~ add.u1,                           # connect(g1_R.y, add.u1)
        add1.y ~ gKt.u,                            # connect(add1.y, gKt.u)
        gKt.y ~ add2.u2,                           # connect(gKt.y, add2.u2)
        transferFunction2.y ~ add1.u2,             # connect(transferFunction2.y, add1.u2)
        transferFunction1.y ~ add3.u2,             # connect(transferFunction1.y, add3.u2)
        transferFunction1.y ~ transferFunction2.u, # connect(transferFunction1.y, transferFunction2.u)
        add.y ~ lV_Gate.u1,                        # connect(add.y, lV_Gate.u1)
        lV_Gate.u2 ~ add2.y,                       # connect(lV_Gate.u2, add2.y)
        const_.y ~ add2.u1,                        # connect(const.y, add2.u1)
        simpleLagLim.u ~ lV_Gate.y,                # connect(simpleLagLim.u, lV_Gate.y)
        simpleLagLim.y ~ transferFunction1.u,      # connect(simpleLagLim.y, transferFunction1.u)
        add3.y ~ PMECH,                            # connect(add3.y, PMECH)
        SPEED ~ g1_R.u,                            # connect(SPEED, g1_R.u)
        gDturb.u ~ g1_R.u,                         # connect(gDturb.u, g1_R.u)
        add.u2 ~ PMECH0,                           # connect(add.u2, PMECH0)
        add1.u1 ~ const_.y,                        # connect(add1.u1, const.y)
    ]
    extend(System(eqs, t, [], pars; name, systems, initial_conditions = Dict(pm0 => missing),
        initialization_eqs = [pm0 ~ PMECH0]), base)
end
