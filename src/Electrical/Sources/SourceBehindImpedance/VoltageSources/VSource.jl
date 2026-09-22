# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Sources/SourceBehindImpedance/VoltageSources/VSource.mo (extends BaseClasses/baseVoltageSource.mo)
# Constant voltage source behind an impedance: `extend` over baseVoltageSource.jl, the internal phasor held at its
# initial value. Omitted: graphical annotations.

@component function VSource(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0, M_b = S_b,
        R_a = 1e-3, X_d = 0.2)
    @named base = baseVoltageSource(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, R_a, X_d)
    @unpack E, delta, Er, Ei, E0, delta0, Er0, Ei0 = base
    eqs = Equation[
        E ~ E0,
        delta ~ delta0,
        Er ~ Er0,
        Ei ~ Ei0,
    ]
    extend(System(eqs, t, [], []; name), base)
end
