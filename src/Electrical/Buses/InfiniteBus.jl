# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Buses/InfiniteBus.mo (extends Electrical/Essentials/pfComponent.mo)
# PSAT infinite bus: fixes the pin voltage at v_0, angle_0 and reports the absorbed P, Q in W/var. `enableP_0`,
# `enableQ_0`, `enablefn`, `enableV_b` are false: those parameters keep their defaults (accepted as keyword arguments
# for uniformity). Omitted: displayPF, graphical annotations.

@component function InfiniteBus(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack S_b, v_0, angle_0 = base
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        P(t), [description = "Active power absorbed by the infinite bus (W)"]
        Q(t), [description = "Reactive power absorbed by the infinite bus (var)"]
    end
    eqs = Equation[
        p.vr ~ v_0 * cos(angle_0),
        p.vi ~ v_0 * sin(angle_0),
        P ~ -(p.vr * p.ir + p.vi * p.ii) * S_b,
        Q ~ -(p.vi * p.ir - p.vr * p.ii) * S_b,
    ]
    extend(System(eqs, t, vars, []; name, systems), base)
end
