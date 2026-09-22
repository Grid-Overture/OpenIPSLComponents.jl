# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/PSS/PSS2B.mo (extends PSS/BaseClasses/BasePSS.mo)
# PSS2A plus the third lead-lag (`Leadlag3`, T_10/T_11) and the two input limiters (`limiter1`, `limiter2`).
# Blocks: Leadlag1/2/3 = LeadLag(1, T_1/T_3/T_10, T_2/T_4/T_11, y_start = 0), SimpleLag1 = SimpleLag(1, T_6, 0),
# SimpleLag2 = SimpleLag(K_S2, T_7, 0), limiter/limiter1/limiter2 = Limiter(V_STMAX/V_S1MAX/V_S2MAX, ...),
# add = Add(k2 = +K_S3), add1 = Add(k2 = -1), gain = Gain(K_S1), derivativeLag..3 = DerivativeLag(K = T = T_w1..T_w4,
# y_start = 0; the first and the third also take x_start = V_S10/V_S20), rampTrackingFilter = RampTrackingFilter.
# `V_S10 = V_S1` and `V_S20 = V_S2` read the inputs: `missing` parameters with their equations in
# `initialization_eqs` (F-33), reaching the two washouts symbolically (F-38).
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function PSS2B(; name, T_w1 = 10, T_w2 = 10, T_6 = 1e-9, T_w3 = 10, T_w4 = 1e-9, T_7 = 10, K_S2 = 0.99,
        K_S3 = 1, T_8 = 0.5, T_9 = 0.1, K_S1 = 20, T_1 = 0.15, T_2 = 0.025, T_3 = 0.15, T_4 = 0.025, T_10 = 1e-9,
        T_11 = 0.033, V_S1MAX = 0.08, V_S1MIN = -0.08, V_S2MAX = 1.25, V_S2MIN = -1.25, V_STMAX = 0.1,
        V_STMIN = -0.1, M = 5, N = 1)
    Mn, Nn = M, N   # the Integer values: `@parameters` below rebinds `M` and `N` to symbols (F-22)
    T_w1, T_w2, T_6, T_w3, T_w4, T_7, K_S2, K_S3, T_8, T_9, K_S1, T_1, T_2, T_3, T_4, T_10, T_11, V_S1MAX, V_S1MIN,
    V_S2MAX, V_S2MIN, V_STMAX, V_STMIN = float.((T_w1, T_w2, T_6, T_w3, T_w4, T_7, K_S2, K_S3, T_8, T_9, K_S1, T_1,
        T_2, T_3, T_4, T_10, T_11, V_S1MAX, V_S1MIN, V_S2MAX, V_S2MIN, V_STMAX, V_STMIN))
    n = (; T_w1, T_w2, T_6, T_w3, T_w4, T_7, K_S2, K_S3, T_8, T_9, K_S1, T_1, T_2, T_3, T_4, T_10, T_11, V_S1MAX,
        V_S1MIN, V_S2MAX, V_S2MIN, V_STMAX, V_STMIN)
    @named base = BasePSS()
    @unpack V_S1, V_S2, VOTHSG = base
    pars = @parameters begin
        T_w1 = T_w1, [description = "Washout time constant 1"]
        T_w2 = T_w2, [description = "Washout time constant 2"]
        T_6 = T_6, [description = "Lag time constant 6"]
        T_w3 = T_w3, [description = "Washout time constant 3"]
        T_w4 = T_w4, [description = "Washout time constant 4"]
        T_7 = T_7, [description = "Lag time constant 7"]
        K_S2 = K_S2, [description = "Lag gain 2, T_7/H"]
        K_S3 = K_S3, [description = "Lag gain 3"]
        T_8 = T_8, [description = "Ramp-tracking filter time constant"]
        T_9 = T_9, [description = "Ramp-tracking filter time constant"]
        K_S1 = K_S1, [description = "PSS gain"]
        T_1 = T_1, [description = "Lead-lag time constant 1"]
        T_2 = T_2, [description = "Lead-lag time constant 2"]
        T_3 = T_3, [description = "Lead-lag time constant 3"]
        T_4 = T_4, [description = "Lead-lag time constant 4"]
        T_10 = T_10, [description = "Lead-lag time constant 10"]
        T_11 = T_11, [description = "Lead-lag time constant 11"]
        V_S1MAX = V_S1MAX, [description = "PSS input 1 max. limit"]
        V_S1MIN = V_S1MIN, [description = "PSS input 1 min. limit"]
        V_S2MAX = V_S2MAX, [description = "PSS input 2 max. limit"]
        V_S2MIN = V_S2MIN, [description = "PSS input 2 min. limit"]
        V_STMAX = V_STMAX, [description = "PSS output max. limit"]
        V_STMIN = V_STMIN, [description = "PSS output min. limit"]
        M = M, [description = "Ramp tracking filter coefficient"]
        N = N, [description = "Ramp tracking filter coefficient"]
        V_S10, [guess = 0.0]
        V_S20, [guess = 0.0]
    end
    systems = @named begin
        Leadlag1 = LeadLag(; K = 1, T1 = n.T_1, T2 = n.T_2, y_start = 0)
        Leadlag2 = LeadLag(; K = 1, T1 = n.T_3, T2 = n.T_4, y_start = 0)
        SimpleLag1 = SimpleLag(; K = 1, T = n.T_6, y_start = 0)
        SimpleLag2 = SimpleLag(; K = n.K_S2, T = n.T_7, y_start = 0)
        Leadlag3 = LeadLag(; K = 1, T1 = n.T_10, T2 = n.T_11, y_start = 0)
        limiter = Limiter(; uMax = n.V_STMAX, uMin = n.V_STMIN)
        limiter1 = Limiter(; uMax = n.V_S1MAX, uMin = n.V_S1MIN)
        limiter2 = Limiter(; uMax = n.V_S2MAX, uMin = n.V_S2MIN)
        add = Add(; k2 = +n.K_S3)
        add1 = Add(; k2 = -1)
        gain = Gain(; k = n.K_S1)
        derivativeLag = DerivativeLag(; K = n.T_w1, T = n.T_w1, y_start = 0, x_start = V_S10)
        derivativeLag1 = DerivativeLag(; y_start = 0, K = n.T_w2, T = n.T_w2)
        derivativeLag2 = DerivativeLag(; y_start = 0, K = n.T_w3, T = n.T_w3, x_start = V_S20)
        derivativeLag3 = DerivativeLag(; y_start = 0, K = n.T_w4, T = n.T_w4)
        rampTrackingFilter = RampTrackingFilter(; M = Mn, N = Nn, T_1 = n.T_8, T_2 = n.T_9)
    end
    eqs = Equation[
        Leadlag3.y ~ limiter.u,                   # connect(Leadlag3.y, limiter.u)
        Leadlag2.y ~ Leadlag3.u,                  # connect(Leadlag2.y, Leadlag3.u)
        Leadlag2.u ~ Leadlag1.y,                  # connect(Leadlag2.u, Leadlag1.y)
        SimpleLag1.y ~ add.u1,                    # connect(SimpleLag1.y, add.u1)
        SimpleLag2.y ~ add.u2,                    # connect(SimpleLag2.y, add.u2)
        add1.y ~ gain.u,                          # connect(add1.y, gain.u)
        gain.y ~ Leadlag1.u,                      # connect(gain.y, Leadlag1.u)
        derivativeLag.y ~ derivativeLag1.u,       # connect(derivativeLag.y, derivativeLag1.u)
        derivativeLag3.u ~ derivativeLag2.y,      # connect(derivativeLag3.u, derivativeLag2.y)
        derivativeLag1.y ~ SimpleLag1.u,          # connect(derivativeLag1.y, SimpleLag1.u)
        derivativeLag3.y ~ SimpleLag2.u,          # connect(derivativeLag3.y, SimpleLag2.u)
        derivativeLag2.u ~ limiter2.y,            # connect(derivativeLag2.u, limiter2.y)
        derivativeLag.u ~ limiter1.y,             # connect(derivativeLag.u, limiter1.y)
        add.y ~ rampTrackingFilter.u,             # connect(add.y, rampTrackingFilter.u)
        rampTrackingFilter.y ~ add1.u1,           # connect(rampTrackingFilter.y, add1.u1)
        add1.u2 ~ add.u2,                         # connect(add1.u2, add.u2)
        V_S1 ~ limiter1.u,                        # connect(V_S1, limiter1.u)
        V_S2 ~ limiter2.u,                        # connect(V_S2, limiter2.u)
        limiter.y ~ VOTHSG,                       # connect(limiter.y, VOTHSG)
    ]
    extend(System(eqs, t, [], pars; name, systems, initialization_eqs = [V_S10 ~ V_S1, V_S20 ~ V_S2],
        initial_conditions = Dict(V_S10 => missing, V_S20 => missing)), base)
end
