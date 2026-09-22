# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Logical/Relay.mo (model): y = if u1 > 0 then u2 else u3.
# Blocks: greaterThreshold = Modelica.Blocks.Logical.GreaterThreshold, switch = Modelica.Blocks.Logical.Switch
# (instance named `switch` in the .mo, kept). Ports are plain variables (u1, u2, u3, y).
# Omitted: graphical annotations.

@component function Relay(; name)
    systems = @named begin
        greaterThreshold = GreaterThreshold()
        switch = Switch()
    end
    vars = @variables begin
        u1(t)
        u2(t)
        u3(t)
        y(t)
    end
    eqs = Equation[
        greaterThreshold.u ~ u1,   # connect(greaterThreshold.u, u1)
        switch.u2 ~ greaterThreshold.y,   # connect(greaterThreshold.y, switch.u2)
        switch.u1 ~ u2,   # connect(switch.u1, u2)
        switch.u3 ~ u3,   # connect(switch.u3, u3)
        y ~ switch.y,   # connect(switch.y, y)
    ]
    System(eqs, t, vars, []; name, systems)
end
