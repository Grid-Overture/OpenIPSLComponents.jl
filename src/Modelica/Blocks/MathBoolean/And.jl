# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/MathBoolean.mo, block And
# Ports are plain variables (u[1:nu], y; PartialBooleanMISO). Omitted: the connectorSizing annotation, graphics.

# Boolean signals are Real 0/1 in this port (PLAN-01): `andTrue(u)` over 0/1 entries is their product.
@component function And(; name, nu = 2)
    vars = @variables begin
        (u(t))[1:nu], [description = "Connector of Boolean input signals (0/1)"]
        y(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    System(Equation[y ~ prod(u[i] for i in 1:nu)], t, [u, y], []; name)
end
