# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/N44/Base_Case/Nordic44_Base_Case.mo (extends nothing; Modelica.Icons.Example is
# graphical), drafted automatically (2026-09-21, --kind example); reviewed by hand.
# The Nordic 44 base case, the largest system of the port: 44 `BusExt` at 420 kV (up to `nn = 16` on bus_7000),
# 67 `PwLine`, 12 PSSE two-winding transformers with the taps of the record, 48 PSSE `Load` with
# `characteristic = 2`, 8 `Shunt` and 80 generation units over the 18 `Generators.Gen<k>_bus_<n>` classes, on
# S_b = 1000 MVA.
# It is not an equilibrium run: `line_5103_5304_1(t1 = 2)` takes `PwLine`'s default `opening = 1`, so the line
# opens at both ends at t = 2 s and never recloses (`t2 = inf`) - "the same line opening event" of the .mo's
# documentation, and the only event of the case.
# The pins of a `BusExt` are the subsystems `p_i`/`n_i` (BusExt.jl): `bus_7000.n[1]` of the .mo is
# `bus_7000.n_1` here.
# `PF_results` is the keyword argument, defaulting to the record `N44_PF_results` the .mo declares as
# `inner Data.PF_results` (precedent: Two_Areas_PSSE.jl); `V`, `M`, `L`, `T` below are its four sub-records, so
# that a modifier reads as in the .mo (`PF_results.voltages.V7020` -> `V.V7020`).
# Named `Nordic44_Base_Case` as in the .mo. Omitted: graphical annotations, displayPF,
# `inner SystemBase SysData`, the `__OpenModelica_commandLineOptions` annotation.

