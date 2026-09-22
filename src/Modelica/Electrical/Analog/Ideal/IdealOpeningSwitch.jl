# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Electrical/Analog/Ideal/IdealOpeningSwitch.mo (with its base Interfaces/IdealSwitch.mo)
# extends Interfaces.IdealSwitch (which extends OnePort) + `off = control`, the Boolean input "true => switch open".
# MSL's parameterized-curve form is kept literally:
#     v = (s*unitCurrent)*(if off then 1 else Ron),  i = (s*unitVoltage)*(if off then Goff else 1)
# with `unitVoltage = unitCurrent = 1`. `off` is an algebraic 0/1 variable and the branches are `ifelse`, so `s`
# stays an unknown of both equations: that is exactly why MSL writes the curve this way, and it is why the F-24
# pivot does not appear here (the coefficient is `1` closed and `Goff` open, never zero). Verified by the phase-0
# probe of PLAN-07 (F-61): `mtkcompile` of the DC link keeps `[Inductor.i, switch.s, Capacitor.v]`, and the open
# branch reproduces `Goff*(p.v - n.v)` to 2e-7.
# **The mode change is a continuous event, not a bare `ifelse` on the condition** (F-61): with the
# `Cdc = 1e-6` of `Examples.Microgrids.IEEEMicrogrid` the `ifelse` form returns `Unstable` at t = 2.99 ms at both
# 1e-8 and 1e-9, while this form runs. In Modelica the Boolean input `control` is itself a relation
# (`Resistor.i < 0` in `AC2DCandDC2AC`), which the tool turns into a state event; here the block owns that event
# (rule 6.3: the event belongs to the block, a model that flattens it loses it, F-59). `switch_condition` is the
# expression whose sign drives it: the switch opens on its down-crossing and closes on its up-crossing, two
# direction-dependent imperative affects on the discrete `off_d` (F-14, F-15). One crossing function serves both
# modes because with the switch open `i = Goff*(p.v - n.v)`, so `i > 0` and `p.v - n.v > 0` have the same root; a
# single affect that reads the sign *at* the crossing is wrong, since the expression is zero there (the probe
# reached `Inductor.i = -126 A` that way).
# `switch_condition` defaults to `p.v - n.v < 0` (the switch's own voltage drop), the mode-consistent condition;
# `AC2DCandDC2AC` passes `Resistor.i` instead, the expression its `.mo` writes.
# Omitted: `ConditionalHeatPort`/`LossPower` (`useHeatPort = false`), graphical annotations.

@component function IdealOpeningSwitch(; name, Ron = 1e-5, Goff = 1e-5, off_start = 0)
    pars = @parameters begin
        Ron = float(Ron), [description = "Closed switch resistance"]
        Goff = float(Goff), [description = "Opened switch conductance"]
    end
    dis = @discretes begin
        off_d(t) = float(off_start)
    end
    vars = @variables begin
        s(t), [description = "Auxiliary variable"]
        off(t), [description = "Indicates off-state (1 = open, 0 = closed)"]
        control(t), [description = "Switching quantity: the switch is open while it is negative"]
    end
    base = OnePort(; name)
    @unpack v, i = base
    eqs = Equation[
        off ~ off_d,
        v ~ s * ifelse(off > 0.5, 1.0, Ron),
        i ~ s * ifelse(off > 0.5, Goff, 1.0),
    ]
    set(value) = ImperativeAffect((m, o, ctx, integ) -> (; off_d = value); modified = (; off_d))
    ev = SymbolicContinuousCallback([control ~ 0], set(0.0); affect_neg = set(1.0),
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    extend(System(eqs, t, vars, [pars; dis]; name, continuous_events = [ev]), base)
end
