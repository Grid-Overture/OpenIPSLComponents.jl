# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Continuous.mo, block Der
# Ports are plain variables (u, y; SISO). Omitted: graphical annotations.

# The whole body of the MSL block is `y = der(u)`: an exact derivative, with no state, no time constant and no
# `initType` (F-89). It is the only mini-MSL block that differentiates its input, so where `u` is an
# algebraic unknown of a network the equation raises the index of the system and `mtkcompile` has to reduce it.
@component function Der(; name)
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    System(Equation[y ~ der(u)], t, vars, []; name)
end
