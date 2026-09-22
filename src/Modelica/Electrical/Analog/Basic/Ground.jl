# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Electrical/Analog/Basic.mo, model Ground
# One pin held at zero potential: the reference node of an analog circuit. Omitted: graphical annotations.

@component function Ground(; name)
    systems = @named begin
        p = Pin()
    end
    System(Equation[p.v ~ 0], t, [], []; name, systems)
end
