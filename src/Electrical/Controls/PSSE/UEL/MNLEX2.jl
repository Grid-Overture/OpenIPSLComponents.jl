# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/UEL/MNLEX2.mo (extends nothing)
# Blocks: add = Add(k1 = -1), product1..4 = Product, gain = Gain(Q_0), product2, add3_1 = Add3(k1 = -1), gain1 =
# Gain(Radius), feedback = Feedback, simpleLagLim = SimpleLagLim(K_M, T_M, y_start = 0, MEL_MAX, 0), derivativeLag =
# DerivativeLag(K_F2, T_F2, y_start = 0). Ports are plain variables (QELEC, Eterm, PELEC, VUEL); the causal connects
# are equalities. Omitted: graphical annotations.

@component function MNLEX2(; name, K_F2 = 0.1, T_F2 = 1, K_M = 0.3, T_M = 0.5, MEL_MAX = 0.1, Q_0 = 2.5, Radius = 3)
    K_F2, T_F2, K_M, T_M, MEL_MAX, Q_0, Radius = float.((K_F2, T_F2, K_M, T_M, MEL_MAX, Q_0, Radius))
    n = (; K_F2, T_F2, K_M, T_M, MEL_MAX, Q_0, Radius)
    pars = @parameters begin
        K_F2 = K_F2, [description = "Rate feedback gain"]
        T_F2 = T_F2, [description = "Rate feedback time constant (>0) (s)"]
        K_M = K_M, [description = "MEL gain"]
        T_M = T_M, [description = "MEL time constant (s)"]
        MEL_MAX = MEL_MAX, [description = "Maximum limiter output"]
        Q_0 = Q_0, [description = "Reactive power circle center in PQ plane (pu on machine base)"]
        Radius = Radius, [description = "Reactive power circle radius in PQ plane (pu on machine base)"]
    end
    systems = @named begin
        add = Add(; k1 = -1)
        product1 = Product()
        gain = Gain(; k = n.Q_0)
        product2 = Product()
        add3_1 = Add3(; k1 = -1)
        gain1 = Gain(; k = n.Radius)
        product3 = Product()
        product4 = Product()
        feedback = Feedback()
        simpleLagLim = SimpleLagLim(; K = n.K_M, T = n.T_M, y_start = 0, outMax = n.MEL_MAX, outMin = 0)
        derivativeLag = DerivativeLag(; K = n.K_F2, T = n.T_F2, y_start = 0)
    end
    vars = @variables begin
        QELEC(t)
        Eterm(t)
        PELEC(t)
        VUEL(t)
    end
    eqs = Equation[
        Eterm ~ product1.u1,          # connect(Eterm, product1.u1)
        Eterm ~ product1.u2,          # connect(Eterm, product1.u2)
        QELEC ~ add.u2,               # connect(QELEC, add.u2)
        product1.y ~ gain.u,          # connect(product1.y, gain.u)
        gain.y ~ add.u1,              # connect(gain.y, add.u1)
        add.y ~ product2.u1,          # connect(add.y, product2.u1)
        product2.u2 ~ add.y,          # connect(product2.u2, add.y)
        product2.y ~ add3_1.u2,       # connect(product2.y, add3_1.u2)
        gain1.u ~ product1.y,         # connect(gain1.u, product1.y)
        gain1.y ~ product3.u1,        # connect(gain1.y, product3.u1)
        product3.u2 ~ product3.u1,    # connect(product3.u2, product3.u1)
        product3.y ~ add3_1.u1,       # connect(product3.y, add3_1.u1)
        product4.y ~ add3_1.u3,       # connect(product4.y, add3_1.u3)
        PELEC ~ product4.u1,          # connect(PELEC, product4.u1)
        PELEC ~ product4.u2,          # connect(PELEC, product4.u2)
        add3_1.y ~ feedback.u1,       # connect(add3_1.y, feedback.u1)
        feedback.y ~ simpleLagLim.u,  # connect(feedback.y, simpleLagLim.u)
        simpleLagLim.y ~ VUEL,        # connect(simpleLagLim.y, VUEL)
        derivativeLag.u ~ VUEL,       # connect(derivativeLag.u, VUEL)
        derivativeLag.y ~ feedback.u2, # connect(derivativeLag.y, feedback.u2)
    ]
    System(eqs, t, vars, pars; name, systems)
end
