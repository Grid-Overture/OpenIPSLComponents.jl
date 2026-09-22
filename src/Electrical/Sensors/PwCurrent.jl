# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Sensors/PwCurrent.mo
# Current sensor between p and n; the RealOutputs ir, ii, i are plain variables. Omitted: graphical annotations.

@component function PwCurrent(; name)
    systems = @named begin
        p = PwPin()
        n = PwPin()
    end
    vars = @variables begin
        ir(t), [description = "Real part of the current (pu)"]
        ii(t), [description = "Imaginary part of the current (pu)"]
        i(t), [description = "Current magnitude (pu)"]
    end
    eqs = Equation[
        p.ir ~ -n.ir,
        p.ii ~ -n.ii,
        ir ~ p.ir,
        ii ~ p.ii,
        p.vr ~ n.vr,
        p.vi ~ n.vi,
        i ~ sqrt(p.ir * p.ir + p.ii * p.ii),
    ]
    System(eqs, t, vars, []; name, systems)
end
