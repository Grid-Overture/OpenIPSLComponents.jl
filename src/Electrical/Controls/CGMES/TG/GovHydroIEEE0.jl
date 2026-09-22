# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/CGMES/TG/GovHydroIEEE0.mo (a `class`, not a `model`; extends nothing)
# Ports as plain variables: SPEED and Pref (inputs), PMECH (output).
# Blocks: GovernorA = LeadLag(K, T1 = T2, T2 = T1, y_start = 0), difference = Add(k2 = -1),
# GovernorB = TransferFunction(a = {T3, 1}, b = {1}), waterway = TransferFunction(a = {0.5*T4, 1}, b = {-T4, 1},
# y_start = 0), limiter = Limiter(Pmax, Pmin). The causal connects are equalities.
# `GovernorB` and `waterway` keep MSL's default `initType = NoInit` (the `.mo` sets `y_start` on `waterway` but not
# the `initType`, so the start value is inert, as in MSL): their states start at `x_start = 0`.
# Omitted: graphical annotations.

@component function GovHydroIEEE0(; name, K = 5, T1 = 0.25, T2 = 0, T3 = 0.1, T4 = 0.04, Pmax = 1.5, Pmin = 0.5)
    K, T1, T2, T3, T4, Pmax, Pmin = float.((K, T1, T2, T3, T4, Pmax, Pmin))
    n = (; K, T1, T2, T3, T4, Pmax, Pmin)   # numeric copies for the sub-blocks (F-22)
    pars = @parameters begin
        K = K, [description = "Governor gain"]
        T1 = T1, [description = "Governor lag time constant"]
        T2 = T2, [description = "Governor lead time constant"]
        T3 = T3, [description = "Gate actuator time constant"]
        T4 = T4, [description = "Water starting time"]
        Pmax = Pmax, [description = "Gate maximum"]
        Pmin = Pmin, [description = "Gate minimum"]
    end
    systems = @named begin
        GovernorA = LeadLag(; K = n.K, T1 = n.T2, T2 = n.T1, y_start = 0)
        difference = Add(; k2 = -1)
        GovernorB = TransferFunction(; a = [n.T3, 1.0], b = [1.0])
        waterway = TransferFunction(; a = [0.5 * n.T4, 1.0], b = [-n.T4, 1.0], y_start = 0)
        limiter = Limiter(; uMax = n.Pmax, uMin = n.Pmin)
    end
    vars = @variables begin
        SPEED(t)
        Pref(t)
        PMECH(t)
    end
    eqs = Equation[
        waterway.y ~ PMECH,        # connect(waterway.y, PMECH)
        limiter.y ~ waterway.u,    # connect(limiter.y, waterway.u)
        difference.y ~ limiter.u,  # connect(difference.y, limiter.u)
        GovernorB.y ~ difference.u2,  # connect(GovernorB.y, difference.u2)
        GovernorA.y ~ GovernorB.u,    # connect(GovernorA.y, GovernorB.u)
        SPEED ~ GovernorA.u,          # connect(SPEED, GovernorA.u)
        Pref ~ difference.u1,         # connect(Pref, difference.u1)
    ]
    System(eqs, t, vars, pars; name, systems)
end
