# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/SevenBus/Network.mo (extends nothing; Modelica.Icons.Example is graphical)
# Seven-bus system: seven `BusExt` (FSSV, FTILL, FSBIS, FVERGE, FPAND, FTDPRA, FVALDI) at 380 kV, three internal
# generator buses, 14 `PwLine` with the same R/X, four loads, four PSSE two-winding transformers with the taps of
# the `PF_results` record, the three generation units and a fault at FTILL from 1 to 1.2 s.
# The pins of a `BusExt` are the subsystems `p_i`/`n_i` (BusExt.jl): `FTILL.n[1]` of the .mo is `FTILL.n_1` here.
# Quirk replicated: `internal_bus_gen3` takes the `Bus` defaults (S_b = 100 MVA, V_b = 400 kV, v_0 = 1, angle_0 = 0)
# while `internal_bus_gen1`/`internal_bus_gen2` take the unit's rating and the record's voltage.
# Named `SevenBus_Network` (JULIA_NAMES). Omitted: graphical annotations, displayPF, `inner SystemBase SysData`.

@component function SevenBus_Network(; name, S_b = 100e6, fn = 50, PF_results = SevenBus_PF_results)
    V, M, L, T = PF_results.voltages, PF_results.machines, PF_results.loads, PF_results.trafos
    line = (; R = 6e-6, X = 0.000692, G = 0.0, B = 0.0)   # every PwLine of the .mo has these values
    systems = @named begin
        GEN1 = SevenBus_G1(; M_b = 1078000000.0, P_0 = M.P21_1, Q_0 = M.Q21_1, V_b = 24000.0, angle_0 = V.A21,
            v_0 = V.V21, S_b, fn)
        pwLine = PwLine(; line..., S_b, fn)
        pwLine1 = PwLine(; line..., S_b, fn)
        pwLine2 = PwLine(; line..., S_b, fn)
        pwLine3 = PwLine(; line..., S_b, fn)
        pwLine4 = PwLine(; line..., S_b, fn)
        pwLine5 = PwLine(; line..., S_b, fn)
        load = Load(; V_b = 380000.0, v_0 = V.V5, angle_0 = V.A5, P_0 = L.PL5_1, Q_0 = L.QL5_1, S_b, fn)
        load1 = Load(; V_b = 380000.0, v_0 = V.V3, angle_0 = V.A3, P_0 = L.PL3_1, Q_0 = L.QL3_1, S_b, fn)
        pwLine6 = PwLine(; line..., S_b, fn)
        pwLine7 = PwLine(; line..., S_b, fn)
        FSSV = BusExt(; np = 4, V_b = 380000.0, nn = 1, v_0 = V.V2, angle_0 = V.A2, S_b, fn)
        FTILL = BusExt(; nn = 2, np = 4, V_b = 380000.0, v_0 = V.V5, angle_0 = V.A5, S_b, fn)
        FSBIS = BusExt(; nn = 2, np = 3, V_b = 380000.0, v_0 = V.V3, angle_0 = V.A3, S_b, fn)
        FVERGE = BusExt(; np = 4, V_b = 380000.0, nn = 1, v_0 = V.V7, angle_0 = V.A7, S_b, fn)
        FPAND = BusExt(; np = 4, nn = 2, V_b = 380000.0, v_0 = V.V1, angle_0 = V.A1, S_b, fn)
        FTDPRA = BusExt(; np = 2, nn = 4, V_b = 380000.0, v_0 = V.V4, angle_0 = V.A4, S_b, fn)
        pwLine8 = PwLine(; line..., S_b, fn)
        pwLine9 = PwLine(; line..., S_b, fn)
        pwLine10 = PwLine(; line..., S_b, fn)
        pwLine11 = PwLine(; line..., S_b, fn)
        load2 = Load(; P_0 = L.PL1_1, Q_0 = L.QL1_1, V_b = 380000.0, angle_0 = V.A1, v_0 = V.V1, S_b, fn)
        load3 = Load(; P_0 = L.PL4_1, Q_0 = L.QL4_1, V_b = 380000.0, angle_0 = V.A4, v_0 = V.V4, S_b, fn)
        FVALDI = BusExt(; nn = 4, V_b = 380000.0, np = 1, v_0 = V.V6, angle_0 = V.A6, S_b, fn)
        pwLine12 = PwLine(; line..., S_b, fn)
        pwLine13 = PwLine(; line..., S_b, fn)
        twoWindingTransformer = PSSE_TwoWindingTransformer(; ANG1 = 0.00174532925199433, B = 0.0, G = 0.0,
            R = 0.00001, VB1 = 380000.0, VB2 = 380000.0, VNOM1 = 380000.0, VNOM2 = 380000.0, X = 0.00069,
            t1 = T.t1_1_4, t2 = T.t2_1_4, S_b, fn)
        GEN2 = SevenBus_G2(; M_b = 1710000000.0, P_0 = M.P61_1, Q_0 = M.Q61_1, V_b = 20000.0, angle_0 = V.A61,
            v_0 = V.V61, S_b, fn)
        GEN3 = SevenBus_G3(; M_b = 1211000000.0, P_0 = M.P71_1, Q_0 = M.Q71_1, V_b = 24000.0, angle_0 = V.A71,
            v_0 = V.V71, S_b, fn)
        pwFault = PwFault(; R = 0.1, X = 0.1, t1 = 1.0, t2 = 1.2)
        twoWindingTransformer1 = PSSE_TwoWindingTransformer(; ANG1 = 0.00174532925199433, B = 0.0, CW = 1, CZ = 2,
            G = 0.0, R = 0.0025, S_n = 1080000000.0, VB1 = 24000.0, VB2 = 380000.0, VNOM1 = 24000.0,
            VNOM2 = 415000.0, X = 0.137, t1 = T.t1_2_21, t2 = T.t2_2_21, S_b, fn)
        twoWindingTransformer2 = PSSE_TwoWindingTransformer(; ANG1 = 0.00174532925199433, B = 0.0, CZ = 2, G = 0.0,
            R = 0.0029, S_n = 1710000000.0, VB1 = 20000.0, VB2 = 380000.0, VNOM1 = 20000.0, VNOM2 = 405000.0,
            X = 0.1583, t1 = T.t1_6_61, t2 = T.t2_6_61, S_b, fn)
        twoWindingTransformer3 = PSSE_TwoWindingTransformer(; ANG1 = 0.00174532925199433, B = 0.0, CZ = 2, G = 0.0,
            R = 0.0025, S_n = 1080000000.0, VB1 = 24000.0, VB2 = 380000.0, VNOM1 = 24000.0, VNOM2 = 415000.0,
            X = 0.1362, t1 = T.t1_7_71, t2 = T.t2_7_71, S_b, fn)
        internal_bus_gen1 = Bus(; S_b = 1078000000.0, angle_0 = V.A21, v_0 = V.V21, fn)
        internal_bus_gen3 = Bus(; S_b, fn)
        internal_bus_gen2 = Bus(; S_b = 1710000000.0, angle_0 = V.A61, v_0 = V.V61, fn)
    end
    eqs = Equation[
        connect(pwLine.n, FTILL.n_1),
        connect(pwLine1.n, FTILL.n_2),
        connect(pwLine4.p, FTILL.p_1),
        connect(pwLine5.p, FTILL.p_2),
        connect(load.p, FTILL.p_3),
        connect(pwLine2.p, FSBIS.p_1),
        connect(pwLine3.p, FSBIS.p_2),
        connect(load1.p, FSBIS.p_3),
        connect(pwLine4.n, FSBIS.n_1),
        connect(pwLine5.n, FSBIS.n_2),
        connect(pwLine.p, FSSV.p_1),
        connect(pwLine1.p, FSSV.p_2),
        connect(pwLine7.p, FSSV.p_3),
        connect(pwLine6.p, FSSV.p_4),
        connect(pwLine6.n, FPAND.n_1),
        connect(pwLine7.n, FPAND.n_2),
        connect(pwLine9.p, FPAND.p_1),
        connect(pwLine8.p, FPAND.p_2),
        connect(pwLine8.n, FVERGE.p_1),
        connect(pwLine9.n, FVERGE.p_2),
        connect(pwLine11.n, FTDPRA.n_1),
        connect(pwLine10.n, FTDPRA.n_2),
        connect(pwLine11.p, FVERGE.p_3),
        connect(pwLine10.p, FVERGE.p_4),
        connect(load2.p, FPAND.p_3),
        connect(load3.p, FTDPRA.n_3),
        connect(pwLine3.n, FVALDI.n_1),
        connect(pwLine2.n, FVALDI.n_2),
        connect(pwLine13.n, FVALDI.n_3),
        connect(pwLine12.n, FVALDI.n_4),
        connect(pwLine13.p, FTDPRA.p_1),
        connect(pwLine12.p, FTDPRA.p_2),
        connect(twoWindingTransformer.n, FTDPRA.n_4),
        connect(twoWindingTransformer.p, FPAND.p_4),
        connect(pwFault.p, FTILL.p_4),
        connect(twoWindingTransformer2.n, FVALDI.p_1),
        connect(twoWindingTransformer3.n, FVERGE.n_1),
        connect(twoWindingTransformer1.n, FSSV.n_1),
        connect(GEN1.pwPin, internal_bus_gen1.p),
        connect(internal_bus_gen1.p, twoWindingTransformer1.p),
        connect(twoWindingTransformer3.p, internal_bus_gen3.p),
        connect(GEN3.pwPin, internal_bus_gen3.p),
        connect(GEN2.pwPin, internal_bus_gen2.p),
        connect(internal_bus_gen2.p, twoWindingTransformer2.p),
    ]
    System(eqs, t, [], []; name, systems)
end
