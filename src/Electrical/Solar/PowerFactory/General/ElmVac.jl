# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/General/ElmVac.mo (extends Electrical/Essentials/pfComponent.mo:
# enablefn = enableS_b = enableangle_0 = enablev_0 = true; V_b, P_0, Q_0 accepted and inert)
# Blocks: none. The PowerFactory controllable voltage source: inputs `f0` (frequency, **per unit of 50 Hz**: the
# .mo integrates `der(phiu) = 2*fn*pi*(f0 - fn/50)`, sic, copied literally) and `v` (magnitude; its
# `start = v_0, fixed = true` on an input is inert), `initial equation phiu = angle_0`. The pin voltage is imposed,
# the pin current is whatever the connected component draws (an ideal source, family of VoltageSourceReImInput).
# Omitted: displayPF, graphical annotations.

@component function ElmVac(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0))
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack fn, angle_0 = base
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        P(t), [description = "Active power (pu)"]
        Q(t), [description = "Reactive power (pu)"]
        phiu(t), [description = "Voltage angle (rad)"]
        f0(t), [description = "Frequency input (pu of 50 Hz)"]
        v(t), [description = "Voltage magnitude input (pu)"]
    end
    eqs = Equation[
        der(phiu) ~ 2 * fn * pi * (f0 - fn / 50),
        p.vr ~ v * cos(phiu),
        p.vi ~ v * sin(phiu),
        -P ~ p.vr * p.ir + p.vi * p.ii,
        -Q ~ p.vi * p.ir - p.vr * p.ii,
    ]
    extend(System(eqs, t, vars, []; name, systems, initialization_eqs = [phiu ~ angle_0],
            guesses = Dict(phiu => angle_0)), base)
end
