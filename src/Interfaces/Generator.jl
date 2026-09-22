# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Interfaces/Generator.mo (partial; extends Electrical/Essentials/pfComponent.mo)
# Interface for a generator: the pin `pwPin` and the injected P, Q in W/var. `enableV_b = false` only removes V_b
# from the Dialog; the parameter still exists and a modifier may set it (Example_3 gives each generation group its
# V_b), so it is a keyword argument like the rest (batch 3; batch 2 had left it out).
# Omitted: graphical annotations. Children `@unpack pwPin, P, Q = base`.

@component function Generator(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack S_b = base
    systems = @named begin
        pwPin = PwPin()
    end
    vars = @variables begin
        P(t), [description = "Active power (W)"]
        Q(t), [description = "Reactive power (var)"]
    end
    eqs = Equation[
        -P ~ (pwPin.vr * pwPin.ir + pwPin.vi * pwPin.ii) * S_b,
        -Q ~ (pwPin.vi * pwPin.ir - pwPin.vr * pwPin.ii) * S_b,
    ]
    extend(System(eqs, t, vars, []; name, systems), base)
end
