# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Sources/CurrentSourceReImInput.mo (extends Electrical/Essentials/pfComponent.mo)
# Ideal current source with the real and imaginary parts of the current phasor as inputs (plain variables iRe, iIm).
# `extend` over pfComponent (enableS_b = true; the other power-flow parameters keep their defaults). Omitted:
# graphical annotations.

@component function CurrentSourceReImInput(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack S_b = base
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        angle(t), [description = "Bus voltage angle (rad)"]
        v(t), [description = "Bus voltage magnitude (pu)"]
        P(t), [description = "Active power absorbed or provided by the source (W)"]
        Q(t), [description = "Reactive power absorbed or provided by the source (var)"]
        iRe(t), [description = "Real part of the current phasor (input)"]
        iIm(t), [description = "Imaginary part of the current phasor (input)"]
    end
    eqs = Equation[
        p.ir ~ iRe,
        p.ii ~ iIm,
        v ~ sqrt(p.vr^2 + p.vi^2),
        angle ~ atan(p.vi, p.vr),   # atan2
        P ~ -(p.vr * p.ir + p.vi * p.ii) * S_b,
        Q ~ -(p.vr * p.ii - p.vi * p.ir) * S_b,
    ]
    extend(System(eqs, t, vars, []; name, systems), base)
end
