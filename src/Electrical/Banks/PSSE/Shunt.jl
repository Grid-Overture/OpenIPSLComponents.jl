# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Banks/PSSE/Shunt.mo
# Fixed shunt: I = (G + jB) V written as its real and imaginary parts (PLAN-02: Complex model variables as real pairs).
# Omitted: the display Complex variables I, V (aliases of the pin) and S = V conj(I), graphical annotations.

@component function Shunt(; name, G, B)
    G, B = float.((G, B))
    pars = @parameters begin
        G = G, [description = "Conductance (system base, pu)"]
        B = B, [description = "Susceptance (system base, pu)"]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        v(t), [description = "Voltage magnitude (pu)"]
    end
    eqs = Equation[
        v ~ sqrt(p.vr^2 + p.vi^2),
        p.ir ~ G * p.vr - B * p.vi,   # I = Complex(G, B)*V
        p.ii ~ B * p.vr + G * p.vi,
    ]
    System(eqs, t, vars, pars; name, systems)
end
