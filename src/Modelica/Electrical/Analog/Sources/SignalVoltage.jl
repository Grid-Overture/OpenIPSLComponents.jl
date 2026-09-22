# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Electrical/Analog/Sources.mo, model SignalVoltage
# Two pins and the voltage between them as an input. It extends `TwoPin`, not `OnePort`: `v` is the block's input,
# so it is a plain variable here and the three equations of the base are written in the model (see OnePort.jl).
# Omitted: the `Icons.VoltageSource` icon, graphical annotations.

@component function SignalVoltage(; name)
    systems = @named begin
        p = Pin()
        n = Pin()
    end
    vars = @variables begin
        v(t), [description = "Voltage between pin p and n (= p.v - n.v) as input signal"]
        i(t), [description = "Current flowing from pin p to pin n"]
    end
    System(Equation[v ~ p.v - n.v, 0 ~ p.i + n.i, i ~ p.i], t, vars, []; name, systems)
end
