# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/WEHGOV/Governor.mo (model)
# Blocks: switch1/switch2 = Logical.Switch, PE_Transducer = SimpleLag(R_PERM_PE, T_PE, y_start = s00),
# Feedback_Signal_Switch/Feedback_Signal_Switch1 = Constant(M), realToBoolean/realToBoolean1 =
# RealToBoolean(threshold = 1), const1 = Constant(0), multiSum = MultiSum(k = {1, -1, -1, -1}, nu = 4),
# DeadBand = DeadZone(uMax = SP_Band), derivativeLag = Continuous.Derivative(KD, TD, InitialOutput, x_start = 0),
# gain = Gain(KP), limIntegrator1 = LimIntegrator(KI, GMAX + DICN, GMIN - DICN, InitialOutput, y_start = sG),
# add3_1 = Add3, Feedback_Gain = Gain(R_PERM_GATE), Pilot_Valve = SimpleLagLim(1, TP, y_start = sG, GMAX + DPV,
# GMIN - DPV), add3_2 = Add3(k2 = -1, k3 = -1), Distribution_Valve = LimIntegrator(1/TDV, GTMXOP*Tg, GTMXCL*Tg,
# InitialOutput, y_start = 0), gain1 = Gain(1/Tg), limIntegrator2 = LimIntegrator(GMAX, GMIN, InitialOutput,
# y_start = sG). Ports as plain variables: SPEED, PELEC, PREF, PMECH0 (inputs), Gate_Position (output).
# The `M` switch is instantiated literally (`Constant(M)` -> `RealToBoolean(threshold = 1)` -> `Switch`), not decided
# in Julia: `mtkcompile` reduces the constant chain anyway, and the OpenModelica CSVs carry the three columns.
# Six `fixed = false` parameters from the inputs PELEC and PMECH0, in the .mo's order: `Pe0`, `Pmech0`, `s00`, `p0`,
# then `sG` (the inverse of the gate/flow table at `f0`) and `f0` (the inverse of the flow/power table at `p0`),
# whose `if` chains compare initialization unknowns and are therefore `ifelse`, branch by branch (F-33, F-38).
# `S_b` and `M_b` are declared by the .mo and used nowhere: dead parameters, kept.
# Omitted: graphical annotations.

