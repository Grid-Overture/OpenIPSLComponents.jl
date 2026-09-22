# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Events/PwFaultPQ.mo
# Transitory short-circuit with the active and reactive power supplied to the fault. The time-dependent `if`
# (`time < t1` → 0, `time < t2` → fault, else 0) is the discrete variable `on` switched by two discrete events at t1
# and t2 (tstops), imperative affects followed by a DAE re-initialization (PwFault, F-15). Equations literal (the
# current relation is implicit, as in the .mo). Omitted: graphical annotations.

@component function PwFaultPQ(; name, R, X, t1, t2)
    R, X, t1, t2 = float.((R, X, t1, t2))
    pars = @parameters begin
        R = R, [description = "Resistance (pu)"]
        X = X, [description = "Reactance (pu)"]
        t1 = t1, [description = "Start time of the fault (s)"]
        t2 = t2, [description = "End time of the fault (s)"]
    end
    disc = @discretes begin
        on(t) = 0
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        P(t), [description = "Active power supplied to the fault (pu)"]
        Q(t), [description = "Reactive power supplied to the fault (pu)"]
    end
    eqs = Equation[
        p.ir ~ on * (1 / X * (p.vi - R * p.ii)),
        p.ii ~ on * ((R * p.vi - X * p.vr) / (X * X + R * R)),
        P ~ p.vr * p.ir + p.vi * p.ii,
        Q ~ (-p.vr * p.ii) + p.vi * p.ir,
    ]
    switch(value) = SymbolicDiscreteCallback(t == (value == 1 ? t1 : t2),
        ImperativeAffect((m, o, ctx, integ) -> (; on = value); modified = (; on));
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    System(eqs, t, vars, [pars; disc]; name, systems, discrete_events = [switch(1), switch(0)], tstops = [[t1, t2]])
end
