# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Nonlinear/Deadband2.mo (model)
# Ports are plain variables (u, y; SISO). The `algorithm` with three `when` clauses on pre(y) is a discrete output y
# (start 0, as the Modelica default) updated by two continuous events: u crossing y - db downwards sets y := u + db,
# u crossing y + db upwards sets y := u - db; between them y keeps its value (the middle `when` is a no-op).
# Imperative affects with a DAE re-initialization (F-15). Omitted: graphical annotations.

@component function Deadband2(; name, db = 0.1)
    pars = @parameters begin
        db = db, [description = "Deadband"]
    end
    disc = @discretes begin
        y(t) = 0
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
    end
    lower = SymbolicContinuousCallback([u - (y - db) ~ 0], nothing;
        affect_neg = ImperativeAffect((m, o, ctx, integ) -> (; y = o.u + o.db); modified = (; y), observed = (; u, db)),
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    upper = SymbolicContinuousCallback([u - (y + db) ~ 0],
        ImperativeAffect((m, o, ctx, integ) -> (; y = o.u - o.db); modified = (; y), observed = (; u, db));
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    System(Equation[], t, vars, [pars; disc]; name, continuous_events = [lower, upper])
end
