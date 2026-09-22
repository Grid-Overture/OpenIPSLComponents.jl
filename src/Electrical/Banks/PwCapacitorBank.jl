# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Banks/PwCapacitorBank.mo
# Literal: the pin voltage is written explicitly from the current, V = I/(G + jB); with the defaults G = B = 0 the
# division by G^2 + B^2 is OpenIPSL's (a bank must be given G or B). `nsteps` is declared and unused in the .mo.
# Omitted: graphical annotations.

@component function PwCapacitorBank(; name, nsteps, G = 0, B = 0)
    G, B = float.((G, B))
    pars = @parameters begin
        nsteps = nsteps, [description = "Number of steps (unused in OpenIPSL 3.1.0)"]
        G = G, [description = "Active power losses (pu)"]
        B = B, [description = "Reactive power (pu)"]
    end
    systems = @named begin
        p = PwPin()
    end
    eqs = Equation[
        p.vr ~ (p.ir * G + p.ii * B) / (G * G + B * B),
        p.vi ~ ((-p.ir * B) + p.ii * G) / (G * G + B * B),
    ]
    System(eqs, t, [], pars; name, systems)
end