@component function Nordic44_Base_Case(; name, S_b = 1000e6, fn = 50,
        PF_results = N44_PF_results)
    V, M, L, T = PF_results.voltages, PF_results.machines, PF_results.loads, PF_results.trafos
    systems = @named begin
        bus_7020 = BusExt(; nn = 1, np = 1, v_0 = V.V7020, angle_0 = V.A7020, V_b = 420000.0, S_b, fn)
        Load1_bus7020 = Load(; V_b = 420000.0, v_0 = V.V7020, angle_0 = V.A7020, P_0 = L.PL7020_1, Q_0 = L.QL7020_1,
            characteristic = 2, S_b, fn)
        bus_7000 = BusExt(; nn = 16, np = 4, v_0 = V.V7000, angle_0 = V.A7000, V_b = 420000.0, S_b, fn)
        Load1_bus7000 = Load(; V_b = 420000.0, v_0 = V.V7000, angle_0 = V.A7000, P_0 = L.PL7000_1, Q_0 = L.QL7000_1,
            characteristic = 2, S_b, fn)
        Load2_bus7000 = Load(; V_b = 420000.0, v_0 = V.V7000, angle_0 = V.A7000, P_0 = L.PL7000_2, Q_0 = L.QL7000_2,
            characteristic = 2, S_b, fn)
        Load3_bus7000 = Load(; V_b = 420000.0, v_0 = V.V7000, angle_0 = V.A7000, P_0 = L.PL7000_3, Q_0 = L.QL7000_3,
            characteristic = 2, S_b, fn)
        Load4_bus7000 = Load(; V_b = 420000.0, v_0 = V.V7000, angle_0 = V.A7000, P_0 = L.PL7000_4, Q_0 = L.QL7000_4,
            characteristic = 2, S_b, fn)
        Load5_bus7000 = Load(; V_b = 420000.0, v_0 = V.V7000, angle_0 = V.A7000, P_0 = L.PL7000_5, Q_0 = L.QL7000_5,
            characteristic = 2, S_b, fn)
        G1_bus7000 = Gen1_bus_7000(; P_0 = M.P7000_1, Q_0 = M.Q7000_1, V_b = 420000.0, v_0 = V.V7000,
            angle_0 = V.A7000, S_b, fn)
        G2_bus7000 = Gen1_bus_7000(; P_0 = M.P7000_2, Q_0 = M.Q7000_2, V_b = 420000.0, v_0 = V.V7000,
            angle_0 = V.A7000, S_b, fn)
        G3_bus7000 = Gen1_bus_7000(; P_0 = M.P7000_3, Q_0 = M.Q7000_3, V_b = 420000.0, v_0 = V.V7000,
            angle_0 = V.A7000, S_b, fn)
        G4_bus7000 = Gen1_bus_7000(; P_0 = M.P7000_4, Q_0 = M.Q7000_4, V_b = 420000.0, v_0 = V.V7000,
            angle_0 = V.A7000, S_b, fn)
        G5_bus7000 = Gen1_bus_7000(; P_0 = M.P7000_5, Q_0 = M.Q7000_5, V_b = 420000.0, v_0 = V.V7000,
            angle_0 = V.A7000, S_b, fn)
        G6_bus7000 = Gen1_bus_7000(; P_0 = M.P7000_6, Q_0 = M.Q7000_6, V_b = 420000.0, v_0 = V.V7000,
            angle_0 = V.A7000, S_b, fn)
        G7_bus7000 = Gen1_bus_7000(; P_0 = M.P7000_7, Q_0 = M.Q7000_7, V_b = 420000.0, v_0 = V.V7000,
            angle_0 = V.A7000, S_b, fn)
        G8_bus7000 = Gen1_bus_7000(; P_0 = M.P7000_8, Q_0 = M.Q7000_8, V_b = 420000.0, v_0 = V.V7000,
            angle_0 = V.A7000, S_b, fn)
        G9_bus7000 = Gen1_bus_7000(; P_0 = M.P7000_9, Q_0 = M.Q7000_9, V_b = 420000.0, v_0 = V.V7000,
            angle_0 = V.A7000, S_b, fn)
        bus_7010 = BusExt(; nn = 1, np = 1, v_0 = V.V7010, angle_0 = V.A7010, V_b = 420000.0, S_b, fn)
        Load1_bus7010 = Load(; V_b = 420000.0, v_0 = V.V7010, angle_0 = V.A7010, P_0 = L.PL7010_1, Q_0 = L.QL7010_1,
            characteristic = 2, S_b, fn)
        G1_bus7100 = Gen3_bus_7100(; V_b = 420000.0, v_0 = V.V7100, angle_0 = V.A7100, P_0 = M.P7100_1,
            Q_0 = M.Q7100_1, S_b, fn)
        G2_bus7100 = Gen3_bus_7100(; V_b = 420000.0, v_0 = V.V7100, angle_0 = V.A7100, P_0 = M.P7100_2,
            Q_0 = M.Q7100_2, S_b, fn)
        G3_bus7100 = Gen3_bus_7100(; V_b = 420000.0, v_0 = V.V7100, angle_0 = V.A7100, P_0 = M.P7100_3,
            Q_0 = M.Q7100_3, S_b, fn)
        Load1_bus7100 = Load(; V_b = 420000.0, v_0 = V.V7100, angle_0 = V.A7100, P_0 = L.PL7100_1, Q_0 = L.QL7100_1,
            characteristic = 2, S_b, fn)
        Load2_bus7100 = Load(; V_b = 420000.0, v_0 = V.V7100, angle_0 = V.A7100, P_0 = L.PL7100_2, Q_0 = L.QL7100_2,
            characteristic = 2, S_b, fn)
        bus_7100 = BusExt(; nn = 8, np = 3, v_0 = V.V7100, angle_0 = V.A7100, V_b = 420000.0, S_b, fn)
        line_7000_7010 = PwLine(; R = 0.000000, X = 0.010000, G = 0.0, B = 0.000000, S_b, fn)
        line_7000_7020 = PwLine(; R = 0.000000, X = 0.010000, G = 0.0, B = 0.000000, S_b, fn)
        line_7000_7100_1 = PwLine(; R = 0.040000, X = 0.120000, G = 0.0, B = 0.130000*0.5, S_b, fn)
        line_7000_7100_2 = PwLine(; R = 0.040000, X = 0.120000, G = 0.0, B = 0.130000*0.5, S_b, fn)
        line_7000_7100_3 = PwLine(; R = 0.040000, X = 0.140000, G = 0.0, B = 0.130000*0.5, S_b, fn)
        bus_3115 = BusExt(; np = 4, v_0 = V.V3115, angle_0 = V.A3115, V_b = 420000.0, nn = 8, S_b, fn)
        G1_bus3115 = Gen3_bus_3115(; V_b = 420000.0, v_0 = V.V3115, angle_0 = V.A3115, P_0 = M.P3115_1,
            Q_0 = M.Q3115_1, S_b, fn)
        G2_bus3115 = Gen3_bus_3115(; V_b = 420000.0, v_0 = V.V3115, angle_0 = V.A3115, P_0 = M.P3115_2,
            Q_0 = M.Q3115_2, S_b, fn)
        G3_bus3115 = Gen3_bus_3115(; V_b = 420000.0, v_0 = V.V3115, angle_0 = V.A3115, P_0 = M.P3115_3,
            Q_0 = M.Q3115_3, S_b, fn)
        Load_bus3115 = Load(; V_b = 420000.0, v_0 = V.V3115, angle_0 = V.A3115, P_0 = L.PL3115_1, Q_0 = L.QL3115_1,
            characteristic = 2, S_b, fn)
        line_3115_7100 = PwLine(; R = 0.040000, X = 0.130000, G = 0.0, B = 0.130000*0.5, S_b, fn)
        line_3000_3115 = PwLine(; R = 0.075000, X = 0.900000, G = 0.0, B = 0.500000*0.5, S_b, fn)
        line_3100_3115 = PwLine(; G = 0.0, R = 0.0150000, X = 0.200000, B = 0.20000*0.5, S_b, fn)
        line_3115_3249 = PwLine(; R = 0.015000, X = 0.200000, G = 0.0, B = 0.080000*0.5, S_b, fn)
        line_3115_6701 = PwLine(; R = 0.040000, X = 0.400000, G = 0.0, B = 0.100000*0.5, S_b, fn)
        line_3115_3245 = PwLine(; R = 0.045000, X = 0.500000, G = 0.0, B = 0.140000*0.5, S_b, fn)
        line_3249_7100 = PwLine(; R = 0.020000, X = 0.075000, G = 0.0, B = 0.078000*0.5, S_b, fn)
        bus_3000 = BusExt(; nn = 7, np = 5, v_0 = V.V3000, angle_0 = V.A3000, V_b = 420000.0, S_b, fn)
        G1_bus3000 = Gen1_bus_3000(; V_b = 420000.0, v_0 = V.V3000, angle_0 = V.A3000, P_0 = M.P3000_1,
            Q_0 = M.Q3000_1, S_b, fn)
        G2_bus3000 = Gen1_bus_3000(; V_b = 420000.0, v_0 = V.V3000, angle_0 = V.A3000, P_0 = M.P3000_2,
            Q_0 = M.Q3000_2, S_b, fn)
        G3_bus3000 = Gen1_bus_3000(; V_b = 420000.0, v_0 = V.V3000, angle_0 = V.A3000, P_0 = M.P3000_3,
            Q_0 = M.Q3000_3, S_b, fn)
        Load1_bus3000 = Load(; V_b = 420000.0, v_0 = V.V3000, angle_0 = V.A3000, P_0 = L.PL3000_1, Q_0 = L.QL3000_1,
            characteristic = 2, S_b, fn)
        Load2_bus3000 = Load(; V_b = 420000.0, v_0 = V.V3000, angle_0 = V.A3000, P_0 = L.PL3000_2, Q_0 = L.QL3000_2,
            characteristic = 2, S_b, fn)
        Load3_bus3000 = Load(; V_b = 420000.0, v_0 = V.V3000, angle_0 = V.A3000, P_0 = L.PL3000_3, Q_0 = L.QL3000_3,
            characteristic = 2, S_b, fn)
        line_3000_3020 = PwLine(; R = 0.000000, X = 0.010000, G = 0.0, B = 0.0, S_b, fn)
        line_3000_3300_1 = PwLine(; R = 0.006000, X = 0.080000, G = 0.0, B = 0.030000*0.5, S_b, fn)
        line_3000_3300_2 = PwLine(; R = 0.009000, X = 0.100000, G = 0.0, B = 0.025000*0.5, S_b, fn)
        line_3000_3245_1 = PwLine(; R = 0.008000, X = 0.120000, G = 0.0, B = 0.050000*0.5, S_b, fn)
        line_3000_3245_2 = PwLine(; R = 0.018000, X = 0.200000, G = 0.0, B = 0.050000*0.5, S_b, fn)
        bus_3020 = BusExt(; nn = 1, np = 1, v_0 = V.V3020, angle_0 = V.A3020, V_b = 420000.0, S_b, fn)
        Load_bus3020 = Load(; V_b = 420000.0, v_0 = V.V3020, angle_0 = V.A3020, P_0 = L.PL3020_1, Q_0 = L.QL3020_1,
            characteristic = 2, S_b, fn)
        bus_3300 = BusExt(; nn = 8, np = 5, v_0 = V.V3300, angle_0 = V.A3300, V_b = 420000.0, S_b, fn)
        G2_bus3300 = Gen4_bus_3300(; V_b = 420000.0, v_0 = V.V3300, angle_0 = V.A3300, P_0 = M.P3300_2,
            Q_0 = M.Q3300_2, S_b, fn)
        G3_bus3300 = Gen4_bus_3300(; V_b = 420000.0, v_0 = V.V3300, angle_0 = V.A3300, P_0 = M.P3300_3,
            Q_0 = M.Q3300_3, S_b, fn)
        G1_bus3300 = Gen4_bus_3300(; V_b = 420000.0, v_0 = V.V3300, angle_0 = V.A3300, P_0 = M.P3300_1,
            Q_0 = M.Q3300_1, S_b, fn)
        Load1_bus3300 = Load(; V_b = 420000.0, v_0 = V.V3300, angle_0 = V.A3300, P_0 = L.PL3300_1, Q_0 = L.QL3300_1,
            characteristic = 2, S_b, fn)
        Load2_bus3300 = Load(; V_b = 420000.0, v_0 = V.V3300, angle_0 = V.A3300, P_0 = L.PL3300_2, Q_0 = L.QL3300_2,
            characteristic = 2, S_b, fn)
        bus_3200 = BusExt(; nn = 5, np = 1, v_0 = V.V3200, angle_0 = V.A3200, V_b = 420000.0, S_b, fn)
        line_3200_3300 = PwLine(; R = 0.020000, X = 0.200000, G = 0.0, B = 0.060000*0.5, S_b, fn)
        line_3100_3200_3 = PwLine(; R = 0.040000, X = 0.240000, G = 0.0, B = 0.200000*0.5, S_b, fn)
        line_3100_3200_2 = PwLine(; R = 0.040000, X = 0.240000, G = 0.0, B = 0.200000*0.5, S_b, fn)
        line_3100_3200_1 = PwLine(; R = 0.040000, X = 0.240000, G = 0.0, B = 0.200000*0.5, S_b, fn)
        bus_3100 = BusExt(; nn = 6, np = 2, v_0 = V.V3100, angle_0 = V.A3100, V_b = 420000.0, S_b, fn)
        line_3300_8500_1 = PwLine(; R = 0.020000, X = 0.230000, G = 0.0, B = 0.060000*0.5, S_b, fn)
        line_3300_8500_2 = PwLine(; R = 0.012000, X = 0.270000, G = 0.0, B = 0.100000*0.5, S_b, fn)
        bus_8500 = BusExt(; nn = 9, np = 8, v_0 = V.V8500, angle_0 = V.A8500, V_b = 420000.0, S_b, fn)
        Load1_bus8500 = Load(; V_b = 420000.0, v_0 = V.V8500, angle_0 = V.A8500, P_0 = L.PL8500_1, Q_0 = L.QL8500_1,
            characteristic = 2, S_b, fn)
        Load2_bus8500 = Load(; V_b = 420000.0, v_0 = V.V8500, angle_0 = V.A8500, P_0 = L.PL8500_2, Q_0 = L.QL8500_2,
            characteristic = 2, S_b, fn)
        Load3_bus8500 = Load(; V_b = 420000.0, v_0 = V.V8500, angle_0 = V.A8500, P_0 = L.PL8500_3, Q_0 = L.QL8500_3,
            characteristic = 2, S_b, fn)
        G1_bus8500 = Gen4_bus_8500(; V_b = 420000.0, v_0 = V.V8500, angle_0 = V.A8500, P_0 = M.P8500_1,
            Q_0 = M.Q8500_1, S_b, fn)
        G2_bus8500 = Gen4_bus_8500(; V_b = 420000.0, v_0 = V.V8500, angle_0 = V.A8500, P_0 = M.P8500_2,
            Q_0 = M.Q8500_2, S_b, fn)
        line_8500_8700 = PwLine(; R = 0.000000, X = 0.010000, G = 0.0, B = 0.000000, S_b, fn)
        G3_bus8500 = Gen4_bus_8500(; V_b = 420000.0, v_0 = V.V8500, angle_0 = V.A8500, P_0 = M.P8500_3,
            Q_0 = M.Q8500_3, S_b, fn)
        line_8500_8600 = PwLine(; R = 0.000000, X = 0.010000, G = 0.0, B = 0.000000, S_b, fn)
        line_3200_8500 = PwLine(; R = 0.010000, X = 0.170000, G = 0.0, B = 0.060000*0.5, S_b, fn)
        line_3359_8500_2 = PwLine(; R = 0.025000, X = 0.320000, G = 0.0, B = 0.090000*0.5, S_b, fn)
        line_3359_8500_1 = PwLine(; R = 0.012000, X = 0.270000, G = 0.0, B = 0.100000*0.5, S_b, fn)
        G4_bus8500 = Gen4_bus_8500(; V_b = 420000.0, v_0 = V.V8500, angle_0 = V.A8500, P_0 = M.P8500_4,
            Q_0 = M.Q8500_4, S_b, fn)
        G5_bus8500 = Gen4_bus_8500(; V_b = 420000.0, v_0 = V.V8500, angle_0 = V.A8500, P_0 = M.P8500_5,
            Q_0 = M.Q8500_5, S_b, fn)
        G6_bus8500 = Gen4_bus_8500(; V_b = 420000.0, v_0 = V.V8500, angle_0 = V.A8500, P_0 = M.P8500_6,
            Q_0 = M.Q8500_6, S_b, fn)
        bus_8700 = BusExt(; nn = 1, np = 1, v_0 = V.V8700, angle_0 = V.A8700, V_b = 420000.0, S_b, fn)
        Load_bus8700 = Load(; v_0 = V.V8700, angle_0 = V.A8700, V_b = 420000.0, P_0 = L.PL8700_1, Q_0 = L.QL8700_1,
            characteristic = 2, S_b, fn)
        bus_8600 = BusExt(; nn = 1, np = 1, v_0 = V.V8600, angle_0 = V.A8600, V_b = 420000.0, S_b, fn)
        Load_bus8600 = Load(; V_b = 420000.0, v_0 = V.V8600, angle_0 = V.A8600, P_0 = L.PL8600_1, Q_0 = L.QL8600_1,
            characteristic = 2, S_b, fn)
        bus_3359 = BusExt(; nn = 9, np = 9, v_0 = V.V3359, angle_0 = V.A3359, V_b = 420000.0, S_b, fn)
        line_3200_3359 = PwLine(; R = 0.010000, X = 0.200000, G = 0.0, B = 0.070000*0.5, S_b, fn)
        Load1_bus3359 = Load(; V_b = 420000.0, v_0 = V.V3359, angle_0 = V.A3359, P_0 = L.PL3359_1, Q_0 = L.QL3359_1,
            characteristic = 2, S_b, fn)
        Load2_bus3359 = Load(; V_b = 420000.0, v_0 = V.V3359, angle_0 = V.A3359, P_0 = L.PL3359_2, Q_0 = L.QL3359_2,
            characteristic = 2, S_b, fn)
        Load3_bus3359 = Load(; V_b = 420000.0, v_0 = V.V3359, angle_0 = V.A3359, P_0 = L.PL3359_3, Q_0 = L.QL3359_3,
            characteristic = 2, S_b, fn)
        Load4_bus3359 = Load(; V_b = 420000.0, v_0 = V.V3359, angle_0 = V.A3359, P_0 = L.PL3359_4, Q_0 = L.QL3359_4,
            characteristic = 2, S_b, fn)
        line_3100_3359_1 = PwLine(; R = 0.080000, X = 0.500000, G = 0.0, B = 0.250000*0.5, S_b, fn)
        line_3100_3359_2 = PwLine(; R = 0.040000, X = 0.230000, G = 0.0, B = 0.240000*0.5, S_b, fn)
        bus_3360 = BusExt(; np = 1, v_0 = V.V3360, angle_0 = V.A3360, V_b = 135000.0, nn = 1, S_b, fn)
        Load_bus3360 = Load(; V_b = 135000.0, v_0 = V.V3360, angle_0 = V.A3360, P_0 = L.PL3360_1, Q_0 = L.QL3360_1,
            characteristic = 2, S_b, fn)
        Load_bus3100 = Load(; V_b = 420000.0, v_0 = V.V3100, angle_0 = V.A3100, P_0 = L.PL3100_1, Q_0 = L.QL3100_1,
            characteristic = 2, S_b, fn)
        line_3100_3249 = PwLine(; G = 0.0, R = 0.0150000, X = 0.2150000, B = 0.20000*0.5, S_b, fn)
        bus_3249 = BusExt(; np = 6, nn = 7, v_0 = V.V3249, angle_0 = V.A3249, V_b = 420000.0, S_b, fn)
        Load_bus3249 = Load(; V_b = 420000.0, v_0 = V.V3249, angle_0 = V.A3249, P_0 = L.PL3249_1, Q_0 = L.QL3249_1,
            characteristic = 2, S_b, fn)
        G1_bus3249 = Gen2_bus_3249(; V_b = 420000.0, v_0 = V.V3249, angle_0 = V.A3249, P_0 = M.P3249_1,
            Q_0 = M.Q3249_1, S_b, fn)
        G2_bus3249 = Gen2_bus_3249(; V_b = 420000.0, v_0 = V.V3249, angle_0 = V.A3249, P_0 = M.P3249_2,
            Q_0 = M.Q3249_2, S_b, fn)
        G3_bus3249 = Gen2_bus_3249(; V_b = 420000.0, v_0 = V.V3249, angle_0 = V.A3249, P_0 = M.P3249_3,
            Q_0 = M.Q3249_3, S_b, fn)
        G4_bus3249 = Gen2_bus_3249(; V_b = 420000.0, v_0 = V.V3249, angle_0 = V.A3249, P_0 = M.P3249_4,
            Q_0 = M.Q3249_4, S_b, fn)
        G5_bus3249 = Gen2_bus_3249(; V_b = 420000.0, v_0 = V.V3249, angle_0 = V.A3249, P_0 = M.P3249_5,
            Q_0 = M.Q3249_5, S_b, fn)
        G6_bus3249 = Gen2_bus_3249(; V_b = 420000.0, v_0 = V.V3249, angle_0 = V.A3249, P_0 = M.P3249_6,
            Q_0 = M.Q3249_6, S_b, fn)
        G7_bus3249 = Gen2_bus_3249(; V_b = 420000.0, v_0 = V.V3249, angle_0 = V.A3249, P_0 = M.P3249_7,
            Q_0 = M.Q3249_7, S_b, fn)
        bus_3701 = BusExt(; np = 1, v_0 = V.V3701, angle_0 = V.A3701, V_b = 300000.0, nn = 1, S_b, fn)
        bus_3245 = BusExt(; nn = 3, np = 2, v_0 = V.V3245, angle_0 = V.A3245, V_b = 420000.0, S_b, fn)
        G1_bus3245 = Gen2_bus_3245(; V_b = 420000.0, v_0 = V.V3245, angle_0 = V.A3245, P_0 = M.P3245_1,
            Q_0 = M.Q3245_1, S_b, fn)
        bus_3244 = BusExt(; np = 1, v_0 = V.V3244, angle_0 = V.A3244, V_b = 300000.0, nn = 1, S_b, fn)
        bus_6701 = BusExt(; nn = 2, np = 2, v_0 = V.V6701, angle_0 = V.A6701, V_b = 420000.0, S_b, fn)
        bus_6700 = BusExt(; np = 5, nn = 4, v_0 = V.V6700, angle_0 = V.A6700, V_b = 300000.0, S_b, fn)
        Load1_bus6700 = Load(; V_b = 300000.0, v_0 = V.V6700, angle_0 = V.A6700, P_0 = L.PL6700_1, Q_0 = L.QL6700_1,
            characteristic = 2, S_b, fn)
        G1_bus6700 = Gen3_bus_6700(; V_b = 300000.0, v_0 = V.V6700, angle_0 = V.A6700, P_0 = M.P6700_1,
            Q_0 = M.Q6700_1, S_b, fn)
        G2_bus6700 = Gen3_bus_6700(; V_b = 300000.0, v_0 = V.V6700, angle_0 = V.A6700, P_0 = M.P6700_2,
            Q_0 = M.Q6700_2, S_b, fn)
        line_3701_6700 = PwLine(; R = 0.250000, X = 2.000000, G = 0.0, B = 0.030000*0.5, S_b, fn)
        line_3244_6500 = PwLine(; R = 0.010000, X = 0.200000, G = 0.0, B = 0.060000*0.5, S_b, fn)
        bus_6500 = BusExt(; nn = 6, np = 5, v_0 = V.V6500, angle_0 = V.A6500, V_b = 300000.0, S_b, fn)
        line_6500_6700_1 = PwLine(; R = 0.170000, X = 1.800000, G = 0.0, B = 0.100000*0.5, S_b, fn)
        line_6500_6700_2 = PwLine(; R = 0.100000, X = 1.300000, G = 0.0, B = 0.120000*0.5, S_b, fn)
        Load1_bus6500 = Load(; V_b = 300000.0, v_0 = V.V6500, angle_0 = V.A6500, P_0 = L.PL6500_1, Q_0 = L.QL6500_1,
            characteristic = 2, S_b, fn)
        Load2_bus6500 = Load(; V_b = 300000.0, v_0 = V.V6500, angle_0 = V.A6500, P_0 = L.PL6500_2, Q_0 = L.QL6500_2,
            characteristic = 2, S_b, fn)
        Load3_bus6500 = Load(; V_b = 300000.0, v_0 = V.V6500, angle_0 = V.A6500, P_0 = L.PL6500_3, Q_0 = L.QL6500_3,
            characteristic = 2, S_b, fn)
        G1_bus6500 = Gen5_bus_6500(; V_b = 300000.0, v_0 = V.V6500, angle_0 = V.A6500, P_0 = M.P6500_1,
            Q_0 = M.Q6500_1, S_b, fn)
        G2_bus6500 = Gen5_bus_6500(; V_b = 300000.0, v_0 = V.V6500, angle_0 = V.A6500, P_0 = M.P6500_2,
            Q_0 = M.Q6500_2, S_b, fn)
        G3_bus6500 = Gen5_bus_6500(; V_b = 300000.0, v_0 = V.V6500, angle_0 = V.A6500, P_0 = M.P6500_3,
            Q_0 = M.Q6500_3, S_b, fn)
        G4_bus6500 = Gen5_bus_6500(; V_b = 300000.0, v_0 = V.V6500, angle_0 = V.A6500, P_0 = M.P6500_4,
            Q_0 = M.Q6500_4, S_b, fn)
        bus_5100 = BusExt(; np = 2, nn = 4, v_0 = V.V5100, angle_0 = V.A5100, V_b = 300000.0, S_b, fn)
        line_5100_6500 = PwLine(; R = 0.080000, X = 0.900000, G = 0.0, B = 0.060000*0.5, S_b, fn)
        G1_bus5100 = Gen5_bus_5100(; V_b = 300000.0, v_0 = V.V5100, angle_0 = V.A5100, P_0 = M.P5100_1,
            Q_0 = M.Q5100_1, S_b, fn)
        Load_bus5100 = Load(; V_b = 300000.0, v_0 = V.V5100, angle_0 = V.A5100, P_0 = L.PL5100_1, Q_0 = L.QL5100_1,
            characteristic = 2, S_b, fn)
        line_5100_5500 = PwLine(; R = 0.027000, X = 0.260000, G = 0.0, B = 0.044000*0.5, S_b, fn)
        bus_5101 = BusExt(; nn = 2, np = 4, v_0 = V.V5101, angle_0 = V.A5101, V_b = 420000.0, S_b, fn)
        line_3359_5101_2 = PwLine(; R = 0.020000, X = 0.220000, G = 0.0, B = 0.060000*0.5, S_b, fn)
        line_3359_5101_1 = PwLine(; R = 0.016000, X = 0.260000, G = 0.0, B = 0.090000*0.5, S_b, fn)
        G1_bus3359 = Gen4_bus_3359(; V_b = 420000.0, v_0 = V.V3359, angle_0 = V.A3359, P_0 = M.P3359_1,
            Q_0 = M.Q3359_1, S_b, fn)
        G2_bus3359 = Gen4_bus_3359(; V_b = 420000.0, v_0 = V.V3359, angle_0 = V.A3359, P_0 = M.P3359_2,
            Q_0 = M.Q3359_2, S_b, fn)
        G3_bus3359 = Gen4_bus_3359(; V_b = 420000.0, v_0 = V.V3359, angle_0 = V.A3359, P_0 = M.P3359_3,
            Q_0 = M.Q3359_3, S_b, fn)
        G4_bus3359 = Gen4_bus_3359(; V_b = 420000.0, v_0 = V.V3359, angle_0 = V.A3359, P_0 = M.P3359_4,
            Q_0 = M.Q3359_4, S_b, fn)
        G5_bus3359 = Gen4_bus_3359(; V_b = 420000.0, v_0 = V.V3359, angle_0 = V.A3359, P_0 = M.P3359_5,
            Q_0 = M.Q3359_5, S_b, fn)
        G6_bus3359 = Gen4_bus_3359(; V_b = 420000.0, v_0 = V.V3359, angle_0 = V.A3359, P_0 = M.P3359_6,
            Q_0 = M.Q3359_6, S_b, fn)
        line_5101_5103 = PwLine(; R = 0.010000, X = 0.140000, G = 0.0, B = 0.040000*0.5, S_b, fn)
        line_5101_5102 = PwLine(; R = 0.008000, X = 0.100000, G = 0.0, B = 0.090000*0.5, S_b, fn)
        line_5101_5501 = PwLine(; R = 0.010000, X = 0.150000, G = 0.0, B = 0.550000*0.5, S_b, fn)
        bus_5103 = BusExt(; nn = 1, np = 3, v_0 = V.V5103, angle_0 = V.A5103, V_b = 420000.0, S_b, fn)
        line_5103_5304_2 = PwLine(; R = 0.013000, X = 0.200000, G = 0.0, B = 0.060000*0.5, S_b, fn)
        line_5103_5304_1 = PwLine(; R = 0.020000, X = 0.250000, G = 0.0, B = 0.070000*0.5, t1 = 2.0, S_b, fn)
        line_5102_5103 = PwLine(; R = 0.004000, X = 0.070000, G = 0.0, B = 0.030000*0.5, S_b, fn)
        bus_5304 = BusExt(; np = 3, nn = 3, v_0 = V.V5304, angle_0 = V.A5304, V_b = 420000.0, S_b, fn)
        bus_5102 = BusExt(; nn = 3, np = 1, v_0 = V.V5102, angle_0 = V.A5102, V_b = 420000.0, S_b, fn)
        line_5102_5304 = PwLine(; R = 0.017000, X = 0.240000, G = 0.0, B = 0.070000*0.5, S_b, fn)
        line_5102_6001 = PwLine(; R = 0.030000, X = 0.460000, G = 0.0, B = 0.130000*0.5, S_b, fn)
        bus_5305 = BusExt(; np = 1, nn = 2, v_0 = V.V5305, angle_0 = V.A5305, V_b = 420000.0, S_b, fn)
        line_5304_5305_1 = PwLine(; R = 0.010000, X = 0.150000, G = 0.0, B = 0.050000*0.5, S_b, fn)
        line_5304_5305_2 = PwLine(; R = 0.013000, X = 0.017000, G = 0.0, B = 0.040000*0.5, S_b, fn)
        line_5301_5304 = PwLine(; R = 0.010000, X = 0.200000, G = 0.0, B = 0.060000*0.5, S_b, fn)
        bus_5301 = BusExt(; nn = 3, v_0 = V.V5301, angle_0 = V.A5301, V_b = 420000.0, np = 1, S_b, fn)
        line_5301_5305 = PwLine(; R = 0.007000, X = 0.120000, G = 0.0, B = 0.031000*0.5, S_b, fn)
        line_5301_6001 = PwLine(; R = 0.013000, X = 0.200000, G = 0.0, B = 0.050000*0.5, S_b, fn)
        bus_5300 = BusExt(; np = 6, nn = 3, v_0 = V.V5300, angle_0 = V.A5300, V_b = 300000.0, S_b, fn)
        G1_bus5300 = Gen3_bus_5300(; V_b = 300000.0, v_0 = V.V5300, angle_0 = V.A5300, P_0 = M.P5300_1,
            Q_0 = M.Q5300_1, S_b, fn)
        G2_bus5300 = Gen3_bus_5300(; V_b = 300000.0, v_0 = V.V5300, angle_0 = V.A5300, P_0 = M.P5300_2,
            Q_0 = M.Q5300_2, S_b, fn)
        Load_bus5300 = Load(; V_b = 300000.0, v_0 = V.V5300, angle_0 = V.A5300, P_0 = L.PL5300_2, Q_0 = L.QL5300_2,
            characteristic = 2, S_b, fn)
        bus_6100 = BusExt(; np = 4, nn = 5, v_0 = V.V6100, angle_0 = V.A6100, V_b = 300000.0, S_b, fn)
        line_5300_6100 = PwLine(; R = 0.021000, X = 0.220000, G = 0.0, B = 0.010000*0.5, S_b, fn)
        Load1_bus6100 = Load(; V_b = 300000.0, v_0 = V.V6100, angle_0 = V.A6100, P_0 = L.PL6100_1, Q_0 = L.QL6100_1,
            characteristic = 2, S_b, fn)
        Load2_bus6100 = Load(; V_b = 300000.0, v_0 = V.V6100, angle_0 = V.A6100, P_0 = L.PL6100_2, Q_0 = L.QL6100_2,
            characteristic = 2, S_b, fn)
        G1_bus6100 = Gen3_bus_6100(; V_b = 300000.0, v_0 = V.V6100, angle_0 = V.A6100, P_0 = M.P6100_1,
            Q_0 = M.Q6100_1, S_b, fn)
        G2_bus6100 = Gen3_bus_6100(; V_b = 300000.0, v_0 = V.V6100, angle_0 = V.A6100, P_0 = M.P6100_2,
            Q_0 = M.Q6100_2, S_b, fn)
        G4_bus6100 = Gen3_bus_6100(; V_b = 300000.0, v_0 = V.V6100, angle_0 = V.A6100, P_0 = M.P6100_4,
            Q_0 = M.Q6100_4, S_b, fn)
        G5_bus6100 = Gen3_bus_6100(; V_b = 300000.0, v_0 = V.V6100, angle_0 = V.A6100, P_0 = M.P6100_5,
            Q_0 = M.Q6100_5, S_b, fn)
        G3_bus6100 = Gen3_bus_6100(; V_b = 300000.0, v_0 = V.V6100, angle_0 = V.A6100, P_0 = M.P6100_3,
            Q_0 = M.Q6100_3, S_b, fn)
        line_6000_6100 = PwLine(; R = 0.034000, X = 0.420000, G = 0.0, B = 0.030000*0.5, S_b, fn)
        bus_6000 = BusExt(; np = 5, nn = 3, v_0 = V.V6000, angle_0 = V.A6000, V_b = 300000.0, S_b, fn)
        G1_bus6000 = Gen5_bus_6000(; V_b = 300000.0, v_0 = V.V6000, angle_0 = V.A6000, P_0 = M.P6000_1,
            Q_0 = M.Q6000_1, S_b, fn)
        line_5400_6000 = PwLine(; R = 0.033000, X = 0.360000, G = 0.0, B = 0.025000*0.5, S_b, fn)
        bus_6001 = BusExt(; nn = 3, np = 3, v_0 = V.V6001, angle_0 = V.A6001, V_b = 420000.0, S_b, fn)
        bus_5601 = BusExt(; np = 1, v_0 = V.V5601, angle_0 = V.A5601, V_b = 300000.0, nn = 1, S_b, fn)
        bus_5600 = BusExt(; nn = 4, np = 6, v_0 = V.V5600, angle_0 = V.A5600, V_b = 300000.0, S_b, fn)
        line_5600_5601 = PwLine(; R = 0.030000, X = 0.340000, G = 0.0, B = 0.020000*0.5, S_b, fn)
        line_5600_6000 = PwLine(; R = 0.020000, X = 0.200000, G = 0.0, B = 0.070000*0.5, S_b, fn)
        Load1_bus5600 = Load(; V_b = 300000.0, v_0 = V.V5600, angle_0 = V.A5600, P_0 = L.PL5600_1, Q_0 = L.QL5600_1,
            characteristic = 2, S_b, fn)
        Load2_bus5600 = Load(; V_b = 300000.0, v_0 = V.V5600, angle_0 = V.A5600, P_0 = L.PL5600_2, Q_0 = L.QL5600_2,
            characteristic = 2, S_b, fn)
        line_5600_5603 = PwLine(; R = 0.020000, X = 0.220000, G = 0.0, B = 0.020000*0.5, S_b, fn)
        bus_5620 = BusExt(; np = 1, nn = 1, v_0 = V.V5620, angle_0 = V.A5620, V_b = 300000.0, S_b, fn)
        Load_bus5620 = Load(; V_b = 300000.0, v_0 = V.V5620, angle_0 = V.A5620, P_0 = L.PL5620_1, Q_0 = L.QL5620_1,
            characteristic = 2, S_b, fn)
        line_5600_5620 = PwLine(; R = 0.000000, X = 0.010000, G = 0.0, B = 0.000000, S_b, fn)
        G1_bus5600 = Gen2_bus_5600(; V_b = 300000.0, v_0 = V.V5600, angle_0 = V.A5600, P_0 = M.P5600_1,
            Q_0 = M.Q5600_1, S_b, fn)
        G2_bus5600 = Gen2_bus_5600(; V_b = 300000.0, v_0 = V.V5600, angle_0 = V.A5600, P_0 = M.P5600_2,
            Q_0 = M.Q5600_2, S_b, fn)
        bus_5603 = BusExt(; np = 2, nn = 2, v_0 = V.V5603, angle_0 = V.A5603, V_b = 300000.0, S_b, fn)
        bus_5610 = BusExt(; np = 1, nn = 1, v_0 = V.V5610, angle_0 = V.A5610, V_b = 300000.0, S_b, fn)
        line_5603_5610 = PwLine(; R = 0.000000, X = 0.010000, G = 0.0, B = 0.000000, S_b, fn)
        Load1_bus5610 = Load(; V_b = 300000.0, v_0 = V.V5610, angle_0 = V.A5610, P_0 = L.PL5610_1, Q_0 = L.QL5610_1,
            characteristic = 2, S_b, fn)
        bus_5602 = BusExt(; nn = 1, v_0 = V.V5602, angle_0 = V.A5602, V_b = 420000.0, np = 1, S_b, fn)
        bus_5500 = BusExt(; nn = 4, np = 4, v_0 = V.V5500, angle_0 = V.A5500, V_b = 300000.0, S_b, fn)
        line_5500_5603 = PwLine(; R = 0.050000, X = 0.600000, G = 0.0, B = 0.050000*0.5, S_b, fn)
        G1_bus5500 = Gen5_bus_5500(; V_b = 300000.0, v_0 = V.V5500, angle_0 = V.A5500, P_0 = M.P5500_1,
            Q_0 = M.Q5500_1, S_b, fn)
        line_5400_5500 = PwLine(; R = 0.009000, G = 0.0, B = 0.050000*0.5, X = 0.0940000, S_b, fn)
        bus_5401 = BusExt(; nn = 1, np = 3, v_0 = V.V5401, angle_0 = V.A5401, V_b = 420000.0, S_b, fn)
        bus_5501 = BusExt(; np = 1, nn = 2, v_0 = V.V5501, angle_0 = V.A5501, V_b = 420000.0, S_b, fn)
        Load1_bus5500 = Load(; V_b = 300000.0, v_0 = V.V5500, angle_0 = V.A5500, P_0 = L.PL5500_1, Q_0 = L.QL5500_1,
            characteristic = 2, S_b, fn)
        Load2_bus5500 = Load(; V_b = 300000.0, v_0 = V.V5500, angle_0 = V.A5500, P_0 = L.PL5500_2, Q_0 = L.QL5500_2,
            characteristic = 2, S_b, fn)
        line_5401_5501 = PwLine(; R = 0.017500, X = 0.270000, G = 0.0, B = 0.080000*0.5, S_b, fn)
        bus_5400 = BusExt(; np = 3, nn = 4, v_0 = V.V5400, angle_0 = V.A5400, V_b = 300000.0, S_b, fn)
        bus_5402 = BusExt(; nn = 1, v_0 = V.V5402, angle_0 = V.A5402, V_b = 420000.0, np = 1, S_b, fn)
        line_5401_6001 = PwLine(; R = 0.006400, X = 0.100000, G = 0.0, B = 0.028000*0.5, S_b, fn)
        line_5401_5602 = PwLine(; R = 0.016000, X = 0.255000, G = 0.0, B = 0.090000*0.5, S_b, fn)
        G1_bus5400 = Gen5_bus_5400(; V_b = 300000.0, v_0 = V.V5400, angle_0 = V.A5400, P_0 = M.P5400_1,
            Q_0 = M.Q5400_1, S_b, fn)
        G2_bus5400 = Gen5_bus_5400(; V_b = 300000.0, v_0 = V.V5400, angle_0 = V.A5400, P_0 = M.P5400_2,
            Q_0 = M.Q5400_2, S_b, fn)
        Load1_bus5400 = Load(; V_b = 300000.0, v_0 = V.V5400, angle_0 = V.A5400, P_0 = L.PL5400_1, Q_0 = L.QL5400_1,
            characteristic = 2, S_b, fn)
        line_5402_6001 = PwLine(; R = 0.000700, X = 0.010000, G = 0.0, B = 0.003000*0.5, S_b, fn)
        shunt_5101_5501 = Shunt(; G = 0.02230, B = -0.97440)
        shunt_5501_5101 = Shunt(; G = -0.02160, B = 0.97440)
        shunt_5102_6001 = Shunt(; G = 0.00020, B = 0.00010)
        shunt_6001_5102 = Shunt(; G = 0.00020, B = -0.00010)
        shunt_6001_5401 = Shunt(; G = 0.00020, B = 0.00050)
        shunt_5401_6001 = Shunt(; G = -0.00020, B = -0.00050)
        shunt_5500_5603 = Shunt(; G = 0.00030, B = 0.00130)
        shunt_5603_5500 = Shunt(; G = -0.00030, B = -0.00130)
        Exch_bus8500 = Load(; V_b = 420000.0, v_0 = V.V8500, angle_0 = V.A8500, characteristic = 2, P_0 = L.PL8500_4,
            Q_0 = L.QL8500_4, S_b, fn)
        Exch_bus7000 = Load(; V_b = 420000.0, v_0 = V.V7000, angle_0 = V.A7000, characteristic = 2, P_0 = L.PL7000_6,
            Q_0 = L.QL7000_6, S_b, fn)
        Exch_bus7100 = Load(; V_b = 420000.0, v_0 = V.V7100, angle_0 = V.A7100, characteristic = 2, P_0 = L.PL7100_3,
            Q_0 = L.QL7100_3, S_b, fn)
        Exch1_bus6701 = Load(; V_b = 420000.0, characteristic = 2, v_0 = V.V6701, angle_0 = V.A6701,
            P_0 = L.PL6701_3, Q_0 = L.QL6701_3, S_b, fn)
        Exch2_bus6701 = Load(; V_b = 420000.0, characteristic = 2, v_0 = V.V6701, angle_0 = V.A6701,
            P_0 = L.PL6701_1, Q_0 = L.QL6701_1, S_b, fn)
        G4_add_bus3115 = Gen3_bus_3115(; V_b = 420000.0, v_0 = V.V3115, angle_0 = V.A3115, P_0 = M.P3115_4,
            Q_0 = M.Q3115_4, S_b, fn)
        G5_add_bus3115 = Gen3_bus_3115(; V_b = 420000.0, v_0 = V.V3115, angle_0 = V.A3115, P_0 = M.P3115_5,
            Q_0 = M.Q3115_5, S_b, fn)
        G8_add_bus3249 = Gen2_bus_3249(; v_0 = V.V3249, angle_0 = V.A3249, V_b = 420000.0, P_0 = M.P3249_8,
            Q_0 = M.Q3249_8, S_b, fn)
        G4_add_bus3300 = Gen4_bus_3300(; V_b = 420000.0, v_0 = V.V3300, angle_0 = V.A3300, P_0 = M.P3300_4,
            Q_0 = M.Q3300_4, S_b, fn)
        G5_add_bus3300 = Gen4_bus_3300(; V_b = 420000.0, v_0 = V.V3300, angle_0 = V.A3300, P_0 = M.P3300_5,
            Q_0 = M.Q3300_5, S_b, fn)
        G6_add_bus3300 = Gen4_bus_3300(; V_b = 420000.0, v_0 = V.V3300, angle_0 = V.A3300, P_0 = M.P3300_6,
            Q_0 = M.Q3300_6, S_b, fn)
        G2_add_bus5100 = Gen5_bus_5100(; V_b = 300000.0, v_0 = V.V5100, angle_0 = V.A5100, P_0 = M.P5100_2,
            Q_0 = M.Q5100_2, S_b, fn)
        G3_add_bus5300 = Gen3_bus_5300(; V_b = 300000.0, v_0 = V.V5300, angle_0 = V.A5300, P_0 = M.P5300_3,
            Q_0 = M.Q5300_3, S_b, fn)
        G4_add_bus5300 = Gen3_bus_5300(; V_b = 300000.0, v_0 = V.V5300, angle_0 = V.A5300, P_0 = M.P5300_4,
            Q_0 = M.Q5300_4, S_b, fn)
        G5_add_bus5300 = Gen3_bus_5300(; V_b = 300000.0, v_0 = V.V5300, angle_0 = V.A5300, P_0 = M.P5300_5,
            Q_0 = M.Q5300_5, S_b, fn)
        G6_add_bus5300 = Gen3_bus_5300(; V_b = 300000.0, v_0 = V.V5300, angle_0 = V.A5300, P_0 = M.P5300_6,
            Q_0 = M.Q5300_6, S_b, fn)
        G2_add_bus5500 = Gen5_bus_5500(; V_b = 300000.0, v_0 = V.V5500, angle_0 = V.A5500, P_0 = M.P5500_2,
            Q_0 = M.Q5500_2, S_b, fn)
        G3_add_bus5600 = Gen2_bus_5600(; V_b = 300000.0, v_0 = V.V5600, angle_0 = V.A5600, P_0 = M.P5600_3,
            Q_0 = M.Q5600_3, S_b, fn)
        G4_add_bus5600 = Gen2_bus_5600(; V_b = 300000.0, v_0 = V.V5600, angle_0 = V.A5600, P_0 = M.P5600_4,
            Q_0 = M.Q5600_4, S_b, fn)
        G2_add_bus6000 = Gen5_bus_6000(; V_b = 300000.0, v_0 = V.V6000, angle_0 = V.A6000, P_0 = M.P6000_2,
            Q_0 = M.Q6000_2, S_b, fn)
        G3_add_bus6000 = Gen5_bus_6000(; V_b = 300000.0, v_0 = V.V6000, angle_0 = V.A6000, P_0 = M.P6000_3,
            Q_0 = M.Q6000_3, S_b, fn)
        G4_add_bus6000 = Gen5_bus_6000(; V_b = 300000.0, v_0 = V.V6000, angle_0 = V.A6000, P_0 = M.P6000_4,
            Q_0 = M.Q6000_4, S_b, fn)
        G4_add_bus6700 = Gen3_bus_6700(; V_b = 300000.0, v_0 = V.V6700, angle_0 = V.A6700, P_0 = M.P6700_4,
            Q_0 = M.Q6700_4, S_b, fn)
        G3_add_bus6700 = Gen3_bus_6700(; V_b = 300000.0, v_0 = V.V6700, angle_0 = V.A6700, P_0 = M.P6700_3,
            Q_0 = M.Q6700_3, S_b, fn)
        twoWindingTransformer = PSSE_TwoWindingTransformer(; R = 0.005, X = 0.02, G = 0.0, B = 0.0,
            t1 = T.t1_3359_3360, t2 = T.t2_3359_3360, S_b, fn)
        twoWindingTransformer1 = PSSE_TwoWindingTransformer(; G = 0.0, B = 0.0, R = 0.02, X = 0.5,
            t1 = T.t1_3249_3701, t2 = T.t2_3249_3701, S_b, fn)
        twoWindingTransformer2 = PSSE_TwoWindingTransformer(; G = 0.0, B = 0.0, R = 0.005, X = 0.02,
            t1 = T.t1_3244_3245, t2 = T.t2_3244_3245, S_b, fn)
        twoWindingTransformer3 = PSSE_TwoWindingTransformer(; G = 0.0, B = 0.0, R = 0.005, X = 0.02,
            t1 = T.t1_6700_6701, t2 = T.t2_6700_6701, S_b, fn)
        twoWindingTransformer4 = PSSE_TwoWindingTransformer(; G = 0.0, B = 0.0, R = 0.0008, X = 0.0305,
            t1 = T.t1_5100_5101, t2 = T.t2_5100_5101, S_b, fn)
        twoWindingTransformer5 = PSSE_TwoWindingTransformer(; G = 0.0, B = 0.0, X = 0.015, R = 0.0004,
            t1 = T.t1_5500_5501, t2 = T.t2_5500_5501, S_b, fn)
        twoWindingTransformer6 = PSSE_TwoWindingTransformer(; G = 0.0, B = 0.0, R = 0.0032, X = 0.12,
            t1 = T.t1_5400_5401, t2 = T.t2_5400_5401, S_b, fn)
        twoWindingTransformer7 = PSSE_TwoWindingTransformer(; G = 0.0, B = 0.0, R = 0.0004, X = 0.015,
            t1 = T.t1_5400_5402, t2 = T.t2_5400_5402, S_b, fn)
        twoWindingTransformer8 = PSSE_TwoWindingTransformer(; G = 0.0, B = 0.0, R = 0.0008, X = 0.0305,
            t1 = T.t1_5602_5603, t2 = T.t2_5602_5603, S_b, fn)
        twoWindingTransformer9 = PSSE_TwoWindingTransformer(; G = 0.0, B = 0.0, R = 0.0016, X = 0.061,
            t1 = T.t1_5300_5301, t2 = T.t2_5300_5301, S_b, fn)
        twoWindingTransformer10 = PSSE_TwoWindingTransformer(; G = 0.0, B = 0.0, R = 0.0002, X = 0.0076,
            t1 = T.t1_5601_6001, t2 = T.t2_5601_6001, S_b, fn)
        twoWindingTransformer11 = PSSE_TwoWindingTransformer(; G = 0.0, B = 0.0, X = 0.015, R = 0.0004,
            t1 = T.t1_6000_6001, t2 = T.t2_6000_6001, S_b, fn)
    end
    eqs = Equation[
        connect(G9_bus7000.pwPin, bus_7000.n_1),
        connect(G8_bus7000.pwPin, bus_7000.n_2),
        connect(G7_bus7000.pwPin, bus_7000.n_3),
        connect(G6_bus7000.pwPin, bus_7000.n_4),
        connect(G5_bus7000.pwPin, bus_7000.n_5),
        connect(G4_bus7000.pwPin, bus_7000.n_6),
        connect(G3_bus7000.pwPin, bus_7000.n_7),
        connect(G2_bus7000.pwPin, bus_7000.n_8),
        connect(G1_bus7000.pwPin, bus_7000.n_9),
        connect(Load5_bus7000.p, bus_7000.n_10),
        connect(Load4_bus7000.p, bus_7000.n_11),
        connect(Load3_bus7000.p, bus_7000.n_12),
        connect(Load2_bus7000.p, bus_7000.n_13),
        connect(Load1_bus7000.p, bus_7000.n_14),
        connect(Load1_bus7020.p, bus_7020.n_1),
        connect(Load1_bus7010.p, bus_7010.n_1),
        connect(bus_7010.p_1, line_7000_7010.p),
        connect(bus_7020.p_1, line_7000_7020.p),
        connect(line_7000_7020.n, bus_7000.n_15),
        connect(line_7000_7010.n, bus_7000.n_16),
        connect(line_7000_7100_3.n, bus_7000.p_1),
        connect(line_7000_7100_2.n, bus_7000.p_2),
        connect(line_7000_7100_1.n, bus_7000.p_3),
        connect(line_7000_7100_3.p, bus_7100.n_1),
        connect(line_7000_7100_2.p, bus_7100.n_2),
        connect(line_7000_7100_1.p, bus_7100.n_3),
        connect(Load2_bus7100.p, bus_7100.n_4),
        connect(Load1_bus7100.p, bus_7100.n_5),
        connect(bus_7100.p_1, line_3249_7100.n),
        connect(Load3_bus3000.p, bus_3000.n_1),
        connect(Load2_bus3000.p, bus_3000.n_2),
        connect(Load1_bus3000.p, bus_3000.n_3),
        connect(G3_bus3000.pwPin, bus_3000.n_4),
        connect(G2_bus3000.pwPin, bus_3000.n_5),
        connect(G1_bus3000.pwPin, bus_3000.n_6),
        connect(line_3000_3020.n, bus_3000.n_7),
        connect(line_3000_3115.p, bus_3000.p_1),
        connect(line_3000_3245_2.p, bus_3000.p_2),
        connect(line_3000_3245_1.p, bus_3000.p_3),
        connect(line_3000_3300_2.n, bus_3000.p_4),
        connect(line_3000_3300_1.n, bus_3000.p_5),
        connect(Load_bus3020.p, bus_3020.n_1),
        connect(line_3000_3300_2.p, bus_3300.n_1),
        connect(line_3000_3300_1.p, bus_3300.n_2),
        connect(G1_bus3300.pwPin, bus_3300.n_3),
        connect(Load2_bus3300.p, bus_3300.n_4),
        connect(Load1_bus3300.p, bus_3300.n_5),
        connect(G3_bus3300.pwPin, bus_3300.p_1),
        connect(G2_bus3300.pwPin, bus_3300.p_2),
        connect(line_3200_3300.p, bus_3300.p_3),
        connect(line_3100_3200_1.p, bus_3200.n_1),
        connect(line_3100_3200_2.p, bus_3200.n_2),
        connect(line_3100_3200_3.p, bus_3200.n_3),
        connect(line_3200_3300.n, bus_3200.n_4),
        connect(line_3300_8500_2.n, bus_3300.p_4),
        connect(line_3300_8500_1.n, bus_3300.p_5),
        connect(line_3300_8500_2.p, bus_8500.n_1),
        connect(line_3300_8500_1.p, bus_8500.n_2),
        connect(G2_bus8500.pwPin, bus_8500.n_3),
        connect(G1_bus8500.pwPin, bus_8500.n_4),
        connect(Load3_bus8500.p, bus_8500.n_5),
        connect(Load2_bus8500.p, bus_8500.n_6),
        connect(Load1_bus8500.p, bus_8500.n_7),
        connect(line_8500_8700.n, bus_8500.n_8),
        connect(line_3200_8500.p, bus_8500.p_1),
        connect(line_3359_8500_1.p, bus_8500.p_2),
        connect(line_3359_8500_2.p, bus_8500.p_3),
        connect(G6_bus8500.pwPin, bus_8500.p_4),
        connect(G5_bus8500.pwPin, bus_8500.p_5),
        connect(G4_bus8500.pwPin, bus_8500.p_6),
        connect(G3_bus8500.pwPin, bus_8500.p_7),
        connect(line_8500_8700.p, bus_8700.p_1),
        connect(Load_bus8700.p, bus_8700.n_1),
        connect(line_8500_8600.n, bus_8500.p_8),
        connect(line_8500_8600.p, bus_8600.n_1),
        connect(Load_bus8600.p, bus_8600.p_1),
        connect(line_3200_8500.n, bus_3200.n_5),
        connect(line_3200_3359.p, bus_3200.p_1),
        connect(bus_3100.p_1, line_3100_3359_2.p),
        connect(bus_3100.p_2, line_3100_3359_1.p),
        connect(line_3100_3359_2.n, bus_3359.n_1),
        connect(line_3100_3359_1.n, bus_3359.n_2),
        connect(Load4_bus3359.p, bus_3359.n_3),
        connect(Load3_bus3359.p, bus_3359.n_4),
        connect(Load2_bus3359.p, bus_3359.n_5),
        connect(Load1_bus3359.p, bus_3359.n_6),
        connect(line_3200_3359.n, bus_3359.n_7),
        connect(line_3359_8500_1.n, bus_3359.n_8),
        connect(line_3359_8500_2.n, bus_3359.n_9),
        connect(Load_bus3360.p, bus_3360.p_1),
        connect(line_3100_3249.p, bus_3100.n_1),
        connect(line_3100_3115.p, bus_3100.n_2),
        connect(Load_bus3100.p, bus_3100.n_3),
        connect(line_3100_3200_3.n, bus_3100.n_4),
        connect(line_3100_3200_2.n, bus_3100.n_5),
        connect(line_3100_3200_1.n, bus_3100.n_6),
        connect(line_3115_6701.n, bus_6701.n_1),
        connect(bus_3701.p_1, line_3701_6700.n),
        connect(bus_3244.p_1, line_3244_6500.n),
        connect(bus_6700.p_1, line_6500_6700_2.n),
        connect(line_6500_6700_1.n, bus_6700.p_2),
        connect(line_3244_6500.p, bus_6500.n_1),
        connect(Load3_bus6500.p, bus_6500.n_2),
        connect(Load2_bus6500.p, bus_6500.n_3),
        connect(Load1_bus6500.p, bus_6500.n_4),
        connect(line_6500_6700_2.p, bus_6500.n_5),
        connect(line_6500_6700_1.p, bus_6500.n_6),
        connect(bus_5100.p_1, line_5100_5500.n),
        connect(line_3359_5101_2.n, bus_3359.p_1),
        connect(line_3359_5101_1.n, bus_3359.p_2),
        connect(G6_bus3359.pwPin, bus_3359.p_3),
        connect(G5_bus3359.pwPin, bus_3359.p_4),
        connect(G4_bus3359.pwPin, bus_3359.p_5),
        connect(G3_bus3359.pwPin, bus_3359.p_6),
        connect(G2_bus3359.pwPin, bus_3359.p_7),
        connect(G1_bus3359.pwPin, bus_3359.p_8),
        connect(line_3359_5101_2.p, bus_5101.n_1),
        connect(line_3359_5101_1.p, bus_5101.n_2),
        connect(bus_5101.p_1, line_5101_5501.n),
        connect(bus_5101.p_2, line_5101_5102.n),
        connect(bus_5101.p_3, line_5101_5103.n),
        connect(line_5101_5103.p, bus_5103.n_1),
        connect(line_5102_5103.n, bus_5103.p_1),
        connect(line_5103_5304_2.n, bus_5103.p_2),
        connect(line_5103_5304_1.n, bus_5103.p_3),
        connect(line_5102_5304.p, bus_5304.n_1),
        connect(line_5103_5304_2.p, bus_5304.n_2),
        connect(line_5103_5304_1.p, bus_5304.n_3),
        connect(line_5101_5102.p, bus_5102.n_1),
        connect(bus_5102.n_2, line_5102_5103.p),
        connect(line_5102_5304.n, bus_5102.n_3),
        connect(bus_5102.p_1, line_5102_6001.n),
        connect(line_5301_5304.n, bus_5304.p_1),
        connect(line_5304_5305_2.n, bus_5304.p_2),
        connect(line_5304_5305_1.n, bus_5304.p_3),
        connect(line_5304_5305_2.p, bus_5305.n_1),
        connect(line_5304_5305_1.p, bus_5305.n_2),
        connect(bus_5305.p_1, line_5301_5305.p),
        connect(line_5301_6001.p, bus_5301.n_1),
        connect(line_5301_5304.p, bus_5301.n_2),
        connect(line_5301_5305.n, bus_5301.n_3),
        connect(line_5300_6100.p, bus_5300.p_1),
        connect(line_6000_6100.p, bus_6100.n_1),
        connect(line_5600_5603.n, bus_5600.n_1),
        connect(Load2_bus5600.p, bus_5600.n_2),
        connect(Load1_bus5600.p, bus_5600.n_3),
        connect(line_5600_6000.n, bus_5600.n_4),
        connect(bus_5601.p_1, line_5600_5601.p),
        connect(bus_5620.p_1, line_5600_5620.n),
        connect(line_5603_5610.n, bus_5610.n_1),
        connect(bus_5603.p_1, line_5603_5610.p),
        connect(bus_5610.p_1, Load1_bus5610.p),
        connect(line_5500_5603.p, bus_5603.n_1),
        connect(Load2_bus5500.p, bus_5500.n_1),
        connect(Load1_bus5500.p, bus_5500.n_2),
        connect(line_5100_5500.p, bus_5500.n_3),
        connect(line_5101_5501.p, bus_5501.n_1),
        connect(bus_5501.p_1, line_5401_5501.n),
        connect(line_5401_5501.p, bus_5401.n_1),
        connect(line_5401_6001.p, bus_6001.n_1),
        connect(line_5401_5602.n, bus_5401.p_1),
        connect(line_5401_5602.p, bus_5602.n_1),
        connect(line_5402_6001.p, bus_5402.n_1),
        connect(line_5102_6001.p, bus_6001.n_2),
        connect(bus_6001.n_3, line_5301_6001.n),
        connect(line_5600_6000.p, bus_6000.p_1),
        connect(bus_6000.p_2, line_6000_6100.n),
        connect(line_5101_5501.n, shunt_5101_5501.p),
        connect(line_5101_5501.p, shunt_5501_5101.p),
        connect(line_5102_6001.n, shunt_5102_6001.p),
        connect(line_5102_6001.p, shunt_6001_5102.p),
        connect(shunt_5401_6001.p, line_5401_6001.n),
        connect(line_5401_6001.p, shunt_6001_5401.p),
        connect(shunt_5500_5603.p, line_5500_5603.n),
        connect(line_5500_5603.p, shunt_5603_5500.p),
        connect(line_5600_5603.p, bus_5603.p_2),
        connect(G3_bus7100.p, bus_7100.n_6),
        connect(G2_bus7100.p, bus_7100.n_7),
        connect(G1_bus7100.p, bus_7100.n_8),
        connect(G7_bus3249.p, bus_3249.p_1),
        connect(G6_bus3249.p, bus_3249.p_2),
        connect(G5_bus3249.p, bus_3249.p_3),
        connect(G4_bus3249.p, bus_3249.p_4),
        connect(G1_bus6700.p, bus_6700.n_1),
        connect(Load1_bus6700.p, bus_6700.n_2),
        connect(line_3701_6700.p, bus_6700.n_3),
        connect(G2_bus6700.p, bus_6700.p_3),
        connect(bus_5401.p_2, line_5401_6001.n),
        connect(G2_bus5400.p, bus_5400.p_1),
        connect(line_5400_6000.n, bus_5400.p_2),
        connect(G2_bus5300.p, bus_5300.p_2),
        connect(G1_bus6100.p, bus_6100.n_2),
        connect(Load2_bus6100.p, bus_6100.n_3),
        connect(Load1_bus6100.p, bus_6100.n_4),
        connect(line_5300_6100.n, bus_6100.n_5),
        connect(G5_bus6100.p, bus_6100.p_1),
        connect(G4_bus6100.p, bus_6100.p_2),
        connect(G3_bus6100.p, bus_6100.p_3),
        connect(G2_bus6100.p, bus_6100.p_4),
        connect(Load_bus5620.p, bus_5620.n_1),
        connect(line_3115_7100.p, bus_7100.p_2),
        connect(G4_bus6500.p, bus_6500.p_1),
        connect(G3_bus6500.p, bus_6500.p_2),
        connect(G2_bus6500.p, bus_6500.p_3),
        connect(G1_bus6500.p, bus_6500.p_4),
        connect(line_5100_6500.n, bus_6500.p_5),
        connect(line_3115_3245.p, bus_3115.p_1),
        connect(line_3115_6701.p, bus_3115.p_2),
        connect(line_3115_3249.n, bus_3115.p_3),
        connect(line_3100_3115.n, bus_3115.p_4),
        connect(line_5400_6000.p, bus_6000.n_1),
        connect(G1_bus6000.p, bus_6000.n_2),
        connect(line_5100_6500.p, bus_5100.n_1),
        connect(G1_bus5100.p, bus_5100.n_2),
        connect(Load_bus5100.p, bus_5100.n_3),
        connect(line_3000_3020.p, bus_3020.p_1),
        connect(line_5400_5500.p, bus_5400.n_1),
        connect(G1_bus5400.p, bus_5400.n_2),
        connect(Load1_bus5400.p, bus_5400.n_3),
        connect(G1_bus5300.p, bus_5300.n_1),
        connect(Load_bus5300.p, bus_5300.n_2),
        connect(line_3249_7100.p, bus_3249.n_1),
        connect(G3_bus3249.p, bus_3249.n_2),
        connect(G2_bus3249.p, bus_3249.n_3),
        connect(G1_bus3249.p, bus_3249.n_4),
        connect(Load_bus3249.p, bus_3249.n_5),
        connect(line_3115_3249.p, bus_3249.n_6),
        connect(line_3100_3249.n, bus_3249.n_7),
        connect(line_3000_3245_2.n, bus_3245.n_1),
        connect(line_3000_3245_1.n, bus_3245.n_2),
        connect(line_3115_3245.n, bus_3245.n_3),
        connect(line_5600_5620.p, bus_5600.p_1),
        connect(G2_bus5600.p, bus_5600.p_2),
        connect(G1_bus5600.p, bus_5600.p_3),
        connect(line_5500_5603.n, bus_5500.p_1),
        connect(G1_bus5500.p, bus_5500.p_2),
        connect(line_5400_5500.n, bus_5500.p_3),
        connect(G1_bus3245.p, bus_3245.p_1),
        connect(line_5402_6001.n, bus_6001.p_1),
        connect(Exch_bus8500.p, bus_8500.n_9),
        connect(Exch_bus7000.p, bus_7000.p_4),
        connect(Exch_bus7100.p, bus_7100.p_3),
        connect(Exch1_bus6701.p, bus_6701.n_2),
        connect(Exch2_bus6701.p, bus_6701.p_1),
        connect(line_3115_7100.n, bus_3115.n_1),
        connect(Load_bus3115.p, bus_3115.n_2),
        connect(G3_bus3115.p, bus_3115.n_3),
        connect(G2_bus3115.p, bus_3115.n_4),
        connect(G1_bus3115.p, bus_3115.n_5),
        connect(line_3000_3115.n, bus_3115.n_6),
        connect(G5_add_bus3115.p, bus_3115.n_7),
        connect(G4_add_bus3115.p, bus_3115.n_8),
        connect(G8_add_bus3249.p, bus_3249.p_5),
        connect(G6_add_bus3300.pwPin, bus_3300.n_6),
        connect(G5_add_bus3300.pwPin, bus_3300.n_7),
        connect(G4_add_bus3300.pwPin, bus_3300.n_8),
        connect(G2_add_bus5100.p, bus_5100.n_4),
        connect(G3_add_bus5300.p, bus_5300.p_3),
        connect(G4_add_bus5300.p, bus_5300.p_4),
        connect(G5_add_bus5300.p, bus_5300.p_5),
        connect(G6_add_bus5300.p, bus_5300.p_6),
        connect(G2_add_bus5500.p, bus_5500.p_4),
        connect(G3_add_bus5600.p, bus_5600.p_4),
        connect(G4_add_bus5600.p, bus_5600.p_5),
        connect(line_5600_5601.n, bus_5600.p_6),
        connect(G4_add_bus6000.p, bus_6000.p_3),
        connect(G3_add_bus6000.p, bus_6000.p_4),
        connect(G2_add_bus6000.p, bus_6000.p_5),
        connect(G3_add_bus6700.p, bus_6700.p_4),
        connect(G4_add_bus6700.p, bus_6700.p_5),
        connect(twoWindingTransformer.n, bus_3360.n_1),
        connect(twoWindingTransformer.p, bus_3359.p_9),
        connect(twoWindingTransformer1.n, bus_3249.p_6),
        connect(twoWindingTransformer1.p, bus_3701.n_1),
        connect(twoWindingTransformer2.n, bus_3245.p_2),
        connect(twoWindingTransformer2.p, bus_3244.n_1),
        connect(twoWindingTransformer3.n, bus_6701.p_2),
        connect(twoWindingTransformer3.p, bus_6700.n_4),
        connect(twoWindingTransformer4.p, bus_5101.p_4),
        connect(twoWindingTransformer4.n, bus_5100.p_2),
        connect(twoWindingTransformer5.n, bus_5501.n_2),
        connect(twoWindingTransformer5.p, bus_5500.n_4),
        connect(twoWindingTransformer6.n, bus_5401.p_3),
        connect(twoWindingTransformer6.p, bus_5400.n_4),
        connect(twoWindingTransformer7.n, bus_5402.p_1),
        connect(twoWindingTransformer7.p, bus_5400.p_3),
        connect(twoWindingTransformer8.p, bus_5603.n_2),
        connect(twoWindingTransformer8.n, bus_5602.p_1),
        connect(twoWindingTransformer9.p, bus_5300.n_3),
        connect(twoWindingTransformer9.n, bus_5301.p_1),
        connect(twoWindingTransformer10.p, bus_5601.n_1),
        connect(twoWindingTransformer10.n, bus_6001.p_2),
        connect(twoWindingTransformer11.n, bus_6001.p_3),
        connect(twoWindingTransformer11.p, bus_6000.n_3),
    ]
    System(eqs, t, [], []; name, systems)
end
