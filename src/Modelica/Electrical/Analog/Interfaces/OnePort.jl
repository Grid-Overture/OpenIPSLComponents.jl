# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Electrical/Analog/Interfaces/OnePort.mo (with its base TwoPin.mo)
# Partial base of every two-pin analog component: `extends TwoPin` (the two pins and `v = p.v - n.v`) plus
# `0 = p.i + n.i` and `i = p.i`. The three equations are written here, as OpenIPSL's own partial bases are
# (rule 4); `TwoPin` is not a file of its own because nothing else extends it -- `SignalVoltage` and
# `SignalCurrent`, MSL's only other `TwoPin` users, do not extend this base either (their `v` / `i` is the block's
# input, not an unknown), so they write the same three equations themselves.
# Omitted: `ConditionalHeatPort` (every user of this batch has `useHeatPort = false`), graphical annotations.

@component function OnePort(; name)
    systems = @named begin
        p = Pin()
        n = Pin()
    end
    vars = @variables begin
        v(t), [description = "Voltage drop of the two pins (= p.v - n.v)"]
        i(t), [description = "Current flowing from pin p to pin n"]
    end
    System(Equation[v ~ p.v - n.v, 0 ~ p.i + n.i, i ~ p.i], t, vars, []; name, systems)
end
