# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/Tutorial/Example_4/BaseModels/GeneratingUnits/InfiniteBus.mo
# (extends Interfaces/Generator.mo). A GENCLS with H = 5, X_d = 0.2 on the unit's own power-flow data.
# Named `Example_4_InfiniteBus` (the name table): the leaf name collides with `Buses.InfiniteBus`.
# Omitted: graphical annotations, displayPF.

@component function Example_4_InfiniteBus(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0)
    @named base = Generator(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack pwPin = base
    systems = @named begin
        gENCLS = GENCLS(; P_0, Q_0, v_0, angle_0, M_b = 100000000.0, H = 5.0, D = 0.0, R_a = 0.0, X_d = 0.2, S_b, fn)
    end
    eqs = Equation[connect(gENCLS.p, pwPin)]
    extend(System(eqs, t, [], []; name, systems), base)
end