@component function Governor(; name, S_b = 100e6, M_b = 100e6, R_PERM_PE = 1, R_PERM_GATE = 1, T_PE = 0.5, M = 1,
        SP_Band = 0, KP = 3, KI = 0.36, KD = 1.5, TD = 0.1, TP = 0.2, GMAX = 1, GMIN = 0, DICN = 0.05, DPV = 0,
        TDV = 0.2, GTMXOP = 0.1, GTMXCL = -0.2, Tg = 0.2, G1 = 0, G2 = 0.25, G3 = 0.5, G4 = 0.75, G5 = 1,
        FLWG1 = 0, FLWG2 = 0.25, FLWG3 = 0.5, FLWG4 = 0.75, FLWG5 = 1, FLWP1 = 0, FLWP2 = 0.2, FLWP3 = 0.23,
        FLWP4 = 0.4, FLWP5 = 0.6, FLWP6 = 0.8, FLWP7 = 0.87, FLWP8 = 0.9, FLWP9 = 0.95, FLWP10 = 1, Pmech1 = 0,
        Pmech2 = 0, Pmech3 = 0.05, Pmech4 = 0.35, Pmech5 = 0.66, Pmech6 = 0.82, Pmech7 = 0.85, Pmech8 = 0.86,
        Pmech9 = 0.88, Pmech10 = 0.9)
    Mn = M   # the Integer value: `@parameters` below rebinds `M` to the symbol (F-22)
    S_b, M_b, R_PERM_PE, R_PERM_GATE, T_PE, SP_Band, KP, KI, KD, TD, TP, GMAX, GMIN, DICN, DPV, TDV, GTMXOP,
    GTMXCL, Tg, G1, G2, G3, G4, G5, FLWG1, FLWG2, FLWG3, FLWG4, FLWG5, FLWP1, FLWP2, FLWP3, FLWP4, FLWP5, FLWP6,
    FLWP7, FLWP8, FLWP9, FLWP10, Pmech1, Pmech2, Pmech3, Pmech4, Pmech5, Pmech6, Pmech7, Pmech8, Pmech9, Pmech10 =
        float.((S_b, M_b, R_PERM_PE, R_PERM_GATE, T_PE, SP_Band, KP, KI, KD, TD, TP, GMAX, GMIN, DICN, DPV, TDV,
            GTMXOP, GTMXCL, Tg, G1, G2, G3, G4, G5, FLWG1, FLWG2, FLWG3, FLWG4, FLWG5, FLWP1, FLWP2, FLWP3, FLWP4,
            FLWP5, FLWP6, FLWP7, FLWP8, FLWP9, FLWP10, Pmech1, Pmech2, Pmech3, Pmech4, Pmech5, Pmech6, Pmech7,
            Pmech8, Pmech9, Pmech10))
    n = (; R_PERM_PE, R_PERM_GATE, T_PE, SP_Band, KP, KI, KD, TD, TP, GMAX, GMIN, DICN, DPV, TDV, GTMXOP, GTMXCL, Tg)
    pars = @parameters begin
        S_b = S_b, [description = "System base"]
        M_b = M_b, [description = "System base"]
        R_PERM_PE = R_PERM_PE, [description = "Pelec gain"]
        R_PERM_GATE = R_PERM_GATE, [description = "Feedback Gate gain"]
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
        G1 = G1
        G2 = G2
        G3 = G3
        G4 = G4
        G5 = G5
        FLWG1 = FLWG1
        FLWG2 = FLWG2
        FLWG3 = FLWG3
        FLWG4 = FLWG4
        FLWG5 = FLWG5
        FLWP1 = FLWP1
        FLWP2 = FLWP2
        FLWP3 = FLWP3
        FLWP4 = FLWP4
        FLWP5 = FLWP5
        FLWP6 = FLWP6
        FLWP7 = FLWP7
        FLWP8 = FLWP8
        FLWP9 = FLWP9
        FLWP10 = FLWP10
        Pmech1 = Pmech1
        Pmech2 = Pmech2
        Pmech3 = Pmech3
        Pmech4 = Pmech4
        Pmech5 = Pmech5
        Pmech6 = Pmech6
        Pmech7 = Pmech7
        Pmech8 = Pmech8
        Pmech9 = Pmech9
        Pmech10 = Pmech10
        Pe0, [guess = 1.0]
        Pmech0, [guess = 1.0]
        s00, [guess = 1.0]
        f0, [guess = 0.5]
        p0, [guess = 1.0]
        sG, [guess = 0.5]
    end
    systems = @named begin
        switch1 = Switch()
        PE_Transducer = SimpleLag(; K = n.R_PERM_PE, T = n.T_PE, y_start = s00)
        Feedback_Signal_Switch = Constant(; k = Mn)
        realToBoolean = RealToBoolean(; threshold = 1)
        const1 = Constant(; k = 0)
        multiSum = MultiSum(; k = [1, -1, -1, -1], nu = 4)
        DeadBand = DeadZone(; uMax = n.SP_Band)
        derivativeLag = Derivative(; k = n.KD, T = n.TD, initType = :InitialOutput, x_start = 0)
        gain = Gain(; k = n.KP)
        limIntegrator1 = LimIntegrator(; k = n.KI, outMax = n.GMAX + n.DICN, outMin = n.GMIN - n.DICN,
            initType = :InitialOutput, y_start = sG)
        add3_1 = Add3()
        switch2 = Switch()
        Feedback_Signal_Switch1 = Constant(; k = Mn)
        realToBoolean1 = RealToBoolean(; threshold = 1)
        Feedback_Gain = Gain(; k = n.R_PERM_GATE)
        Pilot_Valve = SimpleLagLim(; K = 1, T = n.TP, y_start = sG, outMax = n.GMAX + n.DPV, outMin = n.GMIN - n.DPV)
        add3_2 = Add3(; k2 = -1, k3 = -1)
        Distribution_Valve = LimIntegrator(; k = 1 / n.TDV, outMax = n.GTMXOP * n.Tg, outMin = n.GTMXCL * n.Tg,
            initType = :InitialOutput, y_start = 0)
        gain1 = Gain(; k = 1 / n.Tg)
        limIntegrator2 = LimIntegrator(; outMax = n.GMAX, outMin = n.GMIN, initType = :InitialOutput, y_start = sG)
    end
    vars = @variables begin
        SPEED(t)
        PELEC(t)
        PREF(t)
        Gate_Position(t)
        PMECH0(t)
    end
    eqs = Equation[
        PE_Transducer.y ~ switch1.u3,                    # connect(PE_Transducer.y, switch1.u3)
        Feedback_Signal_Switch.y ~ realToBoolean.u,      # connect(Feedback_Signal_Switch.y, realToBoolean.u)
        realToBoolean.y ~ switch1.u2,                    # connect(realToBoolean.y, switch1.u2)
        const1.y ~ switch1.u1,                           # connect(const1.y, switch1.u1)
        PREF ~ multiSum.u[1],                            # connect(PREF, multiSum.u[1])
        SPEED ~ multiSum.u[2],                           # connect(SPEED, multiSum.u[2])
        switch1.y ~ multiSum.u[3],                       # connect(switch1.y, multiSum.u[3])
        multiSum.y ~ DeadBand.u,                         # connect(multiSum.y, DeadBand.u)
        DeadBand.y ~ gain.u,                             # connect(DeadBand.y, gain.u)
        derivativeLag.u ~ gain.u,                        # connect(derivativeLag.u, gain.u)
        limIntegrator1.u ~ gain.u,                       # connect(limIntegrator1.u, gain.u)
        derivativeLag.y ~ add3_1.u1,                     # connect(derivativeLag.y, add3_1.u1)
        gain.y ~ add3_1.u2,                              # connect(gain.y, add3_1.u2)
        limIntegrator1.y ~ add3_1.u3,                    # connect(limIntegrator1.y, add3_1.u3)
        Feedback_Signal_Switch1.y ~ realToBoolean1.u,    # connect(Feedback_Signal_Switch1.y, realToBoolean1.u)
        realToBoolean1.y ~ switch2.u2,                   # connect(realToBoolean1.y, switch2.u2)
        add3_1.y ~ switch2.u1,                           # connect(add3_1.y, switch2.u1)
        Feedback_Gain.u ~ switch2.y,                     # connect(Feedback_Gain.u, switch2.y)
        Feedback_Gain.y ~ multiSum.u[4],                 # connect(Feedback_Gain.y, multiSum.u[4])
        Pilot_Valve.u ~ switch2.u1,                      # connect(Pilot_Valve.u, switch2.u1)
        Pilot_Valve.y ~ add3_2.u1,                       # connect(Pilot_Valve.y, add3_2.u1)
        add3_2.u2 ~ switch2.u3,                          # connect(add3_2.u2, switch2.u3)
        add3_2.y ~ Distribution_Valve.u,                 # connect(add3_2.y, Distribution_Valve.u)
        Distribution_Valve.y ~ add3_2.u3,                # connect(Distribution_Valve.y, add3_2.u3)
        gain1.u ~ add3_2.u3,                             # connect(gain1.u, add3_2.u3)
        limIntegrator2.u ~ gain1.y,                      # connect(limIntegrator2.u, gain1.y)
        limIntegrator2.y ~ switch2.u3,                   # connect(limIntegrator2.y, switch2.u3)
        Gate_Position ~ switch2.u3,                      # connect(Gate_Position, switch2.u3)
        PELEC ~ PE_Transducer.u,                         # connect(PELEC, PE_Transducer.u)
    ]
    # the two `if` chains of the `initial equation`, branch by branch as the .mo writes them, folded from the last
    # `else` backwards so the nesting cannot be miscounted
    chain(default, branches) = foldr((b, acc) -> ifelse(b[1], b[2], acc), branches; init = default)
    sG_eq = chain((f0 - FLWG2) * (G3 - G2) / (FLWG3 - FLWG2) + G2, [
        (f0 > FLWG4, (f0 - FLWG4) * (1 - G4) / (1 - FLWG4) + G4),
        ((f0 <= FLWG4) & (f0 > FLWG3), (f0 - FLWG3) * (G4 - G3) / (FLWG4 - FLWG3) + G3),
        (f0 <= FLWG2, f0 * G2 / FLWG2),
    ])
    f0_eq = chain((p0 - Pmech2) * (FLWP3 - FLWP2) / (Pmech3 - Pmech2) + FLWP2, [
        (p0 > Pmech9, (p0 - Pmech9) * (1 - FLWP9) / (Pmech10 - Pmech9) + FLWP9),
        ((p0 <= Pmech9) & (p0 > Pmech8), (p0 - Pmech8) * (FLWP9 - FLWP8) / (Pmech9 - Pmech8) + FLWP8),
        ((p0 <= Pmech8) & (p0 > Pmech7), (p0 - Pmech7) * (FLWP8 - FLWP7) / (Pmech8 - Pmech7) + FLWP7),
        ((p0 <= Pmech7) & (p0 > Pmech6), (p0 - Pmech6) * (FLWP7 - FLWP6) / (Pmech7 - Pmech6) + FLWP6),
        ((p0 <= Pmech6) & (p0 > Pmech5), (p0 - Pmech5) * (FLWP6 - FLWP5) / (Pmech6 - Pmech5) + FLWP5),
        ((p0 <= Pmech5) & (p0 > Pmech4), (p0 - Pmech4) * (FLWP5 - FLWP4) / (Pmech5 - Pmech4) + FLWP4),
        ((p0 <= Pmech4) & (p0 > Pmech3), (p0 - Pmech3) * (FLWP4 - FLWP3) / (Pmech4 - Pmech3) + FLWP3),
        (p0 <= Pmech2, p0 * FLWP2 / Pmech2),
    ])
    ieqs = [
        Pe0 ~ PELEC,
        Pmech0 ~ PMECH0,
        s00 ~ PELEC * R_PERM_PE,
        p0 ~ Pmech0,
        sG ~ sG_eq,
        f0 ~ f0_eq,
    ]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = ieqs,
        initial_conditions = Dict(Pe0 => missing, Pmech0 => missing, s00 => missing, f0 => missing,
            p0 => missing, sG => missing))
end
