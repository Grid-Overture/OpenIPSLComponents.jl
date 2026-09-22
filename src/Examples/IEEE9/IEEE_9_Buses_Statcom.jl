# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/IEEE9/IEEE_9_Buses_Statcom.mo, transcribed automatically
# (2026-09-16); reviewed by hand.
# The IEEE (WSCC) 9-bus 3-machine system with a STATCOM at the bus-8 node: three Order4 + AVRTypeII groups, three PSAT
# transformers, six lines, three `VoltageDependent` loads, `line_7_8(opening = 1, t1 = 30, t2 = 110)` whose opening is
# outside the 20 s horizon, and a fault at B9 from 3 to 3.1 s. `no_pss` grounds the STATCOM's `v_POD`.
# `gen1/2/3(gen(delta(fixed = true)))` travels in `mods`, although baseMachine already carries `delta` as an initial
# condition (F-20), so the modifier is a no-op here and is not transcribed.
# `sTATCOM3_1(S_b = SysData.S_b)` is the S_b keyword argument.
# Omitted: Modelica.Icons.Example, graphical annotations, displayPF.

@component function IEEE_9_Buses_Statcom(; name, S_b = 100e6, fn = 60)
    systems = @named begin
        twoWindingTransformer = TwoWindingTransformer(; V_b = 16500.0, Vn = 16500.0, rT = 0.0, xT = 0.0576, S_b, fn)
        line_6_4 = PwLine(; R = 0.017, X = 0.092, G = 0.0, B = 0.079, S_b, fn)
        line_4_5 = PwLine(; G = 0.0, R = 0.01, X = 0.085, B = 0.088, S_b, fn)
        lOADPQ = VoltageDependent(; V_b = 230000.0, v_0 = 0.995630859628167, angle_0 = -0.0696176932,
            P_0 = 125000000.0, Q_0 = 50000000.0, S_b, fn)
        PQ1 = VoltageDependent(; V_b = 230000.0, v_0 = 1.012654326639182, angle_0 = -0.06435727083,
            P_0 = 90000000.0, Q_0 = 30000000.0, S_b, fn)
        line_9_6 = PwLine(; G = 0.0, R = 0.039, X = 0.170, B = 0.179, S_b, fn)
        line_5_7 = PwLine(; G = 0.0, R = 0.032, X = 0.161, B = 0.153, S_b, fn)
        line_8_9 = PwLine(; G = 0.0, R = 0.0119, X = 0.1008, B = 0.1045, S_b, fn)
        twoWindingTransformer1 = TwoWindingTransformer(; V_b = 13800.0, Vn = 13800.0, rT = 0.0, xT = 0.0586, S_b, fn)
        twoWindingTransformer2 = TwoWindingTransformer(; Sn = 100000000.0, V_b = 18000.0, Vn = 18000.0, rT = 0.0,
            xT = 0.0625, S_b, fn)
        lOADPQ1 = VoltageDependent(; v_0 = 1.015882581760390, angle_0 = 0.01269796844, V_b = 230000.0,
            P_0 = 100000000.0, Q_0 = 35000000.0, S_b, fn)
        sTATCOM3_1 = STATCOM(; Q_0 = 128730.182132440, Tr = 0.1, Sn = 100000000.0, fn = 60, v_0 = 1.015882581760390,
            V_b = 230000.0, Vn = 230000.0, S_b, angle_0 = 0.011660880329004, i_Min = -0.8, Kr = 100.0, i_Max = 1.2)
        B2 = Bus(; S_b, fn)
        B7 = Bus(; S_b, fn)
        B8 = Bus(; v_0 = 1.025, S_b, fn)
        B9 = Bus(; S_b, fn)
        B3 = Bus(; S_b, fn)
        B6 = Bus(; S_b, fn)
        B5 = Bus(; S_b, fn)
        B4 = Bus(; S_b, fn)
        B1 = Bus(; S_b, fn)
        line_7_8 = PwLine(; R = 0.0085, X = 0.072, G = 0.0, B = 0.0745, t2 = 110.0, t1 = 30.0, opening = 1, S_b, fn)
        gen1 = IEEE9_Gen1(; V_b = 18000.0, v_0 = 1.025, vref0 = 1.120103884682511, vf0 = 1.789323314329606,
            height_1 = 0.05, tstart_1 = 2.0, angle_0 = 0.161966652912444, P_0 = 163000000.0, Q_0 = 6653656.0198189,
            refdisturb_1 = false, S_b, fn)
        gen2 = IEEE9_Gen2(; V_b = 13800.0, v_0 = 1.025, height_2 = 0.05, tstart_2 = 2.0, refdisturb_2 = false,
            vref0 = 1.097573933623472, vf0 = 1.402994304406186, P_0 = 85000000.0, Q_0 = -10859708.8920594,
            angle_0 = 0.08141611894, S_b, fn)
        gen3 = IEEE9_Gen3(; v_0 = 1.040000000000000, angle_0 = 0.0, height_3 = 0.05, tstart_3 = 2.0,
            refdisturb_3 = false, V_b = 16500.0, vref0 = 1.095242742681042, vf0 = 1.082148046273888,
            P_0 = 71641021.4993680, Q_0 = 27045927.9594234, S_b, fn)
        pwFault2 = PwFault(; X = 0.01, R = 0.01, t1 = 3.0, t2 = 3.1)
        no_pss = Constant(; k = 0.0)
    end
    eqs = Equation[
        connect(line_5_7.n, B7.p),
        connect(twoWindingTransformer1.n, B9.p),
        connect(line_9_6.n, B9.p),
        connect(twoWindingTransformer1.p, B3.p),
        connect(line_6_4.n, B6.p),
        connect(B6.p, line_9_6.p),
        connect(line_4_5.n, B5.p),
        connect(line_5_7.p, B5.p),
        connect(twoWindingTransformer.p, B1.p),
        connect(B7.p, line_7_8.p),
        connect(line_7_8.n, B8.p),
        connect(B2.p, gen1.pwPin),
        connect(B2.p, twoWindingTransformer2.p),
        connect(twoWindingTransformer2.n, B7.p),
        connect(gen2.pwPin, B3.p),
        connect(lOADPQ.p, B5.p),
        connect(line_4_5.p, B4.p),
        connect(line_6_4.p, B4.p),
        connect(PQ1.p, B6.p),
        connect(lOADPQ1.p, B8.p),
        connect(B4.p, twoWindingTransformer.n),
        connect(gen3.pwPin, B1.p),
        connect(line_8_9.n, B9.p),
        connect(B8.p, line_8_9.p),
        connect(sTATCOM3_1.p, line_8_9.p),
        connect(B9.p, pwFault2.p),
        sTATCOM3_1.v_POD ~ no_pss.y,   # connect(no_pss.y, sTATCOM3_1.v_POD)
    ]
    System(eqs, t, [], []; name, systems)
end
