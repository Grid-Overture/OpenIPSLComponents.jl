# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/KundurSMIB/SMIB_Partial.mo (partial), transcribed automatically
# (2026-09-16); reviewed by hand. Named `KundurSMIB_Partial` (JULIA_NAMES): `SMIB_Partial` would read as the test base.
# The network of the Kundur single-machine-infinite-bus case: three buses, a PSAT transformer of 2220 MVA, two
# parallel lines to the infinite bus, and a bolted fault at line_1.p (= B2) from 0.5 to 0.57 s. `line_2` carries
# `opening = 1, t1 = 0.57, t2 = 100`, so clearing the fault **trips it permanently** within the 10 s run.
# `inner SysData(S_b = 2220e6, fn = 60)` is the keyword arguments S_b, fn; the protected `S_b` alias of the .mo is
# that same keyword argument in the children.
# Omitted: graphical annotations, displayPF.
@component function KundurSMIB_Partial(; name, S_b = 2220e6, fn = 60)
    systems = @named begin
        B1 = Bus(; S_b, fn)
        B2 = Bus(; S_b, fn)
        B3 = Bus(; S_b, fn)
        transformer = TwoWindingTransformer(; Sn = 2220000000.0, xT = 0.15, rT = 0.0, V_b = 400000.0,
            Vn = 400000.0, S_b, fn)
        line_1 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.5, S_b, fn)
        infinite_bus = InfiniteBus(; angle_0 = 0.0, v_0 = 0.900810000000000, S_b, fn)
        fault = PwFault(; R = 0.0, t1 = 0.5, t2 = 0.57, X = 1e-5)
        line_2 = PwLine(; R = 0.0, G = 0.0, B = 0.0, X = 0.93, t1 = 0.57, t2 = 100.0, opening = 1, S_b, fn)
    end
    eqs = Equation[
        connect(B1.p, transformer.p),
        connect(transformer.n, B2.p),
        connect(B2.p, line_1.p),
        connect(line_1.n, B3.p),
        connect(B3.p, infinite_bus.p),
        connect(fault.p, line_1.p),
        connect(line_2.n, B3.p),
        connect(line_2.p, line_1.p),
    ]
    System(eqs, t, [], []; name, systems)
end
