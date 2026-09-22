# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/PSS/PSS2A.mo (extends PSS/BaseClasses/BasePSS.mo)
# Blocks: Leadlag1/Leadlag2 = LeadLag(1, T_1/T_3, T_2/T_4, y_start = x_start = 0), SimpleLag1 = SimpleLag(1, T_6, 0),
# SimpleLag2 = SimpleLag(K_S2, T_7, 0), add = Add(k2 = +K_S3), add1 = Add(k2 = -1), gain = Gain(K_S1),
# limiter = Limiter(V_STMAX, V_STMIN), rampTrackingFilter = RampTrackingFilter(M, N, T_8, T_9),
# derivativeLag..derivativeLag3 = DerivativeLag(K = T = T_w1..T_w4, y_start = 0). The causal connects are equalities.
# `Tests.Controls.PSSE.PSS.PSS2A` has no OpenModelica oracle (F-48: with its `T_w1 = 0` OpenModelica inverts the
# conditional output equation of `LeadLag` and divides by zero at initialization, with every solver and flag), so the
# model is validated by `test/test_PSS2A.jl` and, against OpenModelica, by `Examples.Tutorial.Example_4.SMIBVarLoad`.
# Omitted: graphical annotations.

@component function PSS2A(; name, T_w1 = 10, T_w2 = 10, T_6 = 1e-9, T_w3 = 10, T_w4 = 1e-9, T_7 = 10, K_S2 = 0.99,
        K_S3 = 1, T_8 = 0.5, T_9 = 0.1, K_S1 = 20, T_1 = 0.15, T_2 = 0.025, T_3 = 0.15, T_4 = 0.025,
        V_STMAX = 0.1, V_STMIN = -0.1, M = 5, N = 1)
    Mn, Nn = M, N   # the Integer values: `@parameters` below rebinds `M` and `N` to symbols (F-22)
    T_w1, T_w2, T_6, T_w3, T_w4, T_7, K_S2, K_S3, T_8, T_9, K_S1, T_1, T_2, T_3, T_4, V_STMAX, V_STMIN =
        float.((T_w1, T_w2, T_6, T_w3, T_w4, T_7, K_S2, K_S3, T_8, T_9, K_S1, T_1, T_2, T_3, T_4, V_STMAX, V_STMIN))
    n = (; T_w1, T_w2, T_6, T_w3, T_w4, T_7, K_S2, K_S3, T_8, T_9, K_S1, T_1, T_2, T_3, T_4, V_STMAX, V_STMIN)
    @named base = BasePSS()
    @unpack V_S1, V_S2, VOTHSG = base
    pars = @parameters begin
        T_w1 = T_w1, [description = "Washout 1 time constant"]
        T_w2 = T_w2, [description = "Washout 2 time constant"]
        T_6 = T_6, [description = "Lag 1 time constant"]
        T_w3 = T_w3, [description = "Washout 3 time constant"]
        T_w4 = T_w4, [description = "Washout 4 time constant"]
        T_7 = T_7, [description = "Lag 2 time constant"]
        K_S2 = K_S2, [description = "Lag 2 gain"]
        K_S3 = K_S3, [description = "gain"]
        T_8 = T_8, [description = "Ramp-tracking filter time constant"]
        T_9 = T_9, [description = "Ramp-tracking filter time constant"]
        K_S1 = K_S1, [description = "PSS gain"]
        T_1 = T_1, [description = "Leadlag1 time constant"]
        T_2 = T_2, [description = "Leadlag1 time constant"]
        T_3 = T_3, [description = "Leadlag2 time constant"]
        T_4 = T_4, [description = "Leadlag2 time constant"]
        V_STMAX = V_STMAX, [description = "PSS output limiation"]
        V_STMIN = V_STMIN, [description = "PSS output limiation"]
        M = M, [description = "Ramp tracking filter coefficient"]
        N = N, [description = "Ramp tracking filter coefficient"]
    end
    systems = @named begin
        Leadlag1 = LeadLag(; K = 1, T1 = n.T_1, T2 = n.T_2, y_start = 0, x_start = 0)
        Leadlag2 = LeadLag(; K = 1, T1 = n.T_3, T2 = n.T_4, y_start = 0, x_start = 0)
        SimpleLag1 = SimpleLag(; K = 1, T = n.T_6, y_start = 0)
        SimpleLag2 = SimpleLag(; K = n.K_S2, T = n.T_7, y_start = 0)
        add = Add(; k2 = +n.K_S3)
        add1 = Add(; k2 = -1)
        gain = Gain(; k = n.K_S1)
        limiter = Limiter(; uMax = n.V_STMAX, uMin = n.V_STMIN)
        rampTrackingFilter = RampTrackingFilter(; M = Mn, N = Nn, T_1 = n.T_8, T_2 = n.T_9)
        derivativeLag = DerivativeLag(; K = n.T_w1, T = n.T_w1, y_start = 0)
        derivativeLag1 = DerivativeLag(; y_start = 0, K = n.T_w2, T = n.T_w2)
        derivativeLag2 = DerivativeLag(; y_start = 0, K = n.T_w3, T = n.T_w3)
        derivativeLag3 = DerivativeLag(; y_start = 0, K = n.T_w4, T = n.T_w4)
    end
    eqs = Equation[
        SimpleLag1.y ~ add.u1,                    # connect(SimpleLag1.y, add.u1)
        SimpleLag2.y ~ add.u2,                    # connect(SimpleLag2.y, add.u2)
        add1.u2 ~ add.u2,                         # connect(add1.u2, add.u2)
        add1.y ~ gain.u,                          # connect(add1.y, gain.u)
        gain.y ~ Leadlag1.u,                      # connect(gain.y, Leadlag1.u)
        Leadlag1.y ~ Leadlag2.u,                  # connect(Leadlag1.y, Leadlag2.u)
        Leadlag2.y ~ limiter.u,                   # connect(Leadlag2.y, limiter.u)
        rampTrackingFilter.y ~ add1.u1,           # connect(rampTrackingFilter.y, add1.u1)
        derivativeLag.y ~ derivativeLag1.u,       # connect(derivativeLag.y, derivativeLag1.u)
        derivativeLag1.y ~ SimpleLag1.u,          # connect(derivativeLag1.y, SimpleLag1.u)
        derivativeLag3.u ~ derivativeLag2.y,      # connect(derivativeLag3.u, derivativeLag2.y)
        derivativeLag3.y ~ SimpleLag2.u,          # connect(derivativeLag3.y, SimpleLag2.u)
        V_S1 ~ derivativeLag.u,                   # connect(V_S1, derivativeLag.u)
        V_S2 ~ derivativeLag2.u,                  # connect(V_S2, derivativeLag2.u)
        limiter.y ~ VOTHSG,                       # connect(limiter.y, VOTHSG)
        add.y ~ rampTrackingFilter.u,             # connect(add.y, rampTrackingFilter.u)
    ]
    extend(System(eqs, t, [], pars; name, systems), base)
end
