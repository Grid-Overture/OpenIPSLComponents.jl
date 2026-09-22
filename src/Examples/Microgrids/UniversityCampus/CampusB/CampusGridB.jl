# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Microgrids/UniversityCampus/CampusB/CampusGridB.mo, transcribed automatically (2026-09-17); reviewed by hand.
# extends: none (Modelica.Icons.Example is graphical). University campus B: 32 buses, 30 lines, five PSSE
# two-winding transformers (one per PV plant), 10 loads, a `GENCLS` utility, two gas-turbine units and one
# steam-turbine unit, and **five `PV` plants** with `REGCA1` + `REECB1` at constant power factor.
# It is an **equilibrium run**: the fault is at t = 1000 s and the seven breakers have no `t_o`.
# `pf` is the keyword that carries the power-flow record, so `pf.powerflow.bus.VB1L1` is literal.
# The five `PV` instances are named like their class and shadow it: all are reached qualified (F-61).
# The `Data.*Campus1` records of the B package are **not read by this system** (it uses `PfData`) and are not
# ported, as `PLAN-07` decided.
# **No OpenModelica reference** (F-63). Named `CampusGridB`.
# Omitted: graphical annotations, displayPF, `inner SystemBase SysData`.
@component function CampusGridB(; name, S_b = 100e6, fn = 60, pf = CampusB_Pf00000)
    systems = @named begin
        B1L1 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB1L1, angle_0 = pf.powerflow.bus.AB1L1, S_b, fn)
        B2L1 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB2L1, angle_0 = pf.powerflow.bus.VB2L1, S_b, fn)
        B1L4 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB1L4, angle_0 = pf.powerflow.bus.AB1L4, S_b, fn)
        B2L4 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB2L4, angle_0 = pf.powerflow.bus.AB2L4, S_b, fn)
        B3L4 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB3L4, angle_0 = pf.powerflow.bus.AB3L4, S_b, fn)
        UTILITY = GENCLS(; V_b = 13800.0, P_0 = pf.powerflow.machines.PG1, Q_0 = pf.powerflow.machines.QG1, v_0 = pf.powerflow.bus.VB1L3, angle_0 = pf.powerflow.bus.AB1L3, R_a = 0.01, S_b, fn)
        B1L2 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB1L2, angle_0 = pf.powerflow.bus.AB1L2, S_b, fn)
        B2L2 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB2L2, angle_0 = pf.powerflow.bus.AB2L2, S_b, fn)
        B3L2 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB3L2, angle_0 = pf.powerflow.bus.AB3L2, S_b, fn)
        B1L5 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB1L5, angle_0 = pf.powerflow.bus.AB1L5, S_b, fn)
        B2L5 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB2L5, angle_0 = pf.powerflow.bus.AB2L5, S_b, fn)
        B3L5 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB3L5, angle_0 = pf.powerflow.bus.AB3L5, S_b, fn)
        B4L5 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB4L5, angle_0 = pf.powerflow.bus.AB4L5, S_b, fn)
        B5L5 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB5L5, angle_0 = pf.powerflow.bus.AB5L5, S_b, fn)
        B6L5 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB6L5, angle_0 = pf.powerflow.bus.AB6L5, S_b, fn)
        L1 = Load(; V_b = 13800.0, P_0 = pf.powerflow.loads.PL1, Q_0 = pf.powerflow.loads.QL1, v_0 = pf.powerflow.bus.VB1L5, angle_0 = pf.powerflow.bus.AB1L5, S_b, fn)
        L2 = Load(; V_b = 13800.0, P_0 = pf.powerflow.loads.PL2, Q_0 = pf.powerflow.loads.QL2, v_0 = pf.powerflow.bus.VB2L5, angle_0 = pf.powerflow.bus.AB2L5, S_b, fn)
        B1L7 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB1L7, angle_0 = pf.powerflow.bus.AB1L7, S_b, fn)
        L7 = Load(; V_b = 13800.0, P_0 = pf.powerflow.loads.PL7, Q_0 = pf.powerflow.loads.QL7, v_0 = pf.powerflow.bus.VB1L7, angle_0 = pf.powerflow.bus.AB1L7, S_b, fn)
        L5 = Load(; V_b = 13800.0, P_0 = pf.powerflow.loads.PL5, Q_0 = pf.powerflow.loads.QL5, v_0 = pf.powerflow.bus.VB6L5, angle_0 = pf.powerflow.bus.AB6L5, S_b, fn)
        Line18 = PwLine(; R = 0.4, X = 0.1, G = 0.0, B = 0.0, S_b, fn)
        Line21 = PwLine(; R = 0.5, X = 0.001, G = 0.0, B = 0.0, S_b, fn)
        B1L8 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB1L8, angle_0 = pf.powerflow.bus.AB1L8, S_b, fn)
        Line9 = PwLine(; R = 0.1, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        Line10 = PwLine(; R = 0.2, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        Line11 = PwLine(; R = 0.2, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        Line12 = PwLine(; R = 0.2, X = 0.1, G = 0.0, B = 0.0, S_b, fn)
        Line13 = PwLine(; R = 0.2, X = 0.1, G = 0.0, B = 0.0, S_b, fn)
        Line14 = PwLine(; R = 0.3, X = 0.1, G = 0.0, B = 0.0, S_b, fn)
        Line15 = PwLine(; R = 0.2, X = 0.001, G = 0.0, B = 0.0, S_b, fn)
        Line16 = PwLine(; R = 0.2, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        Line17 = PwLine(; R = 0.7, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        L4 = Load(; V_b = 13800.0, P_0 = pf.powerflow.loads.PL4, Q_0 = pf.powerflow.loads.QL4, v_0 = pf.powerflow.bus.VB5L5, angle_0 = pf.powerflow.bus.AB5L5, S_b, fn)
        L3 = Load(; V_b = 13800.0, P_0 = pf.powerflow.loads.PL3, Q_0 = pf.powerflow.loads.QL3, v_0 = pf.powerflow.bus.VB4L5, angle_0 = pf.powerflow.bus.AB4L5, S_b, fn)
        Line19 = PwLine(; R = 0.2, X = 0.1, G = 0.0, B = 0.0, S_b, fn)
        B1L6 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB1L6, angle_0 = pf.powerflow.bus.AB1L6, S_b, fn)
        Line20 = PwLine(; R = 0.2, X = 0.001, G = 0.0, B = 0.0, S_b, fn)
        L6 = Load(; V_b = 13800.0, P_0 = pf.powerflow.loads.PL6, Q_0 = pf.powerflow.loads.QL6, v_0 = pf.powerflow.bus.VB1L6, angle_0 = pf.powerflow.bus.AB1L6, S_b, fn)
        B1L9 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB1L9, angle_0 = pf.powerflow.bus.AB1L9, S_b, fn)
        Line24 = PwLine(; R = 0.2, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        L9 = Load(; V_b = 13800.0, P_0 = pf.powerflow.loads.PL9, Q_0 = pf.powerflow.loads.QL9, v_0 = pf.powerflow.bus.VB1L9, angle_0 = pf.powerflow.bus.AB1L9, S_b, fn)
        B2L9 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB2L9, angle_0 = pf.powerflow.bus.AB2L9, S_b, fn)
        Line25 = PwLine(; R = 0.001, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        L10 = Load(; V_b = 13800.0, P_0 = pf.powerflow.loads.PL10, Q_0 = pf.powerflow.loads.QL10, v_0 = pf.powerflow.bus.VB2L9, angle_0 = pf.powerflow.bus.AB2L9, S_b, fn)
        B2L7 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB2L7, angle_0 = pf.powerflow.bus.AB2L7, S_b, fn)
        Line22 = PwLine(; R = 0.2, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        Line23 = PwLine(; R = 0.1, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        B2L8 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB2L8, angle_0 = pf.powerflow.bus.AB2L8, S_b, fn)
        L8 = Load(; V_b = 13800.0, P_0 = pf.powerflow.loads.PL8, Q_0 = pf.powerflow.loads.QL8, v_0 = pf.powerflow.bus.VB2L8, angle_0 = pf.powerflow.bus.AB2L8, S_b, fn)
        Line2 = PwLine(; R = 0.2, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        Line3 = PwLine(; R = 0.2, X = 0.001, G = 0.0, B = 0.0, S_b, fn)
        Line6 = PwLine(; R = 0.5, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        B1L3 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VB1L3, angle_0 = pf.powerflow.bus.AB1L3, S_b, fn)
        Line7 = PwLine(; R = 0.2, X = 0.1, G = 0.0, B = 0.0, S_b, fn)
        Line8 = PwLine(; R = 0.2, X = 0.001, G = 0.0, B = 0.0, S_b, fn)
        Line1 = PwLine(; R = 0.3, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        Line4 = PwLine(; R = 0.2, X = 0.001, G = 0.0, B = 0.0, S_b, fn)
        Line5 = PwLine(; R = 0.4, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        Br1 = Breaker(; enableTrigger = false)
        Br2 = Breaker(; )
        Br3 = Breaker(; rc_enabled = false, t_rc = 10.5)
        pwFault = PwFault(; R = 0.5, X = 0.5, t1 = 1000.0, t2 = 1001.0)
        GT1 = GasTurbineUnit(; P_0 = pf.powerflow.machines.PG2, Q_0 = pf.powerflow.machines.QG2, v_0 = pf.powerflow.bus.VB1L2, angle_0 = pf.powerflow.bus.AB1L2)
        GT2 = GasTurbineUnit(; P_0 = pf.powerflow.machines.PG3, Q_0 = pf.powerflow.machines.QG3, v_0 = pf.powerflow.bus.VB2L2, angle_0 = pf.powerflow.bus.AB2L2)
        ST = SteamTurbineUnit(; P_0 = pf.powerflow.machines.PG4, Q_0 = pf.powerflow.machines.QG4, v_0 = pf.powerflow.bus.VB3L2, angle_0 = pf.powerflow.bus.AB3L2)
        BrST = Breaker(; enableTrigger = false)
        BrGT1 = Breaker(; enableTrigger = false)
        BrGT2 = Breaker(; enableTrigger = false)
        BrU = Breaker(; enableTrigger = false, rc_enabled = false, t_rc = 2.5)
        PV1 = OpenIPSLComponents.PV(; M_b = 409500.0, V_b = 600.0, P_0 = pf.powerflow.machines.PVP1, Q_0 = pf.powerflow.machines.PVQ1, v_0 = pf.powerflow.bus.VPV1B1, angle_0 = pf.powerflow.bus.APV1B1, QFunctionality = 0, S_b, fn,
            mods = (; RenewableGenerator = (; redeclare = REGCA1),
                RenewableController = (; redeclare = REECB1),
                PlantController = (; redeclare = REPCA1)))
        PV1B1 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VPV1B1, angle_0 = pf.powerflow.bus.APV1B1, S_b, fn)
        twoWindingTransformer = PSSE_TwoWindingTransformer(; R = 0.0, X = 0.057, G = 0.0, B = 0.0, VB1 = 600.0, VB2 = 13800.0, S_b, fn)
        PV1B2 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VPV1B2, angle_0 = pf.powerflow.bus.APV1B2, S_b, fn)
        Line26 = PwLine(; R = 0.04, X = 0.08, G = 0.0, B = 0.0, S_b, fn)
        PV2 = OpenIPSLComponents.PV(; M_b = 12600.0, V_b = 600.0, P_0 = pf.powerflow.machines.PVP2, Q_0 = pf.powerflow.machines.PVQ2, v_0 = pf.powerflow.bus.VPV2B1, angle_0 = pf.powerflow.bus.APV2B1, QFunctionality = 0, S_b, fn,
            mods = (; RenewableGenerator = (; redeclare = REGCA1),
                RenewableController = (; redeclare = REECB1),
                PlantController = (; redeclare = REPCA1)))
        PV2B1 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VPV2B1, angle_0 = pf.powerflow.bus.APV2B1, S_b, fn)
        twoWindingTransformer1 = PSSE_TwoWindingTransformer(; R = 0.0, X = 0.057, G = 0.0, B = 0.0, VB1 = 600.0, VB2 = 13800.0, S_b, fn)
        PV2B2 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VPV2B2, angle_0 = pf.powerflow.bus.APV2B2, S_b, fn)
        Line27 = PwLine(; R = 0.02, X = 0.04, G = 0.0, B = 0.0, S_b, fn)
        PV3 = OpenIPSLComponents.PV(; M_b = 7400.0, V_b = 600.0, P_0 = pf.powerflow.machines.PVP3, Q_0 = pf.powerflow.machines.PVQ3, v_0 = pf.powerflow.bus.VPV3B1, angle_0 = pf.powerflow.bus.APV3B1, QFunctionality = 0, S_b, fn,
            mods = (; RenewableGenerator = (; redeclare = REGCA1),
                RenewableController = (; redeclare = REECB1),
                PlantController = (; redeclare = REPCA1)))
        PV3B1 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VPV3B1, angle_0 = pf.powerflow.bus.APV3B1, S_b, fn)
        twoWindingTransformer2 = PSSE_TwoWindingTransformer(; R = 0.0, X = 0.057, G = 0.0, B = 0.0, VB1 = 600.0, VB2 = 13800.0, S_b, fn)
        PV3B2 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VPV3B2, angle_0 = pf.powerflow.bus.APV3B2, S_b, fn)
        Line28 = PwLine(; R = 0.01, X = 0.05, G = 0.0, B = 0.0, S_b, fn)
        PV4 = OpenIPSLComponents.PV(; M_b = 103200.0, V_b = 600.0, P_0 = pf.powerflow.machines.PVP4, Q_0 = pf.powerflow.machines.PVQ4, v_0 = pf.powerflow.bus.VPV4B1, angle_0 = pf.powerflow.bus.APV4B1, QFunctionality = 0, S_b, fn,
            mods = (; RenewableGenerator = (; redeclare = REGCA1),
                RenewableController = (; redeclare = REECB1),
                PlantController = (; redeclare = REPCA1)))
        PV4B1 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VPV4B1, angle_0 = pf.powerflow.bus.APV4B1, S_b, fn)
        twoWindingTransformer3 = PSSE_TwoWindingTransformer(; R = 0.0, X = 0.057, G = 0.0, B = 0.0, VB1 = 600.0, VB2 = 13800.0, S_b, fn)
        PV4B2 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VPV4B2, angle_0 = pf.powerflow.bus.APV4B2, S_b, fn)
        Line29 = PwLine(; R = 0.001, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        PV5 = OpenIPSLComponents.PV(; M_b = 894700.0, V_b = 600.0, P_0 = pf.powerflow.machines.PVP5, Q_0 = pf.powerflow.machines.PVQ5, v_0 = pf.powerflow.bus.VPV5B1, angle_0 = pf.powerflow.bus.APV5B1, QFunctionality = 0, S_b, fn,
            mods = (; RenewableGenerator = (; redeclare = REGCA1),
                RenewableController = (; redeclare = REECB1),
                PlantController = (; redeclare = REPCA1)))
        PV5B1 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VPV5B1, angle_0 = pf.powerflow.bus.APV5B1, S_b, fn)
        twoWindingTransformer4 = PSSE_TwoWindingTransformer(; R = 0.0, X = 0.057, G = 0.0, B = 0.0, VB1 = 600.0, VB2 = 13800.0, S_b, fn)
        PV5B2 = Bus(; V_b = 13800.0, v_0 = pf.powerflow.bus.VPV5B2, angle_0 = pf.powerflow.bus.APV5B2, S_b, fn)
        Line30 = PwLine(; R = 0.03, X = 0.05, G = 0.0, B = 0.0, S_b, fn)
    end
    eqs = Equation[
        connect(L1.p, B1L5.p),
        connect(B2L5.p, L2.p),
        connect(L7.p, B1L7.p),
        connect(Line18.p, B1L7.p),
        connect(Line18.n, B1L5.p),
        connect(Line21.n, B1L7.p),
        connect(L5.p, B6L5.p),
        connect(B5L5.p, L4.p),
        connect(L3.p, B4L5.p),
        connect(B3L5.p, Line19.n),
        connect(Line19.p, B1L6.p),
        connect(B1L6.p, Line20.n),
        connect(L6.p, B1L6.p),
        connect(Line21.p, B1L9.p),
        connect(Line24.p, B1L9.p),
        connect(L9.p, B1L9.p),
        connect(Line25.p, B2L9.p),
        connect(B2L9.p, L10.p),
        connect(Line24.n, B1L8.p),
        connect(Line25.n, B1L8.p),
        connect(Line22.n, B2L7.p),
        connect(Line22.p, B1L8.p),
        connect(Line20.p, B2L7.p),
        connect(Line23.n, B2L7.p),
        connect(Line23.p, B2L8.p),
        connect(B2L8.p, L8.p),
        connect(Line3.p, B3L4.p),
        connect(Line2.p, B2L4.p),
        connect(B2L2.p, Line4.p),
        connect(Line4.n, B2L1.p),
        connect(Line5.n, B2L1.p),
        connect(Line5.p, B3L2.p),
        connect(Line1.p, B1L2.p),
        connect(Line1.n, B1L1.p),
        connect(B1L1.p, Br1.s),
        connect(Br1.r, B2L1.p),
        connect(Line3.n, B2L1.p),
        connect(Line2.n, B1L1.p),
        connect(Line7.n, B2L4.p),
        connect(Line7.p, B1L3.p),
        connect(Br2.r, B2L4.p),
        connect(Br2.s, B1L4.p),
        connect(Br3.s, B2L4.p),
        connect(Line8.p, B1L3.p),
        connect(Line6.p, B1L3.p),
        connect(Line6.n, B1L4.p),
        connect(Line8.n, B3L4.p),
        connect(Line9.n, B1L4.p),
        connect(Line10.n, B1L4.p),
        connect(Line11.n, B1L4.p),
        connect(Line12.n, B2L4.p),
        connect(Line13.n, B2L4.p),
        connect(Line14.n, B2L4.p),
        connect(Line15.n, B2L4.p),
        connect(Line16.n, B2L4.p),
        connect(Line17.n, B3L4.p),
        connect(Line17.p, B6L5.p),
        connect(Line16.p, B5L5.p),
        connect(Line15.p, B4L5.p),
        connect(Line14.p, B3L5.p),
        connect(Line13.p, B3L5.p),
        connect(Line10.p, B2L5.p),
        connect(Line9.p, B1L5.p),
        connect(Line11.p, B2L7.p),
        connect(Line12.p, B2L7.p),
        connect(ST.pwPin, BrST.s),
        connect(BrST.r, B3L2.p),
        connect(BrGT1.r, B1L2.p),
        connect(GT1.pwPin, BrGT1.s),
        connect(GT2.pwPin, BrGT2.s),
        connect(BrGT2.r, B2L2.p),
        connect(BrU.s, B1L3.p),
        connect(BrU.r, UTILITY.p),
        connect(PV1.pwPin, PV1B1.p),
        connect(twoWindingTransformer.p, PV1B1.p),
        connect(twoWindingTransformer.n, PV1B2.p),
        connect(PV1B2.p, Line26.p),
        connect(PV2.pwPin, PV2B1.p),
        connect(twoWindingTransformer1.p, PV2B1.p),
        connect(twoWindingTransformer1.n, PV2B2.p),
        connect(PV2B2.p, Line27.p),
        connect(Line27.n, L10.p),
        connect(Br3.r, B3L4.p),
        connect(PV3.pwPin, PV3B1.p),
        connect(twoWindingTransformer2.p, PV3B1.p),
        connect(twoWindingTransformer2.n, PV3B2.p),
        connect(PV3B2.p, Line28.p),
        connect(Line28.n, B6L5.p),
        connect(PV4.pwPin, PV4B1.p),
        connect(twoWindingTransformer3.p, PV4B1.p),
        connect(twoWindingTransformer3.n, PV4B2.p),
        connect(PV4B2.p, Line29.p),
        connect(Line29.n, B1L6.p),
        connect(PV5.pwPin, PV5B1.p),
        connect(twoWindingTransformer4.p, PV5B1.p),
        connect(twoWindingTransformer4.n, PV5B2.p),
        connect(PV5B2.p, Line30.p),
        connect(Line30.n, B5L5.p),
        connect(pwFault.p, Line30.p),
        connect(Line26.n, B1L9.p),
    ]
    System(eqs, t, [], []; name, systems)
end