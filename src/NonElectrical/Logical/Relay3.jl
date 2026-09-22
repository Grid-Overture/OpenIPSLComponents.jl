# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Logical/Relay3.mo (model):
# y = if u1 > Vov then u3 elseif u1 < -Vov then u4 else u2.
# Blocks: greaterThreshold = Modelica.Blocks.Logical.GreaterThreshold(threshold = Vov),
# lessThreshold = Modelica.Blocks.Logical.LessThreshold(threshold = -Vov), switch_u3 and switch_u4 =
# Modelica.Blocks.Logical.Switch. Ports are plain variables (u1, u2, u3, u4, y).
# Omitted: graphical annotations.

@component function Relay3(; name, Vov = 0.5)
    Vov = float(Vov)
    Vn = Vov   # numeric copy for the two thresholds of the sub-blocks (F-22)
    pars = @parameters begin
        Vov = Vov, [description = "Threshold for relay"]
    end
    systems = @named begin
        greaterThreshold = GreaterThreshold(; threshold = Vn)
        lessThreshold = LessThreshold(; threshold = -Vn)
        switch_u3 = Switch()
        switch_u4 = Switch()
    end
    vars = @variables begin
        u1(t)
        u2(t)
        u3(t)
        u4(t)
        y(t)
    end
    eqs = Equation[
        greaterThreshold.u ~ u1,   # connect(greaterThreshold.u, u1)
        switch_u3.u2 ~ greaterThreshold.y,   # connect(greaterThreshold.y, switch_u3.u2)
        y ~ switch_u3.y,   # connect(switch_u3.y, y)
        switch_u3.u1 ~ u3,   # connect(u3, switch_u3.u1)
        lessThreshold.u ~ u1,   # connect(lessThreshold.u, u1)
        switch_u4.u1 ~ u4,   # connect(switch_u4.u1, u4)
        switch_u4.u3 ~ u2,   # connect(u2, switch_u4.u3)
        switch_u3.u3 ~ switch_u4.y,   # connect(switch_u4.y, switch_u3.u3)
        switch_u4.u2 ~ lessThreshold.y,   # connect(lessThreshold.y, switch_u4.u2)
    ]
    System(eqs, t, vars, pars; name, systems)
end
