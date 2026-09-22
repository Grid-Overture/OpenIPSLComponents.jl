# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Microgrids/IEEEMicrogrid/IEEEMicrogrid.mo, transcribed automatically (2026-09-17); reviewed by hand.
# extends: none (Modelica.Icons.Example is graphical). The IEEE microgrid: eight buses, a GENCLS grid behind a PSSE
# transformer, a diesel unit, a PV and a BESS at constant power factor (`QFunctionality = 0`, so neither
# instantiates its `PlantController` -- the `redeclare REPCA1` of the .mo builds nothing) and two identical VSD
# chains that start a `CIM5` each from a frequency ramp over 0-3 s.
# `PF_results` is the kwarg that carries the record (the `SevenBus_Network` precedent); `mods` forwards component
# modifiers to `Diesel`, which is how the case gives `DEGOV` its Pade order (F-51).
# `PV` and `BESS` are instances named exactly like their classes and shadow them: both are reached qualified (F-61).
# `GRID = GENCLS` takes the `pfComponent` defaults for P_0/Q_0/v_0/angle_0 (sic): the record's `PInf`/`QInf` are
# never read.
# `Fault1`, `Fault2` (t1 = 1000 s) and `BreakerGrid` (no `t_o`) are inert over the 20 s of the case.
# **No OpenModelica reference** (F-63): OM cannot initialize this system at all.
# Named `IEEEMicrogrid`. Omitted: graphical annotations, displayPF, `inner SystemBase SysData`.
@component function IEEEMicrogrid(; name, S_b = 100e6, fn = 60,
        PF_results = IEEEMicrogrid_PF_results, mods = (;))
    systems = @named begin
        Bus4 = Bus(; V_b = 400.0, v_0 = PF_results.voltages.V4, angle_0 = PF_results.voltages.A4, S_b, fn)
        substation_line_2 = PwLine(; R = 0.0785/2, X = 0.0818/2, G = 0.0, B = 0.0, S_b, fn)
        Bus3 = Bus(; V_b = 400.0, v_0 = PF_results.voltages.V3, angle_0 = PF_results.voltages.A3, S_b, fn)
        substation_line_1 = PwLine(; R = 0.04257/2, X = 0.0796/2, G = 0.0, B = 0.0, S_b, fn)
        Bus2 = Bus(; V_b = 400.0, v_0 = PF_results.voltages.V2, angle_0 = PF_results.voltages.A2, S_b, fn)
        Transformer = PSSE_TwoWindingTransformer(; CZ = 1, R = 0.0, X = 0.057, G = 0.0, B = 0.0, CW = 1, VB1 = 11000.0, VB2 = 400.0, S_b, fn)
        Bus1 = Bus(; V_b = 11000.0, v_0 = PF_results.voltages.V1, angle_0 = PF_results.voltages.A1, S_b, fn)
        GRID = GENCLS(; V_b = 11000.0, R_a = 0.0, X_d = 1.0, S_b, fn)
        Fault1 = PwFault(; R = 0.01, X = 0.1, t1 = 1000.0, t2 = 1001.0)
        Fault2 = PwFault(; R = 0.5, X = 0.5, t1 = 1000.0, t2 = 1001.0)
        substation_line_3 = PwLine(; R = 0.0785/2, X = 0.0818/2, G = 0.0, B = 0.0, S_b, fn)
        substation_line_4 = PwLine(; R = 0.04257/2, X = 0.0796/2, G = 0.0, B = 0.0, S_b, fn)
        load = Load(; V_b = 400.0, P_0 = PF_results.loads.P1, Q_0 = PF_results.loads.Q1, v_0 = PF_results.voltages.V5, angle_0 = PF_results.voltages.A5, S_b, fn)
        capacitor_bank = Shunt(; G = 0.0, B = 0.02/4)
        capacitor_bank1 = Shunt(; G = 0.0, B = 0.02/4)
        capacitor_bank2 = Shunt(; G = 0.0, B = 0.02/4)
        capacitor_bank3 = Shunt(; G = 0.0, B = 0.02/4)
        Diesel = DieselGeneratorUnit(; mods = get(mods, :Diesel, (;)), P_0 = PF_results.machines.PDT, Q_0 = PF_results.machines.QDT, v_0 = PF_results.voltages.V4, angle_0 = PF_results.voltages.A4, S_b, fn)
        Bus5 = Bus(; V_b = 400.0, v_0 = PF_results.voltages.V5, angle_0 = PF_results.voltages.A5, S_b, fn)
        Bus6 = Bus(; V_b = 400.0, v_0 = PF_results.voltages.V6, angle_0 = PF_results.voltages.A6, S_b, fn)
        LoadLine = PwLine(; R = 0.2686, X = 0.089300, G = 0.0, B = 0.0, S_b, fn)
        BreakerGrid = Breaker(; enableTrigger = false)
        LoadLine1 = PwLine(; R = 0.2686, X = 0.089300, G = 0.0, B = 0.0, S_b, fn)
        Bus7 = Bus(; V_b = 400.0, v_0 = PF_results.voltages.V7, angle_0 = PF_results.voltages.A7, S_b, fn)
        aC2DCandDC2AC = AC2DCandDC2AC(; V_b = 400.0, v_0 = PF_results.voltages.V7, angle_0 = PF_results.voltages.A7, Rdc = 0.01, Cdc = 0.000001, m0 = 0.095, S_b, fn)
        voltsHertzController = VoltsHertzController(; V_b = 400.0, f_max = 80.0, f_min = 0.0, m0 = 0.095, Kp = 0.5, Ki = 0.2, S_b, fn)
        Motor1 = CIM5(; V_b = 400.0, M_b = 50000.0, Sup = true, T_nom = 0.4, D = 1.0, S_b, fn)
        Sync_Speed = Ramp(; height = 0.9*1.9*pi*fn, duration = 3, offset = 0.1*1.9*pi*fn, startTime = 0)
        PV = OpenIPSLComponents.PV(; M_b = 80000.0, V_b = 400.0, P_0 = PF_results.machines.PPV,
            Q_0 = PF_results.machines.QPV, v_0 = PF_results.voltages.V4, angle_0 = PF_results.voltages.A4,
            QFunctionality = 0, S_b, fn,
            mods = (; RenewableGenerator = (; redeclare = REGCA1), RenewableController = (; redeclare = REECB1),
                PlantController = (; redeclare = REPCA1)))
        BESS = OpenIPSLComponents.BESS(; M_b = 50000.0, V_b = 400.0, P_0 = PF_results.machines.PBESS,
            Q_0 = PF_results.machines.QBESS, v_0 = PF_results.voltages.V4, angle_0 = PF_results.voltages.A4,
            QFunctionality = 0, S_b, fn,
            mods = (; RenewableGenerator = (; redeclare = REGCA1), RenewableController = (; redeclare = REECCU1),
                PlantController = (; redeclare = REPCA1)))
        BusGrid = Bus(; V_b = 11000.0, v_0 = PF_results.voltages.V1, angle_0 = PF_results.voltages.A1, S_b, fn)
        aC2DCandDC2AC1 = AC2DCandDC2AC(; V_b = 400.0, v_0 = PF_results.voltages.V7, angle_0 = PF_results.voltages.A7, Rdc = 0.01, Cdc = 0.000001, m0 = 0.095, S_b, fn)
        voltsHertzController1 = VoltsHertzController(; V_b = 400.0, f_max = 80.0, f_min = 0.0, m0 = 0.095, Kp = 0.5, Ki = 0.2, S_b, fn)
        Motor2 = CIM5(; V_b = 400.0, M_b = 50000.0, Sup = true, T_nom = 0.4, D = 1.0, S_b, fn)
        Sync_Speed1 = Ramp(; height = 0.9*1.9*pi*fn, duration = 3, offset = 0.1*1.9*pi*fn, startTime = 0)
    end
    eqs = Equation[
        connect(substation_line_2.p, Bus4.p),
        connect(substation_line_3.p, Bus4.p),
        connect(substation_line_2.n, Bus3.p),
        connect(substation_line_3.n, Bus3.p),
        connect(Fault2.p, Bus3.p),
        connect(substation_line_1.p, Bus3.p),
        connect(substation_line_4.p, Bus3.p),
        connect(substation_line_1.n, Bus2.p),
        connect(substation_line_4.n, Bus2.p),
        connect(Fault1.p, Bus2.p),
        connect(Diesel.pwPin, Bus4.p),
        connect(Bus5.p, Bus4.p),
        connect(load.p, Bus6.p),
        connect(Bus6.p, LoadLine.n),
        connect(BreakerGrid.r, Bus1.p),
        connect(LoadLine.p, Bus4.p),
        connect(LoadLine1.p, Bus4.p),
        connect(LoadLine1.n, Bus7.p),
        voltsHertzController.Vc ~ aC2DCandDC2AC.Vc,   # connect(voltsHertzController.Vc, aC2DCandDC2AC.Vc)
        voltsHertzController.m ~ aC2DCandDC2AC.m_input,   # connect(voltsHertzController.m, aC2DCandDC2AC.m_input)
        Motor1.wr ~ voltsHertzController.motor_speed,   # connect(Motor1.wr, voltsHertzController.motor_speed)
        voltsHertzController.we ~ Motor1.we,   # connect(voltsHertzController.we, Motor1.we)
        connect(Motor1.p, aC2DCandDC2AC.n),
        Sync_Speed.y ~ voltsHertzController.W_ref,   # connect(Sync_Speed.y, voltsHertzController.W_ref)
        connect(BESS.pwPin, Bus4.p),
        connect(PV.pwPin, Bus4.p),
        connect(Bus1.p, Transformer.p),
        connect(Transformer.n, Bus2.p),
        connect(BusGrid.p, BreakerGrid.s),
        connect(BusGrid.p, GRID.p),
        connect(capacitor_bank.p, Bus5.p),
        connect(capacitor_bank1.p, Bus5.p),
        connect(capacitor_bank2.p, Bus5.p),
        connect(capacitor_bank3.p, Bus5.p),
        connect(aC2DCandDC2AC.p, Bus7.p),
        voltsHertzController1.Vc ~ aC2DCandDC2AC1.Vc,   # connect(voltsHertzController1.Vc, aC2DCandDC2AC1.Vc)
        voltsHertzController1.m ~ aC2DCandDC2AC1.m_input,   # connect(voltsHertzController1.m, aC2DCandDC2AC1.m_input)
        Motor2.wr ~ voltsHertzController1.motor_speed,   # connect(Motor2.wr, voltsHertzController1.motor_speed)
        voltsHertzController1.we ~ Motor2.we,   # connect(voltsHertzController1.we, Motor2.we)
        connect(Motor2.p, aC2DCandDC2AC1.n),
        Sync_Speed1.y ~ voltsHertzController1.W_ref,   # connect(Sync_Speed1.y, voltsHertzController1.W_ref)
        connect(aC2DCandDC2AC1.p, Bus7.p),
    ]
    System(eqs, t, [], []; name, systems)
end