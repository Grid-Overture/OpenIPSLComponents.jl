# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/IEEEG2.mo (extends TG/BaseClasses/BaseGovernor.mo)
# Blocks: leadLag = LeadLag(K, T1 = T_2, T2 = T_1, y_start = 0), add = Add(k2 = -1), limiter = Limiter(P_MAX, P_MIN),
# leadLag2 = LeadLag(K = 1, T1 = -T_4, T2 = 0.5*T_4, y_start = p0), simpleLag = SimpleLag(K = 1, T = T_3, y_start = 0).
# The causal connects are equalities. `p0(fixed = false)` is set by an `initial algorithm` (`p0 := PMECH0`), a
# sequence of assignments transcribed as equalities in the same order: it reads an input, so it is declared with a
# guess, listed as `missing` in `initial_conditions` and given its equation in `initialization_eqs` (F-33), and it is
# passed symbolically to `leadLag2` (F-38).
# Omitted: graphical annotations.

@component function IEEEG2(; name, K = 20, T_1 = 50, T_2 = 5, T_3 = 1, T_4 = 1.5, P_MAX = 1.043, P_MIN = 0.09)
    K, T_1, T_2, T_3, T_4, P_MAX, P_MIN = float.((K, T_1, T_2, T_3, T_4, P_MAX, P_MIN))
    n = (; K, T_1, T_2, T_3, T_4, P_MAX, P_MIN)   # numeric copies for the sub-blocks (F-22)
    @named base = BaseGovernor()
    @unpack PMECH0, SPEED, PMECH = base
    pars = @parameters begin
        K = K, [description = "Permanent governor gain K=1/R (pu on generator MVA base)"]
        T_1 = T_1, [description = "Compensator time constant (sec)"]
        T_2 = T_2, [description = "Compensator time constant (sec)"]
        T_3 = T_3, [description = "Governor time constant (sec)"]
        T_4 = T_4, [description = "Water starting time (sec)"]
        P_MAX = P_MAX, [description = "Upper power limit (pu on machine MVA rating)"]
        P_MIN = P_MIN, [description = "Lower power limit (pu on machine MVA rating)"]
        p0, [guess = 1.0]
    end
    systems = @named begin
        leadLag = LeadLag(; K = n.K, T1 = n.T_2, T2 = n.T_1, y_start = 0)
        add = Add(; k2 = -1)
        limiter = Limiter(; uMax = n.P_MAX, uMin = n.P_MIN)
        leadLag2 = LeadLag(; K = 1, T1 = -n.T_4, T2 = 0.5 * n.T_4, y_start = p0)
        simpleLag = SimpleLag(; K = 1, T = n.T_3, y_start = 0)
    end
    eqs = Equation[
        PMECH0 ~ add.u1,        # connect(PMECH0, add.u1)
        SPEED ~ leadLag.u,      # connect(SPEED, leadLag.u)
        add.y ~ limiter.u,      # connect(add.y, limiter.u)
        limiter.y ~ leadLag2.u, # connect(limiter.y, leadLag2.u)
        leadLag2.y ~ PMECH,     # connect(leadLag2.y, PMECH)
        leadLag.y ~ simpleLag.u,# connect(leadLag.y, simpleLag.u)
        simpleLag.y ~ add.u2,   # connect(simpleLag.y, add.u2)
    ]
    extend(System(eqs, t, [], pars; name, systems, initial_conditions = Dict(p0 => missing),
        initialization_eqs = [p0 ~ PMECH0]), base)
end
