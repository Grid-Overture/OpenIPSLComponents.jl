# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Sensors/PwVoltage.mo (a `class`)
# Voltage sensor: draws no current; the RealOutputs vr, vi, v are plain variables. Omitted: graphical annotations.

@component function PwVoltage(; name)
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        vr(t), [description = "Real part of the voltage (pu)"]
        vi(t), [description = "Imaginary part of the voltage (pu)"]
        v(t), [description = "Voltage magnitude (pu)"]
    end
    eqs = Equation[
        p.ir ~ 0,
        p.ii ~ 0,
        vr ~ p.vr,
        vi ~ p.vi,
        v ~ sqrt(p.vr * p.vr + p.vi * p.vi),
    ]
    System(eqs, t, vars, []; name, systems)
end
