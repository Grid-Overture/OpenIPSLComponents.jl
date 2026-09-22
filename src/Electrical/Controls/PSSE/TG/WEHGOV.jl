# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/WEHGOV.mo (extends nothing: its ports are its own)
# Ports as plain variables: SPEED, PELEC, PMECH0 (inputs), PMECH (output).
# Blocks: Turbine = BaseClasses.WEHGOV.Turbine (built as `WEHGOV_Turbine`) and Governor = BaseClasses.WEHGOV.Governor,
# both with an explicit `name` outside the `@named` block (an assignment there would shadow the constructor with the
# instance, and the .mo names both instances after their class), and P_ref = Constant(Pref). The causal connects are
# equalities.
# `Pe0` and `Pref` are `fixed = false` from the input PELEC (`Pref = R_PERM_PE*Pe0`): `missing` parameters with
# their equations in `initialization_eqs` (F-33), `Pref` reaching `P_ref` symbolically (F-38).
# `S_b` and `M_b` are passed down to both bases and used by neither: dead parameters of the .mo, kept.
# Omitted: graphical annotations.

@component function WEHGOV(; name, S_b = 100e6, M_b = 100e6, R_PERM_GATE = 1, R_PERM_PE = 1, T_PE = 0.5, M = 1,
        SP_Band = 0, KP = 3, KI = 0.36, KD = 1.5, TD = 0.1, TP = 0.2, GMAX = 1, GMIN = 0, DICN = 0.05, DPV = 0,
        TDV = 0.2, GTMXOP = 0.1, GTMXCL = -0.2, Tg = 0.2, G1 = 0, G2 = 0.25, FLWG1 = 0, FLWG2 = 0.25, TW = 0.2,
        FLWP1 = 0, FLWP2 = 0.2, FLWP3 = 0.23, FLWP4 = 0.4, FLWP5 = 0.6, FLWP6 = 0.8, Pmech1 = 0, Pmech2 = 0,
        Pmech3 = 0.05, Pmech4 = 0.35, Pmech5 = 0.66, Pmech6 = 0.82, D_TURB = 0)
    Mn = M   # the Integer value: `@parameters` below rebinds `M` to the symbol (F-22)
    S_b, M_b, R_PERM_GATE, R_PERM_PE, T_PE, SP_Band, KP, KI, KD, TD, TP, GMAX, GMIN, DICN, DPV, TDV, GTMXOP,
    GTMXCL, Tg, G1, G2, FLWG1, FLWG2, TW, FLWP1, FLWP2, FLWP3, FLWP4, FLWP5, FLWP6, Pmech1, Pmech2, Pmech3,
    Pmech4, Pmech5, Pmech6, D_TURB = float.((S_b, M_b, R_PERM_GATE, R_PERM_PE, T_PE, SP_Band, KP, KI, KD, TD, TP,
        GMAX, GMIN, DICN, DPV, TDV, GTMXOP, GTMXCL, Tg, G1, G2, FLWG1, FLWG2, TW, FLWP1, FLWP2, FLWP3, FLWP4,
        FLWP5, FLWP6, Pmech1, Pmech2, Pmech3, Pmech4, Pmech5, Pmech6, D_TURB))
    n = (; S_b, M_b, R_PERM_GATE, R_PERM_PE, T_PE, SP_Band, KP, KI, KD, TD, TP, GMAX, GMIN, DICN, DPV, TDV, GTMXOP,
        GTMXCL, Tg, G1, G2, FLWG1, FLWG2, TW, FLWP1, FLWP2, FLWP3, FLWP4, FLWP5, FLWP6, Pmech1, Pmech2, Pmech3,
        Pmech4, Pmech5, Pmech6, D_TURB)
    pars = @parameters begin
        S_b = S_b, [description = "System base"]
        M_b = M_b, [description = "System base"]
        R_PERM_GATE = R_PERM_GATE, [description = "Feedback Gate gain"]
        R_PERM_PE = R_PERM_PE, [description = "Pelec gain"]
        T_PE = T_PE, [description = "Electrical power transducer time constant"]
        M = M, [description = "Feedback control switch"]
        SP_Band = SP_Band, [description = "Speed deadband"]
        KP = KP, [description = "Governor proportional gain"]
        KI = KI, [description = "Governor integral gain"]
        KD = KD, [description = "Governor derivative gain"]
        TD = TD, [description = "Governor derivative controller time constant"]
        TP = TP, [description = "Pilot valve time constant"]
        GMAX = GMAX, [description = "Maximum limit for the gate position"]
        GMIN = GMIN, [description = "Minimum limit for the gate position"]
        DICN = DICN, [description = "PID integral controller limit from field tuning"]
        DPV = DPV, [description = "Change in valve output"]
        TDV = TDV, [description = "Distribution valve time constant"]
        GTMXOP = GTMXOP, [description = "Maximum gate opening rate [p.u./s]"]
        GTMXCL = GTMXCL, [description = "Maximum gate closing rate [p.u./s]"]
        Tg = Tg, [description = "Distribution valve limit"]
        G1 = G1, [description = "Gate position 1"]
        G2 = G2, [description = "Gate position 2"]
        FLWG1 = FLWG1, [description = "Water flow rate 1"]
        FLWG2 = FLWG2, [description = "Water flow rate 2"]
        TW = TW, [description = "Water time constant"]
        FLWP1 = FLWP1
        FLWP2 = FLWP2
        FLWP3 = FLWP3
        FLWP4 = FLWP4
        FLWP5 = FLWP5
        FLWP6 = FLWP6
        Pmech1 = Pmech1
        Pmech2 = Pmech2
        Pmech3 = Pmech3
        Pmech4 = Pmech4
        Pmech5 = Pmech5
        Pmech6 = Pmech6
        D_TURB = D_TURB, [description = "Turbine damping"]
        Pe0, [guess = 1.0]
        Pref, [guess = 1.0]
    end
    Turbine_ = WEHGOV_Turbine(; name = :Turbine, S_b = n.S_b, M_b = n.M_b, G1 = n.G1, G2 = n.G2, FLWG1 = n.FLWG1,
        FLWG2 = n.FLWG2, TW = n.TW, FLWP1 = n.FLWP1, FLWP2 = n.FLWP2, FLWP3 = n.FLWP3, FLWP4 = n.FLWP4,
        FLWP5 = n.FLWP5, FLWP6 = n.FLWP6, Pmech1 = n.Pmech1, Pmech2 = n.Pmech2, Pmech3 = n.Pmech3,
        Pmech4 = n.Pmech4, Pmech5 = n.Pmech5, Pmech6 = n.Pmech6, D_TURB = n.D_TURB)
    Governor_ = Governor(; name = :Governor, S_b = n.S_b, M_b = n.M_b, R_PERM_PE = n.R_PERM_PE, R_PERM_GATE = n.R_PERM_GATE,
        T_PE = n.T_PE, M = Mn, SP_Band = n.SP_Band, KP = n.KP, KI = n.KI, KD = n.KD, TD = n.TD, TP = n.TP,
        GMAX = n.GMAX, GMIN = n.GMIN, DICN = n.DICN, DPV = n.DPV, TDV = n.TDV, GTMXOP = n.GTMXOP,
        GTMXCL = n.GTMXCL, Tg = n.Tg, G1 = n.G1, G2 = n.G2, FLWG1 = n.FLWG1, FLWG2 = n.FLWG2, FLWP1 = n.FLWP1,
        FLWP2 = n.FLWP2, FLWP3 = n.FLWP3, FLWP4 = n.FLWP4, FLWP5 = n.FLWP5, FLWP6 = n.FLWP6,
        Pmech1 = n.Pmech1, Pmech2 = n.Pmech2, Pmech3 = n.Pmech3, Pmech4 = n.Pmech4, Pmech5 = n.Pmech5,
        Pmech6 = n.Pmech6)
    systems = @named begin
        P_ref = Constant(; k = Pref)
    end
    prepend!(systems, [Turbine_, Governor_])
    vars = @variables begin
        SPEED(t)
        PELEC(t)
        PMECH(t)
        PMECH0(t)
    end
    eqs = Equation[
        Governor_.Gate_Position ~ Turbine_.Gate_Position,  # connect(Governor.Gate_Position, Turbine.Gate_Position)
        P_ref.y ~ Governor_.PREF,                          # connect(P_ref.y, Governor.PREF)
        SPEED ~ Governor_.SPEED,                           # connect(SPEED, Governor.SPEED)
        PELEC ~ Governor_.PELEC,                           # connect(PELEC, Governor.PELEC)
        Turbine_.SPEED ~ SPEED,                           # connect(Turbine.SPEED, SPEED)
        Turbine_.PMECH ~ PMECH,                           # connect(Turbine.PMECH, PMECH)
        PMECH0 ~ Turbine_.PMECH0,                         # connect(PMECH0, Turbine.PMECH0)
        Governor_.PMECH0 ~ Turbine_.PMECH0,                # connect(Governor.PMECH0, Turbine.PMECH0)
    ]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = [Pe0 ~ PELEC, Pref ~ R_PERM_PE * Pe0],
        initial_conditions = Dict(Pe0 => missing, Pref => missing))
end
