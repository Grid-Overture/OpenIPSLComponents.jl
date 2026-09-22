# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Electrical/Analog/Basic.mo, model Inductor
# extends Interfaces.OnePort(i(start = 0)): `L*der(i) = v`. The `start = 0` of the base modifier is carried as the
# kwarg `i_start` -> `guesses`, so that a parent can hand back a different value (rule 6.2); `AC2DCandDC2AC` writes
# `Inductor(i(start = Il0, fixed = false), L = Ldc)` with `Il0 = 0`, i.e. a guess, not a fixed initial condition.
# Omitted: graphical annotations.

@component function Inductor(; name, L = 1, i_start = 0)
    pars = @parameters begin
        L = float(L), [description = "Inductance"]
    end
    base = OnePort(; name)
    @unpack v, i = base
    extend(System(Equation[L * der(i) ~ v], t, [], pars; name, guesses = Dict(i => float(i_start))), base)
end
