# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Events/PwFault.mo
# The bolted-fault branch (ground = abs(R) < eps and abs(X) < eps, which prescribes p.vr = 1e-10, p.vi = 0) is not
# translated: Example_3 uses R = X = 0.01. The constructor rejects a bolted fault.
# The time-dependent `if` becomes the discrete variable `on` (0 before t1 and from t2, 1 in [t1, t2)) switched by
# two discrete events at t1 and t2 (both registered as tstops). The affects are imperative (they only write `on`)
# and each is followed by a DAE re-initialization (BrownFullBasicInit: differential states held, algebraic
# variables re-solved), i.e. the re-initialization the paper performs by hand at each segment boundary (F-15).
# `events = false` (Julia only) skips the events and the tstops so that `on` can be set by the caller; used by
# examples/example_3_segmented.jl.
# Omitted: graphical annotations.

@component function PwFault(; name, R, X, t1, t2, events = true)
    ground = abs(R) < Modelica.Constants.eps && abs(X) < Modelica.Constants.eps
    ground && throw(ArgumentError("PwFault: the bolted-fault branch (R = X = 0) is not translated"))
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
    eqs = Equation[
        p.ii ~ on * (R * p.vi - X * p.vr) / (X * X + R * R),
        p.ir ~ on * (R * p.vr + X * p.vi) / (R * R + X * X),
    ]
    switch(value) = SymbolicDiscreteCallback(t == (value == 1 ? t1 : t2),
        ImperativeAffect((m, o, ctx, integ) -> (; on = value); modified = (; on));
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    kw = events ? (; discrete_events = [switch(1), switch(0)], tstops = [[t1, t2]]) : (;)
    System(eqs, t, [], [pars; disc]; name, systems, kw...)
end
