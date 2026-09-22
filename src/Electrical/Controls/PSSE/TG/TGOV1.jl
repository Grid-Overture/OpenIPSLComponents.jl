# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/TGOV1.mo (extends TG/BaseClasses/BaseGovernor.mo)
# Blocks: imLeadLag = LeadLag(T1 = T_2, T2 = T_3, K = 1, y_start = P0), imGain9 = Gain(1/R), imGain1 = Gain(D_t),
# add = Add(k2 = -1), add1 = Add(k2 = -1), REF = Constant(k = P_REF), simpleLagLim = SimpleLagLim(K = 1, T = T_1,
# y_start = P0, V_MAX, V_MIN). The causal connects are equalities.
# `P0` and `P_REF` are `parameter (fixed = false)`: `P0 = PMECH0` reads an input, so both are declared with a guess,
# listed as `missing` in `initial_conditions` and given their `initial equation` in order (F-33). They are passed
# symbolically to the two blocks that start from them (F-38).
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function TGOV1(; name, R = 0.04, D_t = 0, T_1 = 0.4, T_2 = 2, T_3 = 6, V_MAX = 0.86, V_MIN = 0.3)
    R, D_t, T_1, T_2, T_3, V_MAX, V_MIN = float.((R, D_t, T_1, T_2, T_3, V_MAX, V_MIN))
    n = (; R, D_t, T_1, T_2, T_3, V_MAX, V_MIN)   # numeric copies for the sub-blocks (F-22)
    @named base = BaseGovernor()
    @unpack SPEED, PMECH0, PMECH = base
    pars = @parameters begin
        R = R, [description = "Inverse of governor gain (the actual gain is 1/R)"]
        D_t = D_t, [description = "Turbine damping factor (on Machine Base)"]
        T_1 = T_1, [description = "Regulator time constant. It must be greater than 0"]
        T_2 = T_2, [description = "High-pressure reheater time constant"]
        T_3 = T_3, [description = "Reheater time constant. It must be greater than 0"]
        V_MAX = V_MAX, [description = "Maximum valve position (on Machine Base)"]
        V_MIN = V_MIN, [description = "Minimum valve position (on Machine Base)"]
        P0, [guess = 1.0, description = "Power reference of the governor"]
        P_REF, [guess = 1.0]
    end
    systems = @named begin
        imLeadLag = LeadLag(; T1 = n.T_2, T2 = n.T_3, K = 1, y_start = P0)
        imGain9 = Gain(; k = 1 / n.R)
        imGain1 = Gain(; k = n.D_t)
        add = Add(; k2 = -1)
        add1 = Add(; k2 = -1)
        REF = Constant(; k = P_REF)
        simpleLagLim = SimpleLagLim(; K = 1, T = n.T_1, y_start = P0, outMax = n.V_MAX, outMin = n.V_MIN)
    end
    eqs = Equation[
        REF.y ~ add.u1,                # connect(REF.y, add.u1)
        simpleLagLim.u ~ imGain9.y,    # connect(simpleLagLim.u, imGain9.y)
        add1.y ~ PMECH,                # connect(add1.y, PMECH)
        simpleLagLim.y ~ imLeadLag.u,  # connect(simpleLagLim.y, imLeadLag.u)
        add.y ~ imGain9.u,             # connect(add.y, imGain9.u)
        imLeadLag.y ~ add1.u1,         # connect(imLeadLag.y, add1.u1)
        imGain1.y ~ add1.u2,           # connect(imGain1.y, add1.u2)
        SPEED ~ add.u2,                # connect(SPEED, add.u2)
        imGain1.u ~ add.u2,            # connect(imGain1.u, add.u2)
    ]
    extend(System(eqs, t, [], pars; name, systems, initial_conditions = Dict(P0 => missing, P_REF => missing),
        initialization_eqs = [P0 ~ PMECH0, P_REF ~ P0 * R]), base)
end
