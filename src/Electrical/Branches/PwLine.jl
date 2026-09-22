# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Branches/PwLine.mo
# Omitted: displayPF, the display variables P12/P21/Q12/Q21 and graphical annotations. S_b and fn are accepted as
# keyword arguments (outer SystemBase) and unused.
# Deviation, Julia only (F-21): the complex pi-model equations  vs - vr = Z*(is - vs*Y)  and  vr - vs = Z*(ir - vr*Y)
# (Y = G + jB, Z = R + jX, vs = p.vr + j p.vi, is = p.ir + j p.ii, vr = n.vr + j n.vi, ir = n.ir + j n.ii) are written
# solved for the currents, is = (vs - vr)/Z + vs*Y and ir = (vr - vs)/Z + vr*Y, as real and imaginary parts. In the
# literal residual form ModelingToolkit's tearing may combine the equations of parallel lines and divide by
# R4 - R3*X4/X3, which is exactly zero for lines with equal parameters (MachineTestBase), so the initialization
# evaluates to -Inf. The batch-0 residual form gave the same Example_3 results (F-17) and is kept in the history.
# Line opening (`if time >= t1 and time < t2 then ... opening == 1/2/3`): with a finite t1 the discrete variable
# `open` (1 in [t1, t2), 0 otherwise) is switched by two discrete events with an imperative affect and a DAE
# re-initialization (as PwFault, F-15); each current is (1 - open)*closed + open*opened, with ir = vr*Y/(1 + Z*Y)
# (opening 2) or is = vs*Y/(1 + Z*Y) (opening 3) for the end that stays connected. With the default t1 = inf the
# closed currents are used as they are, without events.

@component function PwLine(; name, R, X, G, B, t1 = Inf, t2 = Inf, opening = 1, S_b = 100e6, fn = 50)
    R, X, G, B = float.((R, X, G, B))
    pars = @parameters begin
        R = R, [description = "Resistance (pu)"]
        X = X, [description = "Reactance (pu)"]
        G = G, [description = "Shunt half conductance (pu)"]
        B = B, [description = "Shunt half susceptance (pu)"]
    end
    systems = @named begin
        p = PwPin()
        n = PwPin()
    end
    # closed: is = (vs - vr)/Z + vs*Y, ir = (vr - vs)/Z + vr*Y, with 1/Z = (R - jX)/(R^2 + X^2)
    dvr, dvi, z2 = p.vr - n.vr, p.vi - n.vi, R^2 + X^2
    is_closed = [(dvr * R + dvi * X) / z2 + (G * p.vr - B * p.vi), (dvi * R - dvr * X) / z2 + (G * p.vi + B * p.vr)]
    ir_closed = [-(dvr * R + dvi * X) / z2 + (G * n.vr - B * n.vi), -(dvi * R - dvr * X) / z2 + (G * n.vi + B * n.vr)]
    if !isfinite(t1)
        eqs = Equation[p.ir ~ is_closed[1], p.ii ~ is_closed[2], n.ir ~ ir_closed[1], n.ii ~ ir_closed[2]]
        return System(eqs, t, [], pars; name, systems)
    end
    tpars = @parameters begin
        t1 = t1, [description = "Line opening time (s)"]
        t2 = t2, [description = "Line reclosing time (s)"]
    end
    disc = @discretes begin
        open(t) = 0
    end
    # opening 2: is = 0, ir = vr*Y/(1 + Z*Y); opening 3: ir = 0, is = vs*Y/(1 + Z*Y); 1 + Z*Y = a + jb
    a, b = 1 + R * G - X * B, R * B + X * G
    zy(vr, vi) = ((vr * G - vi * B) * a + (vr * B + vi * G) * b, (vr * B + vi * G) * a - (vr * G - vi * B) * b) ./ (a^2 + b^2)
    is_open, ir_open = opening == 1 ? ((0, 0), (0, 0)) :
                       opening == 2 ? ((0, 0), zy(n.vr, n.vi)) :
                                      (zy(p.vr, p.vi), (0, 0))
    eqs = Equation[
        p.ir ~ (1 - open) * is_closed[1] + open * is_open[1],
        p.ii ~ (1 - open) * is_closed[2] + open * is_open[2],
        n.ir ~ (1 - open) * ir_closed[1] + open * ir_open[1],
        n.ii ~ (1 - open) * ir_closed[2] + open * ir_open[2],
    ]
    switch(value) = SymbolicDiscreteCallback(t == (value == 1 ? t1 : t2),
        ImperativeAffect((m, o, ctx, integ) -> (; open = value); modified = (; open));
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    System(eqs, t, [], [pars; tpars; disc]; name, systems, discrete_events = [switch(1), switch(0)], tstops = [[t1, t2]])
end
