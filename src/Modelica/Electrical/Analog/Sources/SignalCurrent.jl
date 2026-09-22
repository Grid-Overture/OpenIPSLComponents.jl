# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Electrical/Analog/Sources.mo, model SignalCurrent
# Two pins and the current from p to n as an input. Same shape as SignalVoltage.jl (it extends `TwoPin`, not
# `OnePort`); the only difference is which of `v` / `i` the caller drives.
# Omitted: the `Icons.CurrentSource` icon, graphical annotations.

@component function SignalCurrent(; name)
    systems = @named begin
        p = Pin()
        n = Pin()
    end
    vars = @variables begin
        v(t), [description = "Voltage drop between the two pins (= p.v - n.v)"]
        i(t), [description = "Current flowing from pin p to pin n as input signal"]
    end
    System(Equation[v ~ p.v - n.v, 0 ~ p.i + n.i, i ~ p.i], t, vars, []; name, systems)
end
