# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/IEEEG1.mo (extends nothing: its ports are its own)
# Ports as plain variables: SPEED_HP (input), PMECH_HP and PMECH_LP (outputs). Unlike the other governors of the
# batch it has no PMECH0 input: the parameter `P0` is the initial power and feeds `Pref`, `limIntegrator` and the
# four lags directly, so nothing here is `fixed = false`.
# Blocks: imLeadLag = LeadLag(K, T1 = T_2, T2 = T_1, y_start = 0), imSimpleLag/1/2/3 = SimpleLag(1, T_4/T_5/T_6/T_7,
# y_start = P0), imGain1..imGain8 = Gain(K_1..K_8), Pref = Constant(P0), add3_1 = Add3(k2 = -1, k3 = -1),
# gain = Gain(1/T_3), limiter = Limiter(U_o, U_c), limIntegrator = LimIntegrator(k = 1, P_MAX, P_MIN, InitialOutput,
# y_start = P0), add..add5 = Add. The causal connects are equalities.
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function IEEEG1(; name, P0 = 1, K = 20, T_1 = 1e-8, T_2 = 1e-8, T_3 = 0.1, U_o = 0.1, U_c = -0.1,
        P_MAX = 0.903, P_MIN = 0, T_4 = 0.4, K_1 = 0.3, K_2 = 0, T_5 = 9, K_3 = 0.4, K_4 = 0, T_6 = 0.5, K_5 = 0.3,
        K_6 = 0, T_7 = 1e-8, K_7 = 0, K_8 = 0)
    P0, K, T_1, T_2, T_3, U_o, U_c, P_MAX, P_MIN, T_4, K_1, K_2, T_5, K_3, K_4, T_6, K_5, K_6, T_7, K_7, K_8 =
        float.((P0, K, T_1, T_2, T_3, U_o, U_c, P_MAX, P_MIN, T_4, K_1, K_2, T_5, K_3, K_4, T_6, K_5, K_6, T_7, K_7,
            K_8))
    n = (; P0, K, T_1, T_2, T_3, U_o, U_c, P_MAX, P_MIN, T_4, K_1, K_2, T_5, K_3, K_4, T_6, K_5, K_6, T_7, K_7, K_8)
    pars = @parameters begin
        P0 = P0, [description = "Power reference of the governor"]
        K = K, [description = "Regulation gain [1/pu]"]
        T_1 = T_1, [description = "Control time constant"]
        T_2 = T_2, [description = "Control time constant"]
        T_3 = T_3, [description = "Control time constant"]
        U_o = U_o, [description = "Max. rate if valve opening"]
        U_c = U_c, [description = "Max. rate if valve closing"]
        P_MAX = P_MAX, [description = "Max. valve position"]
        P_MIN = P_MIN, [description = "Min. valve position"]
        T_4 = T_4, [description = "HP section time constant"]
        K_1 = K_1, [description = "Fraction of power from high pressure turbine (upper branch)"]
        K_2 = K_2, [description = "Fraction of power from high pressure turbine (lower branch)"]
        T_5 = T_5, [description = "Reheat plus intermediate pressure turbine time constant"]
        K_3 = K_3, [description = "Fraction of power from intermediate pressure turbine (upper branch)"]
        K_4 = K_4, [description = "Fraction of power from intermediate pressure turbine (lower branch)"]
        T_6 = T_6, [description = "Reheater plus intermediate pressure turbine time constant (second)"]
        K_5 = K_5, [description = "Fraction of power from low pressure turbine (first LP, upper branch)"]
        K_6 = K_6, [description = "Fraction of power from low pressure turbine (first LP, lower branch)"]
        T_7 = T_7, [description = "Low pressure turbine time constant"]
        K_7 = K_7, [description = "Fraction of power from low pressure turbine (second LP, upper branch)"]
        K_8 = K_8, [description = "Fraction of power from low pressure turbine (second LP, lower branch)"]
    end
    systems = @named begin
        imLeadLag = LeadLag(; K = n.K, T1 = n.T_2, T2 = n.T_1, y_start = 0)
        imSimpleLag = SimpleLag(; K = 1, T = n.T_4, y_start = n.P0)
        imSimpleLag1 = SimpleLag(; K = 1, T = n.T_5, y_start = n.P0)
        imSimpleLag2 = SimpleLag(; K = 1, T = n.T_6, y_start = n.P0)
        imSimpleLag3 = SimpleLag(; K = 1, T = n.T_7, y_start = n.P0)
        imGain1 = Gain(; k = n.K_1)
        imGain2 = Gain(; k = n.K_2)
        imGain3 = Gain(; k = n.K_3)
        imGain4 = Gain(; k = n.K_4)
        imGain5 = Gain(; k = n.K_5)
        imGain6 = Gain(; k = n.K_6)
        imGain7 = Gain(; k = n.K_7)
        imGain8 = Gain(; k = n.K_8)
        Pref = Constant(; k = n.P0)
        add3_1 = Add3(; k2 = -1, k3 = -1)
        gain = Gain(; k = 1 / n.T_3)
        limiter = Limiter(; uMax = n.U_o, uMin = n.U_c)
        limIntegrator = LimIntegrator(; k = 1, outMax = n.P_MAX, outMin = n.P_MIN, initType = :InitialOutput,
            y_start = n.P0)
        add = Add()
        add1 = Add()
        add2 = Add()
        add3 = Add()
        add4 = Add()
        add5 = Add()
    end
    vars = @variables begin
        SPEED_HP(t), [description = "Machine speed deviation from nominal [pu]"]
        PMECH_HP(t), [description = "Turbine mechanical power [pu]"]
        PMECH_LP(t), [description = "Turbine mechanical power [pu]"]
    end
    eqs = Equation[
        SPEED_HP ~ imLeadLag.u,               # connect(SPEED_HP, imLeadLag.u)
        Pref.y ~ add3_1.u1,                   # connect(Pref.y, add3_1.u1)
        add3_1.u2 ~ imLeadLag.y,              # connect(add3_1.u2, imLeadLag.y)
        add3_1.y ~ gain.u,                    # connect(add3_1.y, gain.u)
        gain.y ~ limiter.u,                   # connect(gain.y, limiter.u)
        limiter.y ~ limIntegrator.u,          # connect(limiter.y, limIntegrator.u)
        imSimpleLag1.u ~ imSimpleLag.y,       # connect(imSimpleLag1.u, imSimpleLag.y)
        limIntegrator.y ~ imSimpleLag.u,      # connect(limIntegrator.y, imSimpleLag.u)
        add3_1.u3 ~ imSimpleLag.u,            # connect(add3_1.u3, imSimpleLag.u)
        imGain1.u ~ imSimpleLag.y,            # connect(imGain1.u, imSimpleLag.y)
        imGain2.u ~ imSimpleLag.y,            # connect(imGain2.u, imSimpleLag.y)
        imSimpleLag1.y ~ imSimpleLag2.u,      # connect(imSimpleLag1.y, imSimpleLag2.u)
        imGain3.u ~ imSimpleLag2.u,           # connect(imGain3.u, imSimpleLag2.u)
        imGain4.u ~ imSimpleLag2.u,           # connect(imGain4.u, imSimpleLag2.u)
        add.u2 ~ imGain3.y,                   # connect(add.u2, imGain3.y)
        imGain1.y ~ add.u1,                   # connect(imGain1.y, add.u1)
        add1.u1 ~ imGain4.y,                  # connect(add1.u1, imGain4.y)
        imGain2.y ~ add1.u2,                  # connect(imGain2.y, add1.u2)
        imSimpleLag2.y ~ imSimpleLag3.u,      # connect(imSimpleLag2.y, imSimpleLag3.u)
        imGain5.u ~ imSimpleLag3.u,           # connect(imGain5.u, imSimpleLag3.u)
        imGain6.u ~ imSimpleLag3.u,           # connect(imGain6.u, imSimpleLag3.u)
        imGain6.y ~ add2.u1,                  # connect(imGain6.y, add2.u1)
        add1.y ~ add2.u2,                     # connect(add1.y, add2.u2)
        add.y ~ add3.u1,                      # connect(add.y, add3.u1)
        imGain5.y ~ add3.u2,                  # connect(imGain5.y, add3.u2)
        imSimpleLag3.y ~ imGain7.u,           # connect(imSimpleLag3.y, imGain7.u)
        imGain8.u ~ imGain7.u,                # connect(imGain8.u, imGain7.u)
        add4.y ~ PMECH_LP,                    # connect(add4.y, PMECH_LP)
        imGain8.y ~ add4.u1,                  # connect(imGain8.y, add4.u1)
        add2.y ~ add4.u2,                     # connect(add2.y, add4.u2)
        add3.y ~ add5.u1,                     # connect(add3.y, add5.u1)
        imGain7.y ~ add5.u2,                  # connect(imGain7.y, add5.u2)
        add5.y ~ PMECH_HP,                    # connect(add5.y, PMECH_HP)
    ]
    System(eqs, t, vars, pars; name, systems)
end
