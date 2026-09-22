# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/WSIEG1.mo (extends nothing: its ports are its own)
# Ports as plain variables: SPEED_HP and PMECH0 (inputs), PMECH_HP and PMECH_LP (outputs).
# Blocks: LeadLag(K, T_2, T_1, 0), Steam/Reheater1/Reheater2/Crossover = SimpleLag(1, T_4/T_5/T_6/T_7, y_start = p0),
# Gain1_HP..Gain4_LP = Gain(K_1..K_8), add_ref = Add3(k2 = -1, k3 = -1), Gov_gain = Gain(1/T_3),
# limiter = Limiter(U_o, U_c), Gov_Integrator = LimIntegrator(1, P_MAX, P_MIN, InitialOutput, y_start = GV0),
# add_12_HP..add1234_HP = Add, deadband1 = Deadband1(db1, err), Lookup_GateValve_Pmech = CombiTable1Ds(the five
# (GV, PGV) points, LinearSegments), Pref = Constant(GV0), deadband2 = Deadband2(db2).
#
# Four `parameter (fixed = false)`: `p0` (from the input PMECH0 and the HP_LP selector), `GV0` (the *inverse* of the
# lookup table at p0, an `if` chain over the five segments), `Pp_max` and `Pp_min` (the `if Iblock` chain). The `if`s
# are on Integer/Real parameters, so they are decided in Julia before `@parameters` (F-22, point 1) and only the
# selected equation is written; `GV0`'s chain compares the unknown `p0`, so it is an `ifelse` inside the
# initialization equation, segment by segment as the `.mo` writes it (its four branches are not the table's four
# segments: the `.mo` tests PGV4, then PGV3, then PGV2, and the `else` is the PGV2..PGV3 segment).
#
# Two deviations from the `.mo`, both required to reproduce OpenModelica 1.25 (F-50):
#  * `initial equation Gov_Integrator.outMax = Pp_max` / `outMin = Pp_min` are redundant with the modifiers
#    `Gov_Integrator(outMax = P_MAX, outMin = P_MIN)`, and OpenModelica removes them as redundant initial equations.
#    The limits stay `P_MAX`/`P_MIN`; `Pp_max`/`Pp_min` keep their own `if Iblock` equations and are not used.
#  * `deadband2(y(start = GV0))` is NOT honoured: `GV0` is `fixed = false`, and OpenModelica starts the discrete
#    output of `Deadband2` at 0, not at the solved `GV0` (the Test's CSV has `wSIEG1.deadband2.y = 0` on all
#    100 046 rows while its input rises from 0.495 to 1.5). Reproducing the modifier would change the trajectory,
#    so the block keeps the Modelica default start of a discrete Real, 0. The Test also settles F-22 (6): the
#    condition `u > pre(y) + db` is already true at t = 0 and never has a rising edge, so OpenModelica freezes `y`
#    exactly as ModelingToolkit does and `Deadband2` needs no change.
# Omitted: graphical annotations.

