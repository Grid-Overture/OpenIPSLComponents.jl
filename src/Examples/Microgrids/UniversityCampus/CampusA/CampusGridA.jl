# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Microgrids/UniversityCampus/CampusA/CampusGridA.mo, transcribed automatically (2026-09-17); reviewed by hand.
# extends: none (Modelica.Icons.Example is graphical). The Texas university campus A: 17 buses at 69 kV, 12 kV and
# 416 V, six PSSE two-winding transformers, 18 lines, 11 loads, three shunts, a `GENCLS` utility and four complete
# PSSE generation units (GENROU + ESST4B / AC7B / ESST2A + GAST / TGOV1 + DisabledPSS, two of them with an IEEEVC).
# **It instantiates no renewable at all** (the correction `PLAN-07` made to `PLAN-00`'s batch-7 text) and it is an
# **equilibrium run**: `pwFault` is at t = 1000 s and `BreakerMicrogrid` has no `t_o`, so nothing acts in [0, 15] s.
# `pf` is the keyword that carries the power-flow record (the `SevenBus_Network` precedent), so the transcribed
# text `pf.powerflow.bus.V2` is literal.
# The `PSSData.PSS2B*` records are dead data (all four units instantiate `DisabledPSS`) and are not ported.
# **No OpenModelica reference** (F-63): OM cannot initialize this system at all.
# Named `CampusGridA`. Omitted: graphical annotations, displayPF, `inner SystemBase SysData`.
@component function CampusGridA(; name, S_b = 100e6, fn = 60, pf = CampusA_Pf00000)
    systems = @named begin
        AENB = Bus(; V_b = 69000.0, v_0 = pf.powerflow.bus.V2, angle_0 = pf.powerflow.bus.A2, S_b, fn)
        H2E = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V3, angle_0 = pf.powerflow.bus.A3, S_b, fn)
        H4S = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V4, angle_0 = pf.powerflow.bus.A4, S_b, fn)
        H3N = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V5, angle_0 = pf.powerflow.bus.A5, S_b, fn)
        H1W = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V6, angle_0 = pf.powerflow.bus.A6, S_b, fn)
        T1 = PSSE_TwoWindingTransformer(; R = 0.02, X = 0.153700, G = 0.0, B = 0.0, CW = 2, VNOM1 = 69000.0, VNOM2 = 12000.0, S_n = 30000000.0, S_b, fn)
        T2 = PSSE_TwoWindingTransformer(; R = 0.02, X = 0.153700, G = 0.0, B = 0.0, CW = 2, VNOM1 = 69000.0, VNOM2 = 12000.0, S_n = 30000000.0, S_b, fn)
        T4 = PSSE_TwoWindingTransformer(; R = 0.02, X = 0.153700, G = 0.0, B = 0.0, CW = 2, VNOM1 = 69000.0, VNOM2 = 12000.0, S_n = 30000000.0, S_b, fn)
        T3 = PSSE_TwoWindingTransformer(; R = 0.02, X = 0.153700, G = 0.0, B = 0.0, CW = 2, VNOM1 = 69000.0, VNOM2 = 12000.0, S_n = 30000000.0, S_b, fn)
        X1 = PwLine(; R = 0.0, X = 0.5021, G = 0.0, B = 0.0, S_b, fn)
        X2 = PwLine(; R = 0.0, X = 0.5021, G = 0.0, B = 0.0, S_b, fn)
        X4 = PwLine(; R = 0.0, X = 0.5021, G = 0.0, B = 0.0, S_b, fn)
        A1W = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V7, angle_0 = pf.powerflow.bus.A7, S_b, fn)
        A2E = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V8, angle_0 = pf.powerflow.bus.A8, S_b, fn)
        X3 = PwLine(; R = 0.0, X = 0.5021, G = 0.0, B = 0.0, S_b, fn)
        W1W = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V9, angle_0 = pf.powerflow.bus.A9, S_b, fn)
        W2E = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V10, angle_0 = pf.powerflow.bus.A10, S_b, fn)
        X5 = PwLine(; R = 0.0, X = 0.5021, G = 0.0, B = 0.0, S_b, fn)
        W3N = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V11, angle_0 = pf.powerflow.bus.A11, S_b, fn)
        W4S = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V12, angle_0 = pf.powerflow.bus.A12, S_b, fn)
        X6 = PwLine(; R = 0.0, X = 0.5021, G = 0.0, B = 0.0, S_b, fn)
        X7 = PwLine(; R = 0.0, X = 0.5021, G = 0.0, B = 0.0, S_b, fn)
        B416N = Bus(; V_b = 4160.0, v_0 = pf.powerflow.bus.V13, angle_0 = pf.powerflow.bus.A13, S_b, fn)
        T6 = PSSE_TwoWindingTransformer(; R = 0.01, X = 0.057620, G = 0.0, B = 0.0, CW = 2, VNOM1 = 12000.0, VNOM2 = 4160.0, S_n = 7500000.0, S_b, fn)
        T5 = PSSE_TwoWindingTransformer(; R = 0.01, X = 0.05762, G = 0.0, B = 0.0, CW = 2, VNOM1 = 12000.0, VNOM2 = 4160.0, S_n = 7500000.0, S_b, fn)
        AENA = Bus(; V_b = 69000.0, v_0 = pf.powerflow.bus.V1, angle_0 = pf.powerflow.bus.A1, S_b, fn)
        L1 = PwLine(; R = 0.01, X = 0.01, G = 0.0, B = 0.0, S_b, fn)
        L3 = PwLine(; R = 0.0, X = 0.0001, G = 0.0, B = 0.0, S_b, fn)
        Load01 = Load(; P_0 = pf.powerflow.loads.PL1, Q_0 = pf.powerflow.loads.QL1, v_0 = pf.powerflow.bus.V3, angle_0 = pf.powerflow.bus.A3, S_b, fn)
        Load02 = Load(; P_0 = pf.powerflow.loads.PL2, Q_0 = pf.powerflow.loads.QL2, v_0 = pf.powerflow.bus.V4, angle_0 = pf.powerflow.bus.A4, S_b, fn)
        Load03 = Load(; P_0 = pf.powerflow.loads.PL3, Q_0 = pf.powerflow.loads.QL3, v_0 = pf.powerflow.bus.V5, angle_0 = pf.powerflow.bus.A5, S_b, fn)
        Load04 = Load(; P_0 = pf.powerflow.loads.PL4, Q_0 = pf.powerflow.loads.QL4, v_0 = pf.powerflow.bus.V6, angle_0 = pf.powerflow.bus.A6, S_b, fn)
        Load05 = Load(; P_0 = pf.powerflow.loads.PL5, Q_0 = pf.powerflow.loads.QL5, v_0 = pf.powerflow.bus.V7, angle_0 = pf.powerflow.bus.A7, S_b, fn)
        Load06 = Load(; P_0 = pf.powerflow.loads.PL6, Q_0 = pf.powerflow.loads.QL6, v_0 = pf.powerflow.bus.V8, angle_0 = pf.powerflow.bus.A8, S_b, fn)
        Load09 = Load(; P_0 = pf.powerflow.loads.PL9, Q_0 = pf.powerflow.loads.QL9, v_0 = pf.powerflow.bus.V11, angle_0 = pf.powerflow.bus.A11, S_b, fn)
        Load10 = Load(; P_0 = pf.powerflow.loads.PL10, Q_0 = pf.powerflow.loads.QL10, v_0 = pf.powerflow.bus.V12, angle_0 = pf.powerflow.bus.A12, S_b, fn)
        Load07 = Load(; P_0 = pf.powerflow.loads.PL7, Q_0 = pf.powerflow.loads.QL7, v_0 = pf.powerflow.bus.V9, angle_0 = pf.powerflow.bus.A9, S_b, fn)
        Load08 = Load(; P_0 = pf.powerflow.loads.PL8, Q_0 = pf.powerflow.loads.QL8, v_0 = pf.powerflow.bus.V10, angle_0 = pf.powerflow.bus.A10, S_b, fn)
        Load11 = Load(; P_0 = pf.powerflow.loads.PL11, Q_0 = pf.powerflow.loads.QL11, v_0 = pf.powerflow.bus.V13, angle_0 = pf.powerflow.bus.A13, S_b, fn)
        L2 = PwLine(; R = 0.0, X = 0.0001, G = 0.0, B = 0.0, S_b, fn)
        L4 = PwLine(; R = 0.0, X = 0.0001, G = 0.0, B = 0.0, S_b, fn)
        L5 = PwLine(; R = 0.0, X = 0.0001, G = 0.0, B = 0.0, S_b, fn)
        L6 = PwLine(; R = 0.0, X = 0.0001, G = 0.0, B = 0.0, S_b, fn)
        L7 = PwLine(; R = 0.0, X = 0.0001, G = 0.0, B = 0.0, S_b, fn)
        BC01 = Shunt(; G = 0.0, B = 0.036)
        BC02 = Shunt(; G = 0.0, B = 0.03)
        BC03 = Shunt(; G = 0.0, B = 0.03)
        CTB = CTG2MachineComplete(; P_0 = pf.powerflow.machines.PG3, Q_0 = pf.powerflow.machines.QG3, v_0 = pf.powerflow.bus.V9, angle_0 = pf.powerflow.bus.A9, V_b = 12000.0, S_b, fn)
        CTA = CTG1MachineComplete(; P_0 = pf.powerflow.machines.PG2, Q_0 = pf.powerflow.machines.QG2, v_0 = pf.powerflow.bus.V7, angle_0 = pf.powerflow.bus.A7, V_b = 12000.0, S_b, fn)
        STGA = STG1MachineComplete(; P_0 = pf.powerflow.machines.PG4, Q_0 = pf.powerflow.machines.QG4, v_0 = pf.powerflow.bus.V10, angle_0 = pf.powerflow.bus.A10, V_b = 12000.0, S_b, fn)
        STGB = STG2MachineComplete(; P_0 = pf.powerflow.machines.PG5, Q_0 = pf.powerflow.machines.QG5, v_0 = pf.powerflow.bus.V12, angle_0 = pf.powerflow.bus.A12, V_b = 12000.0, S_b, fn)
        A1WG = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V7, angle_0 = pf.powerflow.bus.A7, S_b, fn)
        L8 = PwLine(; R = 0.0, X = 0.0001, G = 0.0, B = 0.0, S_b, fn)
        W1WG = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V9, angle_0 = pf.powerflow.bus.A9, S_b, fn)
        L9 = PwLine(; R = 0.0, X = 0.0001, G = 0.0, B = 0.0, S_b, fn)
        L10 = PwLine(; R = 0.0, X = 0.0001, G = 0.0, B = 0.0, S_b, fn)
        W2EG = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V10, angle_0 = pf.powerflow.bus.A10, S_b, fn)
        W4SG = Bus(; V_b = 12000.0, v_0 = pf.powerflow.bus.V12, angle_0 = pf.powerflow.bus.A12, S_b, fn)
        L11 = PwLine(; R = 0.0, X = 0.0001, G = 0.0, B = 0.0, S_b, fn)
        pwFault = PwFault(; R = 0.0, X = 0.2, t1 = 1000.0, t2 = 1001.0)
        UTILITY = GENCLS(; V_b = 69000.0, P_0 = pf.powerflow.machines.PG1, Q_0 = pf.powerflow.machines.QG1, v_0 = pf.powerflow.bus.V1, angle_0 = pf.powerflow.bus.A1, R_a = 0.0, S_b, fn)
        BreakerMicrogrid = Breaker(; enableTrigger = false, rc_enabled = false, t_rc = 2.5)
    end
    eqs = Equation[
        connect(AENA.p, L1.n),
        connect(L1.p, AENB.p),
        connect(T1.p, AENB.p),
        connect(T2.p, AENB.p),
        connect(T3.p, AENB.p),
        connect(T4.p, AENB.p),
        connect(T1.n, H2E.p),
        connect(T2.n, H4S.p),
        connect(T3.n, H3N.p),
        connect(T4.n, H1W.p),
        connect(H2E.p, X1.p),
        connect(X1.n, H4S.p),
        connect(H4S.p, X2.p),
        connect(X2.n, H3N.p),
        connect(H3N.p, X4.p),
        connect(X4.n, H1W.p),
        connect(X3.p, H2E.p),
        connect(X3.n, H1W.p),
        connect(A1W.p, X6.n),
        connect(X6.p, W3N.p),
        connect(W1W.p, X5.p),
        connect(X5.n, W2E.p),
        connect(A2E.p, X7.n),
        connect(X7.p, W4S.p),
        connect(T5.p, W3N.p),
        connect(T6.p, W4S.p),
        connect(T5.n, B416N.p),
        connect(T6.n, B416N.p),
        connect(Load11.p, B416N.p),
        connect(A1W.p, L2.n),
        connect(L2.p, H2E.p),
        connect(A2E.p, L3.p),
        connect(L3.n, H1W.p),
        connect(A1W.p, L4.p),
        connect(L4.n, A2E.p),
        connect(W1W.p, L5.p),
        connect(L5.n, H4S.p),
        connect(W2E.p, L6.p),
        connect(L6.n, H3N.p),
        connect(W3N.p, L7.p),
        connect(L7.n, W4S.p),
        connect(Load09.p, W3N.p),
        connect(Load10.p, W4S.p),
        connect(Load08.p, W2E.p),
        connect(Load07.p, W1W.p),
        connect(Load05.p, A1W.p),
        connect(Load06.p, A2E.p),
        connect(Load01.p, H2E.p),
        connect(Load02.p, H4S.p),
        connect(Load03.p, H3N.p),
        connect(Load04.p, H1W.p),
        connect(BC02.p, W3N.p),
        connect(BC01.p, A2E.p),
        connect(BC03.p, B416N.p),
        connect(L8.p, A1WG.p),
        connect(A1WG.p, CTA.pwPin),
        connect(L8.n, A1W.p),
        connect(W1WG.p, CTB.pwPin),
        connect(L9.p, W1WG.p),
        connect(L9.n, W1W.p),
        connect(W2EG.p, STGA.pwPin),
        connect(W2EG.p, L10.p),
        connect(L10.n, W2E.p),
        connect(STGB.pwPin, W4SG.p),
        connect(L11.n, W4S.p),
        connect(L11.p, W4SG.p),
        connect(pwFault.p, W1W.p),
        connect(UTILITY.p, BreakerMicrogrid.r),
    ]
    System(eqs, t, [], []; name, systems)
end