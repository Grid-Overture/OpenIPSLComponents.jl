# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/IEESGO.mo (extends TG/BaseClasses/BaseGovernor.mo)
# Blocks: imSimpleLag = SimpleLag(K_1, T_1, y_start = 0), imLeadLag = LeadLag(K = 1, T1 = T_2, T2 = T_3, y_start = 0),
# imSimpleLag1 = SimpleLag(1, T_4, y_start = p0), imSimpleLag2 = SimpleLag(K_2, T_5, y_start = p0*K_2),
# imSimpleLag3 = SimpleLag(K_3, T_6, y_start = p0*K_2*K_3), add = Add(k2 = -1), limiter = Limiter(P_MAX, P_MIN),
# gain = Gain(1 - K_2), gain1 = Gain(1 - K_3), add3_1 = Add3. The causal connects are equalities.
# `p0(fixed = false)` comes from the `initial algorithm` `p0 := PMECH0`, an input, so it is a `missing` parameter with
# its equation in `initialization_eqs` (F-33) and reaches the three lags symbolically (F-38).
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function IEESGO(; name, T_1 = 0.2, T_2 = 0, T_3 = 0.5, T_4 = 0.12, T_5 = 5, T_6 = 0.5, K_1 = 20,
        K_2 = 0.59, K_3 = 0.43, P_MAX = 0.98, P_MIN = 0)
    T_1, T_2, T_3, T_4, T_5, T_6, K_1, K_2, K_3, P_MAX, P_MIN =
        float.((T_1, T_2, T_3, T_4, T_5, T_6, K_1, K_2, K_3, P_MAX, P_MIN))
    n = (; T_1, T_2, T_3, T_4, T_5, T_6, K_1, K_2, K_3, P_MAX, P_MIN)   # numeric copies for the sub-blocks (F-22)
    @named base = BaseGovernor()
    @unpack PMECH0, SPEED, PMECH = base
    pars = @parameters begin
        T_1 = T_1, [description = "Controller lag"]
        T_2 = T_2, [description = "Controller lead compensation"]
        T_3 = T_3, [description = "Governor lag"]
        T_4 = T_4, [description = "Delay due to steam inlet volumes associated with steam chest and inlet piping"]
        T_5 = T_5, [description = "Reheater delay including hot and cold leads"]
        T_6 = T_6, [description = "Delay due to IP-LP turbine, crossover pipes, and LP end hoods"]
        K_1 = K_1, [description = "Regulation gain [1/pu]"]
        K_2 = K_2, [description = "Intermediate pressure turbine fraction"]
        K_3 = K_3, [description = "Low pressure turbine fraction"]
        P_MAX = P_MAX, [description = "Upper power limit"]
        P_MIN = P_MIN, [description = "Lower power limit"]
        p0, [guess = 1.0]
    end
    systems = @named begin
        imSimpleLag = SimpleLag(; K = n.K_1, T = n.T_1, y_start = 0)
        imLeadLag = LeadLag(; K = 1, T1 = n.T_2, T2 = n.T_3, y_start = 0)
        imSimpleLag1 = SimpleLag(; K = 1, T = n.T_4, y_start = p0)
        imSimpleLag2 = SimpleLag(; K = n.K_2, T = n.T_5, y_start = p0 * n.K_2)
        imSimpleLag3 = SimpleLag(; K = n.K_3, T = n.T_6, y_start = p0 * n.K_2 * n.K_3)
        add = Add(; k2 = -1)
        limiter = Limiter(; uMax = n.P_MAX, uMin = n.P_MIN)
        gain = Gain(; k = 1 - n.K_2)
        gain1 = Gain(; k = 1 - n.K_3)
        add3_1 = Add3()
    end
    eqs = Equation[
        imSimpleLag.y ~ imLeadLag.u,     # connect(imSimpleLag.y, imLeadLag.u)
        imLeadLag.y ~ add.u2,            # connect(imLeadLag.y, add.u2)
        add.y ~ limiter.u,               # connect(add.y, limiter.u)
        limiter.y ~ imSimpleLag1.u,      # connect(limiter.y, imSimpleLag1.u)
        imSimpleLag2.y ~ imSimpleLag3.u, # connect(imSimpleLag2.y, imSimpleLag3.u)
        gain1.u ~ imSimpleLag3.u,        # connect(gain1.u, imSimpleLag3.u)
        PMECH0 ~ add.u1,                 # connect(PMECH0, add.u1)
        SPEED ~ imSimpleLag.u,           # connect(SPEED, imSimpleLag.u)
        imSimpleLag1.y ~ gain.u,         # connect(imSimpleLag1.y, gain.u)
        imSimpleLag2.u ~ gain.u,         # connect(imSimpleLag2.u, gain.u)
        gain.y ~ add3_1.u1,              # connect(gain.y, add3_1.u1)
        gain1.y ~ add3_1.u2,             # connect(gain1.y, add3_1.u2)
        imSimpleLag3.y ~ add3_1.u3,      # connect(imSimpleLag3.y, add3_1.u3)
        add3_1.y ~ PMECH,                # connect(add3_1.y, PMECH)
    ]
    extend(System(eqs, t, [], pars; name, systems, initial_conditions = Dict(p0 => missing),
        initialization_eqs = [p0 ~ PMECH0]), base)
end
