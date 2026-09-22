# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/OEL/IF_comparisor.mo (model): the discrete stage of the PSS/E OEL.
# Ports are plain variables (p; n1, n2, n3, n4). No sub-blocks. Omitted: graphical annotations.

# `LL`, `ML` and `HL` are parameters with a binding on the three current limits, so they are Julia arithmetic
# before `@parameters` (F-22) and are also declared as parameters, as the .mo does. Note the order the bindings
# produce: `HL = 1 - LowCurrentLimit` is the **highest** of the three and `LL = 1 - HighCurrentLimit` the lowest.
# The four-branch `if` is over a *variable* and has no `when`/`reinit`, so it is a chain of `ifelse`; the three
# thresholds are registered as continuous events without affect so that the integrator steps exactly onto them,
# as a Modelica state event does. The branch conditions of the .mo are `p >= ML and p < HL` and
# `p >= LL and p < ML`, which are exactly the complements the chain reproduces.
@component function IF_comparisor(; name, HighCurrentLimit = 1.5, MediumCurrentLimit = 1.2, LowCurrentLimit = 1.1,
        LL = 1 - HighCurrentLimit, ML = 1 - MediumCurrentLimit, HL = 1 - LowCurrentLimit)
    HighCurrentLimit, MediumCurrentLimit, LowCurrentLimit, LL, ML, HL =
        float.((HighCurrentLimit, MediumCurrentLimit, LowCurrentLimit, LL, ML, HL))
    pars = @parameters begin
        HighCurrentLimit = HighCurrentLimit
        MediumCurrentLimit = MediumCurrentLimit
        LowCurrentLimit = LowCurrentLimit
        LL = LL
        ML = ML
        HL = HL
    end
    vars = @variables begin
        p(t)
        n1(t)
        n2(t)
        n3(t)
        n4(t)
    end
    eqs = Equation[
        n1 ~ ifelse(p >= HL, 100, 0),
        n2 ~ ifelse(p >= HL, 0, ifelse(p >= ML, -0.1, 0)),
        n3 ~ ifelse(p >= ML, 0, ifelse(p >= LL, -0.2, 0)),
        n4 ~ ifelse(p >= LL, 0, -0.5),
    ]
    events = [SymbolicContinuousCallback([p - HL ~ 0], nothing), SymbolicContinuousCallback([p - ML ~ 0], nothing),
        SymbolicContinuousCallback([p - LL ~ 0], nothing)]
    System(eqs, t, vars, pars; name, continuous_events = events)
end
