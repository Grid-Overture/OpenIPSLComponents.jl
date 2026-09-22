# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Logical.mo, block ZeroCrossing
# Ports are plain variables (u, enable, y (partialBooleanSO)); Boolean signals as Real 0/1 (PLAN-01). Omitted:
# graphical annotations.
# `y = change(u_pos) and not edge(enable) and not edge(disable)`, with `u_pos = enable and u >= 0`, is true only at
# the instant u crosses zero while enable is true: a pulse of zero width has no continuous representation, so y is
# identically 0 here and the parent that consumes the crossing (`when zeroCrossing.y and ...`, Generic.ULTC)
# registers a continuous event on `zeroCrossing.u` itself (PLAN-02). The block keeps the names OpenModelica writes
# (`ultc.zeroCrossing.u`, `.enable`, `.y`); `enable` is set by the parent (`zeroCrossing.enable ~ 1`).

@component function ZeroCrossing(; name)
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        enable(t), [description = "Zero input crossing is triggered if the enable input signal is true (0/1)"]
        y(t), [description = "Connector of Boolean output signal (0/1); 0 in continuous time, see header"]
    end
    System(Equation[y ~ 0], t, vars, []; name)
end
