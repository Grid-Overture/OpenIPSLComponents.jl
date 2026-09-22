# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/SimpleLead.mo (block)
# Ports are plain variables (u, y; SISO). `T*der(u) = K*y - u` differentiates the input: ModelingToolkit's index
# reduction differentiates the equations that define u. `y_start` is accepted (unused in the .mo as well).
# Omitted: the assert, graphical annotations.

@component function SimpleLead(; name, K, T, y_start = 0)
    pars = @parameters begin
        K = K, [description = "Gain"]
        T = T, [description = "Lead time constant (s)"]
        y_start = y_start, [description = "Output start value"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [guess = y_start, description = "Connector of Real output signal"]
    end
    System(Equation[T * der(u) ~ K * y - u], t, vars, pars; name)
end