@component function WSIEG1(; name, K = 30.32, T_1 = 0.5, T_2 = 1e-8, T_3 = 0.1, U_o = 0.4, U_c = -0.4, P_MAX = 1.5,
        P_MIN = 0, T_4 = 0.25, K_1 = 0.307, K_2 = 0, T_5 = 10, K_3 = 0, K_4 = 0.23, T_6 = 0.588, K_5 = 0.2315,
        K_6 = 0.2315, T_7 = 1e-8, K_7 = 0, K_8 = 0, db1 = 0.0006, err = 0, db2 = 0, GV1 = 0, GV2 = 0.25, GV3 = 0.5,
        GV4 = 0.75, GV5 = 2, PGV1 = 0, PGV2 = 0.25, PGV3 = 0.5, PGV4 = 0.75, PGV5 = 2, Iblock = 0, HP_LP = 1)
    K, T_1, T_2, T_3, U_o, U_c, P_MAX, P_MIN, T_4, K_1, K_2, T_5, K_3, K_4, T_6, K_5, K_6, T_7, K_7, K_8, db1, err,
    db2, GV1, GV2, GV3, GV4, GV5, PGV1, PGV2, PGV3, PGV4, PGV5 =
        float.((K, T_1, T_2, T_3, U_o, U_c, P_MAX, P_MIN, T_4, K_1, K_2, T_5, K_3, K_4, T_6, K_5, K_6, T_7, K_7, K_8,
            db1, err, db2, GV1, GV2, GV3, GV4, GV5, PGV1, PGV2, PGV3, PGV4, PGV5))
    n = (; K, T_1, T_2, T_3, U_o, U_c, P_MAX, P_MIN, T_4, K_1, K_2, T_5, K_3, K_4, T_6, K_5, K_6, T_7, K_7, K_8,
        db1, err, db2)
    tbl = [GV1 PGV1; GV2 PGV2; GV3 PGV3; GV4 PGV4; GV5 PGV5]
    eps = Modelica.Constants.eps
    pars = @parameters begin
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
        db1 = db1, [description = "Speed deadband"]
        err = err, [description = "Error deadband"]
        db2 = db2, [description = "Gate valve deadband"]
        GV1 = GV1, [description = "Gate valve position 1"]
        GV2 = GV2, [description = "Gate valve position 2"]
        GV3 = GV3, [description = "Gate valve position 3"]
        GV4 = GV4, [description = "Gate valve position 4"]
        GV5 = GV5, [description = "Gate valve position 5"]
        PGV1 = PGV1, [description = "Mechanical power 1"]
        PGV2 = PGV2, [description = "Mechanical power 2"]
        PGV3 = PGV3, [description = "Mechanical power 3"]
        PGV4 = PGV4, [description = "Mechanical power 4"]
        PGV5 = PGV5, [description = "Mechanical power 5"]
        p0, [guess = 1.0]
        GV0, [guess = 1.0]
        Pp_max, [guess = 1.0]
        Pp_min, [guess = 0.0]
    end
    # the .mo names this instance after its own class, which inside the Julia constructor would shadow the block:
    # it is built with an explicit `name`, so the hierarchical name is still `LeadLag` (as in DEGOV's `Constant`)
    LeadLag_ = LeadLag(; name = :LeadLag, K = n.K, T1 = n.T_2, T2 = n.T_1, y_start = 0)
    systems = @named begin
        Steam = SimpleLag(; K = 1, T = n.T_4, y_start = p0)
        Reheater1 = SimpleLag(; K = 1, T = n.T_5, y_start = p0)
        Reheater2 = SimpleLag(; K = 1, T = n.T_6, y_start = p0)
        Crossover = SimpleLag(; K = 1, T = n.T_7, y_start = p0)
        Gain1_HP = Gain(; k = n.K_1)
        Gain1_LP = Gain(; k = n.K_2)
        Gain2_HP = Gain(; k = n.K_3)
        Gain2_LP = Gain(; k = n.K_4)
        Gain3_HP = Gain(; k = n.K_5)
        Gain3_LP = Gain(; k = n.K_6)
        Gain4_HP = Gain(; k = n.K_7)
        Gain4_LP = Gain(; k = n.K_8)
        add_ref = Add3(; k2 = -1, k3 = -1)
        Gov_gain = Gain(; k = 1 / n.T_3)
        limiter = Limiter(; uMax = n.U_o, uMin = n.U_c)
        Gov_Integrator = LimIntegrator(; k = 1, outMax = n.P_MAX, outMin = n.P_MIN, initType = :InitialOutput,
            y_start = GV0)
        add_12_HP = Add()
        add12_LP = Add()
        add123_LP = Add()
        add_123_HP = Add()
        add1234_LP = Add()
        add1234_HP = Add()
        deadband1 = Deadband1(; db = n.db1, err = n.err)
        Lookup_GateValve_Pmech = CombiTable1Ds(; table = tbl, smoothness = :LinearSegments)
        Pref = Constant(; k = GV0)
        deadband2 = Deadband2(; db = n.db2)
    end
    pushfirst!(systems, LeadLag_)
    vars = @variables begin
        SPEED_HP(t), [description = "Machine speed deviation from nominal [pu]"]
        PMECH0(t), [description = "Initial mechanical power [pu]"]
        PMECH_HP(t), [description = "Turbine mechanical power [pu]"]
        PMECH_LP(t), [description = "Turbine mechanical power [pu]"]
    end
    eqs = Equation[
        add_ref.u2 ~ LeadLag_.y,                    # connect(add_ref.u2, LeadLag.y)
        add_ref.y ~ Gov_gain.u,                     # connect(add_ref.y, Gov_gain.u)
        Gov_gain.y ~ limiter.u,                     # connect(Gov_gain.y, limiter.u)
        limiter.y ~ Gov_Integrator.u,               # connect(limiter.y, Gov_Integrator.u)
        Reheater1.u ~ Steam.y,                      # connect(Reheater1.u, Steam.y)
        Gain1_HP.u ~ Steam.y,                       # connect(Gain1_HP.u, Steam.y)
        Gain1_LP.u ~ Steam.y,                       # connect(Gain1_LP.u, Steam.y)
        Reheater1.y ~ Reheater2.u,                  # connect(Reheater1.y, Reheater2.u)
        Gain2_HP.u ~ Reheater2.u,                   # connect(Gain2_HP.u, Reheater2.u)
        Gain2_LP.u ~ Reheater2.u,                   # connect(Gain2_LP.u, Reheater2.u)
        add_12_HP.u2 ~ Gain2_HP.y,                  # connect(add_12_HP.u2, Gain2_HP.y)
        Gain1_HP.y ~ add_12_HP.u1,                  # connect(Gain1_HP.y, add_12_HP.u1)
        add12_LP.u1 ~ Gain2_LP.y,                   # connect(add12_LP.u1, Gain2_LP.y)
        Gain1_LP.y ~ add12_LP.u2,                   # connect(Gain1_LP.y, add12_LP.u2)
        Reheater2.y ~ Crossover.u,                  # connect(Reheater2.y, Crossover.u)
        Gain3_HP.u ~ Crossover.u,                   # connect(Gain3_HP.u, Crossover.u)
        Gain3_LP.u ~ Crossover.u,                   # connect(Gain3_LP.u, Crossover.u)
        Gain3_LP.y ~ add123_LP.u1,                  # connect(Gain3_LP.y, add123_LP.u1)
        add12_LP.y ~ add123_LP.u2,                  # connect(add12_LP.y, add123_LP.u2)
        add_12_HP.y ~ add_123_HP.u1,                # connect(add_12_HP.y, add_123_HP.u1)
        Gain3_HP.y ~ add_123_HP.u2,                 # connect(Gain3_HP.y, add_123_HP.u2)
        Crossover.y ~ Gain4_HP.u,                   # connect(Crossover.y, Gain4_HP.u)
        Gain4_LP.u ~ Gain4_HP.u,                    # connect(Gain4_LP.u, Gain4_HP.u)
        add1234_LP.y ~ PMECH_LP,                    # connect(add1234_LP.y, PMECH_LP)
        Gain4_LP.y ~ add1234_LP.u1,                 # connect(Gain4_LP.y, add1234_LP.u1)
        add123_LP.y ~ add1234_LP.u2,                # connect(add123_LP.y, add1234_LP.u2)
        add_123_HP.y ~ add1234_HP.u1,               # connect(add_123_HP.y, add1234_HP.u1)
        Gain4_HP.y ~ add1234_HP.u2,                 # connect(Gain4_HP.y, add1234_HP.u2)
        add1234_HP.y ~ PMECH_HP,                    # connect(add1234_HP.y, PMECH_HP)
        SPEED_HP ~ deadband1.u,                     # connect(SPEED_HP, deadband1.u)
        deadband1.y ~ LeadLag_.u,                   # connect(deadband1.y, LeadLag.u)
        add_ref.u3 ~ Lookup_GateValve_Pmech.u,      # connect(add_ref.u3, Lookup_GateValve_Pmech.u)
        Lookup_GateValve_Pmech.y[1] ~ Steam.u,      # connect(Lookup_GateValve_Pmech.y[1], Steam.u)
        Pref.y ~ add_ref.u1,                        # connect(Pref.y, add_ref.u1)
        Gov_Integrator.y ~ deadband2.u,             # connect(Gov_Integrator.y, deadband2.u)
        deadband2.y ~ Lookup_GateValve_Pmech.u,     # connect(deadband2.y, Lookup_GateValve_Pmech.u)
    ]
    # `initial equation` of the .mo, in its own order. The `if HP_LP` and `if Iblock` chains are on Integer/Real
    # parameters and are decided here; `GV0`'s chain compares `p0`, an initialization unknown, so it stays symbolic
    p0_eq = HP_LP == 1 ? PMECH0 / (K_1 + K_3 + K_5 + K_7) :
            HP_LP == 2 ? PMECH0 / (K_2 + K_4 + K_6 + K_8) : PMECH0
    gv0_eq = ifelse(p0 > PGV4, (p0 - PGV4) * (GV5 - GV4) / (PGV5 - PGV4) + GV4,
        ifelse((p0 <= PGV4) & (p0 > PGV3), (p0 - PGV3) * (GV4 - GV3) / (PGV4 - PGV3) + GV3,
            ifelse(p0 <= PGV2, (p0 - PGV1) * (GV2 - GV1) / (PGV2 - PGV1) + GV1,
                (p0 - PGV2) * (GV3 - GV2) / (PGV3 - PGV2) + GV2)))
    if Iblock == 0
        pmax_eq, pmin_eq = P_MAX, P_MIN
    elseif Iblock == 1
        pmax_eq, pmin_eq = P_MIN < eps ? (P_MAX, p0) : (P_MAX, P_MIN)
    elseif Iblock == 2
        pmax_eq, pmin_eq = P_MAX < eps ? (p0, P_MIN) : (P_MAX, P_MIN)
    else
        pmax_eq, pmin_eq = (P_MAX < eps && P_MIN < eps) ? (p0, p0) : (P_MAX, P_MIN)
    end
    ieqs = [p0 ~ p0_eq, GV0 ~ gv0_eq, Pp_max ~ pmax_eq, Pp_min ~ pmin_eq]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = ieqs,
        initial_conditions = Dict(p0 => missing, GV0 => missing, Pp_max => missing, Pp_min => missing))
end
