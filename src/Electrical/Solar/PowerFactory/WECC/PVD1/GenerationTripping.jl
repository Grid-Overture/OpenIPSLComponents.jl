# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/WECC/PVD1/GenerationTripping.mo (extends nothing)
# Blocks: none. Ports are plain variables (u; TrpLow, TrpHigh). Two first-order trackers of the minimum and the
# maximum of the input (`umin`, `umax`, states with `initial equation umin = Lv1; umax = Lv2`) and the two tripping
# curves, every `if noEvent(...)` written as an `ifelse` (no event, as in the .mo).
# The two `when (u <= Lv1) and (umin > Lv1) then reinit(umin, Lv1)` / `when (u >= Lv2) and (umax < Lv2) then
# reinit(umax, Lv2)` are **unreachable by construction**: `umin` starts at `Lv1` and can only decrease (its
# derivative is zero unless u < umin), `umax` starts at `Lv2` and can only increase. They are written all the same
# in the F-14/F-15/F-55 form (a continuous event whose root function carries the conjunction of the `when` as a
# guard, the constant 1 while it cannot fire) plus the F-41 discrete callback on the literal conditions: the cost is
# nil, the guard leaves the root function at 1 for the whole run. Omitted: graphical annotations.

@component function GenerationTripping(; name, Lv0, Lv1, Lv2, Lv3, recov, Tfilter = 1e-2)
    Lv0, Lv1, Lv2, Lv3, recov, Tfilter = float.((Lv0, Lv1, Lv2, Lv3, recov, Tfilter))
    pars = @parameters begin
        Lv0 = Lv0, [description = "Tripping repose curve point 0"]
        Lv1 = Lv1, [description = "Tripping repose curve point 1"]
        Lv2 = Lv2, [description = "Tripping repose curve point 2"]
        Lv3 = Lv3, [description = "Tripping repose curve point 3"]
        recov = recov, [description = "Recovery amount for reconnection"]
        Tfilter = Tfilter, [description = "Filter time constant of the min/max trackers (s)"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        TrpLow(t), [description = "Tripping for low values of the input"]
        TrpHigh(t), [description = "Tripping for high values of the input"]
        umin(t), [description = "Tracked minimum of the input"]
        umax(t), [description = "Tracked maximum of the input"]
    end
    eqs = Equation[
        umin + Tfilter * der(umin) ~ ifelse((u < umin) & (umin > Lv0), u, umin),
        umax + Tfilter * der(umax) ~ ifelse((u > umax) & (umax < Lv3), u, umax),
        TrpLow ~ ifelse(u < Lv0, 0.0,
            ifelse(u < Lv1, (umin - Lv0 + ifelse(u <= umin, 0.0, recov * (u - umin))) / (Lv1 - Lv0),
                ifelse(umin >= Lv1, 1.0, (umin - Lv0 + recov * (Lv1 - umin)) / (Lv1 - Lv0)))),
        TrpHigh ~ ifelse(u > Lv3, 0.0,
            ifelse(u > Lv2, (Lv3 - umax + ifelse(u >= umax, 0.0, recov * (umax - u))) / (Lv3 - Lv2),
                ifelse(umax <= Lv2, 1.0, (Lv3 - umax + recov * (umax - Lv2)) / (Lv3 - Lv2)))),
    ]
    to_Lv1 = ImperativeAffect((m, o, ctx, integ) -> (; umin = o.Lv1); modified = (; umin), observed = (; Lv1))
    to_Lv2 = ImperativeAffect((m, o, ctx, integ) -> (; umax = o.Lv2); modified = (; umax), observed = (; Lv2))
    # when (u <= Lv1) and (umin > Lv1): u crosses Lv1 downwards while umin > Lv1 (guard, F-55)
    ev_min = SymbolicContinuousCallback([ifelse(umin > Lv1, u - Lv1, 1.0) ~ 0], nothing; affect_neg = to_Lv1,
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    # when (u >= Lv2) and (umax < Lv2): u crosses Lv2 upwards while umax < Lv2
    ev_max = SymbolicContinuousCallback([ifelse(umax < Lv2, u - Lv2, 1.0) ~ 0], to_Lv2; affect_neg = nothing,
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    after_event = SymbolicDiscreteCallback(((u <= Lv1) & (umin > Lv1)) | ((u >= Lv2) & (umax < Lv2)),
        ImperativeAffect((m, o, ctx, integ) -> (; umin = o.u <= o.Lv1 && m.umin > o.Lv1 ? o.Lv1 : m.umin,
                umax = o.u >= o.Lv2 && m.umax < o.Lv2 ? o.Lv2 : m.umax);
            modified = (; umin, umax), observed = (; u, Lv1, Lv2)); reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    System(eqs, t, vars, pars; name, initialization_eqs = [umin ~ Lv1, umax ~ Lv2],
        guesses = Dict(umin => Lv1, umax => Lv2), continuous_events = [ev_min, ev_max], discrete_events = [after_event])
end
