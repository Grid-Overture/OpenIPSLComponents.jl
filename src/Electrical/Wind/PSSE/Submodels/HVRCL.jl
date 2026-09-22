# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSSE/Submodels/HVRCL.mo (extends nothing)
# Blocks: none. Ports are plain variables (Vt, Iq; Iq_HVRCL). Above VHVRCR the output is **CurHVRCR itself**, not a
# limit applied to Iq (sic). Omitted: the comment of the .mo, graphical annotations.
# The relation `Vt > VHVRCR` is the discrete `hv` (0/1), not a bare `ifelse` (F-78): `Vt` is the terminal voltage
# that the current this block sets helps determine, so after a jump of the network the algebraic loop has two
# consistent roots -- `Vt = 1.0` with `Iq` injected and `Vt = 1.45` with `CurHVRCR = 2` injected in the WT4G1 Test --
# and OpenModelica, which holds a relation at its pre-event value while it re-solves the network, lands on the
# first; an `ifelse` evaluated inside Newton landed on the second. `hv` starts at 0 (`Vt <= VHVRCR` at `t = 0`,
# every case of the port starts near 1 pu) and is updated by a continuous event on `Vt - VHVRCR` located on the
# right of the crossing (F-73) plus, for a crossing produced inside another component's event or a start above the
# threshold, two discrete callbacks at the end of every step (F-41) with a 1e-9 pu hysteresis, so that they
# never undo the continuous event at its own root; every affect re-initializes the algebraics, which is the event
# iteration of Modelica.

@component function HVRCL(; name, VHVRCR, CurHVRCR)
    VHVRCR, CurHVRCR = float.((VHVRCR, CurHVRCR))
    pars = @parameters begin
        VHVRCR = VHVRCR, [description = "Threshold voltage for HVRCL (pu)"]
        CurHVRCR = CurHVRCR, [description = "Max. reactive current at VHVRCR (pu)"]
    end
    disc = @discretes begin
        hv(t) = 0.0, [description = "The relation Vt > VHVRCR (0/1), updated at its crossings"]
    end
    vars = @variables begin
        Vt(t), [description = "Terminal voltage (pu)"]
        Iq_HVRCL(t), [description = "Reactive current after the high-voltage limiter"]
        Iq(t), [description = "Reactive current before the high-voltage limiter"]
    end
    up = ImperativeAffect((m, o, ctx, integ) -> (; hv = 1.0); modified = (; hv))
    down = ImperativeAffect((m, o, ctx, integ) -> (; hv = 0.0); modified = (; hv))
    ev = SymbolicContinuousCallback([Vt - VHVRCR ~ 0], up; affect_neg = down, rootfind = SciMLBase.RightRootFind,
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    # the fallbacks carry a 1e-9 pu hysteresis (OpenModelica's relations have one too, F-77): at the root the
    # continuous event locates, Vt is VHVRCR to 1e-16 and a fallback without margin undoes the affect (F-78)
    after_up = SymbolicDiscreteCallback((Vt > VHVRCR + 1e-9) & (hv < 0.5), up; reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    after_down = SymbolicDiscreteCallback((Vt < VHVRCR - 1e-9) & (hv > 0.5), down; reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    System(Equation[Iq_HVRCL ~ ifelse(hv > 0.5, CurHVRCR, Iq)], t, vars, [pars; disc]; name,
        continuous_events = [ev], discrete_events = [after_up, after_down])
end
