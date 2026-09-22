# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Logical.mo, block RSFlipFlop
# Blocks, with the names of MSL: nor, nor1 = Nor, pre = Pre(pre_u_start = not Qini). Ports are plain variables
# (S, R; Q, QI). `Q = not (pre(not (S or Q)) or R)`: R dominant. The three sub-blocks are instantiated literally
# (the OpenModelica CSV carries `nor.y`, `nor1.y`, `pre.y`; precedent `OnePort`, batch 7); the `Pre` breaks the
# `nor <-> nor1` loop and its events (PLAN-08 probe 0.2, F-73) are the event iteration. Omitted: graphical
# annotations.

@component function RSFlipFlop(; name, Qini = false)
    systems = @named begin
        nor = Nor()
        nor1 = Nor()
        pre = Pre_(; pre_u_start = !Qini)
    end
    vars = @variables begin
        Q(t), [description = "Connector of Boolean output signal (0/1)"]
        QI(t), [description = "Connector of inverted Boolean output signal (0/1)"]
        S(t), [description = "Set input (0/1)"]
        R(t), [description = "Reset input (0/1)"]
    end
    eqs = Equation[
        nor1.y ~ nor.u2,                     # connect(nor1.y, nor.u2)
        nor1.y ~ Q,                          # connect(nor1.y, Q)
        nor.y ~ pre.u,                       # connect(nor.y, pre.u)
        pre.y ~ nor1.u1,                     # connect(pre.y, nor1.u1)
        pre.y ~ QI,                          # connect(pre.y, QI)
        S ~ nor.u1,                          # connect(S, nor.u1)
        R ~ nor1.u2,                         # connect(R, nor1.u2)
    ]
    System(eqs, t, vars, []; name, systems)
end
