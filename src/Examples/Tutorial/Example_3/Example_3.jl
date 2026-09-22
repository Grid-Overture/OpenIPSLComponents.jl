# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_3/Example_3.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# `inner SystemBase SysData(fn = 60)` is the pair of keyword arguments S_b (SystemBase default 100e6) and fn, passed
# to every component that declares `outer SysData`. `fault_events = false` builds the system with the fault switching
# disabled (see PwFault.jl); it is not in the .mo and exists for examples/example_3_segmented.jl.
@component function Example_3(; name, S_b = 100e6, fn = 60, fault_events = true)
    systems = @named begin
        twoWindingTransformer = TwoWindingTransformer(; V_b = 16500.0, Vn = 16500.0, rT = 0.0, xT = 0.0576, S_b, fn)
        line_6_4 = PwLine(; R = 0.017, X = 0.092, G = 0.0, B = 0.079, S_b, fn)
        line_4_5 = PwLine(; G = 0.0, R = 0.01, X = 0.085, B = 0.088, S_b, fn)
        lOADPQ = VoltageDependent(; V_b = 230000.0, angle_0 = -0.069617784448685, v_0 = 0.995630859628167, Sn = 100000000.0, P_0 = 1.25*S_b, Q_0 = 0.5*S_b, S_b, fn)
        PQ1 = VoltageDependent(; V_b = 230000.0, P_0 = 0.9*S_b, Q_0 = 0.3*S_b, angle_0 = -0.064357203188830, v_0 = 1.012654326639182, Sn = 100000000.0, S_b, fn)
        line_9_6 = PwLine(; G = 0.0, R = 0.039, X = 0.170, B = 0.179, S_b, fn)
        line_5_7 = PwLine(; G = 0.0, R = 0.032, X = 0.161, B = 0.153, S_b, fn)
        line_8_9 = PwLine(; G = 0.0, R = 0.0119, X = 0.1008, B = 0.1045, S_b, fn)
        twoWindingTransformer1 = TwoWindingTransformer(; V_b = 13800.0, Vn = 13800.0, rT = 0.0, xT = 0.0586, S_b, fn)
        twoWindingTransformer2 = TwoWindingTransformer(; Sn = 100000000.0, V_b = 18000.0, Vn = 18000.0, rT = 0.0, xT = 0.0625, S_b, fn)
        lOADPQ1 = VoltageDependent(; V_b = 230000.0, P_0 = 1*S_b, Q_0 = 0.35*S_b, angle_0 = 0.012697901381466, v_0 = 1.015882581760390, Sn = 100000000.0, S_b, fn)
        B2 = Bus(; v_0 = 1.025, angle_0 = 0.161966652912444, S_b, fn)
        B7 = Bus(; S_b, fn)
        B8 = Bus(; S_b, fn)
        B9 = Bus(; S_b, fn)
        B3 = Bus(; S_b, fn)
        B6 = Bus(; S_b, fn)
        B5 = Bus(; S_b, fn)
        B4 = Bus(; S_b, fn)
        B1 = Bus(; angle_0 = 0.0, S_b, fn)
        gen1 = Gen1(; V_b = 18000.0, v_0 = 1.025, height = 0.05, tstart = 2.0, refdisturb = false, angle_0 = 0.161966652912444, vref0 = 1.120103884682511, P_0 = 1.629999999999999*S_b, Q_0 = 0.066536560198189*S_b, vf0 = 1.789323314329606, S_b, fn)
        gen2 = Gen2(; V_b = 13800.0, v_0 = 1.025, angle_0 = 0.081415270775183, vref0 = 1.097573933623472, P_0 = 0.850000000000000*S_b, Q_0 = -0.108597088920594*S_b, vf0 = 1.402994304406186, height = 0.05, tstart = 2.0, refdisturb = false, S_b, fn)
        gen3 = Gen3(; v_0 = 1.040000000000000, angle_0 = 0.0, V_b = 16500.0, vref0 = 1.095242742681042, Q_0 = 0.270459279594234*S_b, vf0 = 1.082148046273888, P_0 = 0.716410214993680*S_b, height = 0.05, tstart = 2.0, refdisturb = false, S_b, fn)
        pwFault2 = PwFault(; X = 0.01, t1 = 3.0, t2 = 3.1, R = 0.01, events = fault_events)
        pwLine2Openings = PwLine(; R = 0.0085, X = 0.072, G = 0.0, B = 0.0745, t1 = 30.0, t2 = 35.0, opening = 1, S_b, fn)
    end
    eqs = Equation[
        connect(line_5_7.n, B7.p),
        connect(twoWindingTransformer1.n, B9.p),
        connect(line_9_6.n, B9.p),
        connect(twoWindingTransformer1.p, B3.p),
        connect(B6.p, line_9_6.p),
        connect(line_5_7.p, B5.p),
        connect(B2.p, gen1.pwPin),
        connect(B2.p, twoWindingTransformer2.p),
        connect(twoWindingTransformer2.n, B7.p),
        connect(gen2.pwPin, B3.p),
        connect(lOADPQ.p, B5.p),
        connect(B4.p, twoWindingTransformer.n),
        connect(B8.p, lOADPQ1.p),
        connect(line_8_9.p, B9.p),
        connect(B8.p, line_8_9.n),
        connect(B9.p, pwFault2.p),
        connect(B7.p, pwLine2Openings.p),
        connect(B8.p, pwLine2Openings.n),
        connect(PQ1.p, B6.p),
        connect(gen3.pwPin, B1.p),
        connect(twoWindingTransformer.p, B1.p),
        connect(line_6_4.p, B4.p),
        connect(line_6_4.n, B6.p),
        connect(line_4_5.n, B5.p),
        connect(line_4_5.p, B4.p),
    ]
    System(eqs, t, [], []; name, systems)
end
