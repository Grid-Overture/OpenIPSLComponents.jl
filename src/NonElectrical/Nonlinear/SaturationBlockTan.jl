# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Nonlinear/SaturationBlockTan.mo (model): block 1 of the PSS/E OEL.
# Ports are plain variables (p1, n1). No sub-blocks. Omitted: graphical annotations.

# The `if` of the .mo is over a *variable* and has no `when`/`reinit`, so it is a chain of `ifelse`; the two
# crossings, `p1 = -0.1` and `p1 = 0`, are registered as continuous events without affect so that the integrator
# steps exactly onto them, as a Modelica state event does. The middle branch of the .mo is written
# `p1 > -0.1 and p1 < 0`, which is exactly the complement of the other two, so the chain reproduces it.
# `tan(r)` is on the numeric parameter: `r` is a parameter of the .mo and Modelica evaluates the call once.
@component function SaturationBlockTan(; name, r, f)
    r, f = float.((r, f))
    tan_r = tan(r)   # a parameter expression: evaluated once, before @parameters rebinds `r` (F-22)
    pars = @parameters begin
        r = r, [description = "Exiciter parameter"]
        f = f, [description = "Exiciter parameter"]
    end
    vars = @variables begin
        p1(t)
        n1(t)
    end
    eqs = Equation[n1 ~ ifelse(p1 <= -0.1, -1, ifelse(p1 < 0, 0, tan_r * p1 + f))]
    events = [SymbolicContinuousCallback([p1 + 0.1 ~ 0], nothing), SymbolicContinuousCallback([p1 ~ 0], nothing)]
    System(eqs, t, vars, pars; name, continuous_events = events)
end
