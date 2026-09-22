# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSAT/PSAT_Type_3/PitchControl.mo (extends nothing)
# Blocks: none. Ports are plain variables (omega_m; theta_p, whose `start = theta_p0` is a guess). The pitch
# integrator with an output saturation, `theta_p = min(max(theta_pI, theta_p_min), theta_p_max)`, on the quantized
# speed error `phi = ceil(0.5*floor(1000*(omega_m - 1)*2))/1000` (a 0.001 quantizer with a +-0.0005 dead band):
# `ceil`/`floor` are written literally on the symbolic expression, without event (OpenModelica generates a state
# event at every step of the quantizer; F-27 covers the sampling). `initial equation (Kp*phi - theta_pI)/Tp = 0`
# uses the unsaturated state while the dynamics use the saturated output (sic).
# `when theta_pI > theta_p_max and der(theta_pI) < 0 then reinit(theta_pI, theta_p_max); elsewhen theta_pI <
# theta_p_min and der(theta_pI) > 0 then reinit(theta_pI, theta_p_min)` is exactly SimpleLagLim's `when`: one
# continuous event on the right-hand side of `der(theta_pI)` (ModelingToolkit does not accept `D(x)` in a
# condition), guarded by the conjunction (F-14, F-15, F-55), with self-limiting imperative affects, plus the F-41
# discrete callback on the literal conditions. Quirk, sic: with the defaults of PSAT_WT (`omega_m0 = 0.58`) `phi =
# -0.42`, `theta_pI(0) = -4.2 < theta_p_min = 0` with `der < 0`, so the internal state runs to -inf while
# `theta_p = 0` (the lower `when` only fires with `der > 0`). Omitted: graphical annotations.

@component function PitchControl(; name, Kp = 10, Tp = 3, theta_p0 = 0, theta_p_min, theta_p_max)
    Kp, Tp, theta_p0, theta_p_min, theta_p_max = float.((Kp, Tp, theta_p0, theta_p_min, theta_p_max))
    pars = @parameters begin
        Kp = Kp, [description = "Pitch control gain"]
        Tp = Tp, [description = "Pitch control time constant (s)"]
        theta_p0 = theta_p0, [description = "Initial pitch angle (rad)"]
        theta_p_min = theta_p_min, [description = "Minimum pitch angle (rad)"]
        theta_p_max = theta_p_max, [description = "Maximum pitch angle (rad)"]
    end
    vars = @variables begin
        omega_m(t), [description = "Mechanical speed"]
        theta_p(t), [description = "saturated theta_p"]
        theta_pI(t), [description = "internal non-saturated theta_p"]
        phi(t)
    end
    rhs = Kp * phi - theta_p   # der(theta_pI) = rhs/Tp
    eqs = Equation[
        theta_p ~ min(max(theta_pI, theta_p_min), theta_p_max),
        phi ~ ceil(0.5 * floor(1000 * (omega_m - 1) * 2)) / 1000,
        der(theta_pI) ~ rhs / Tp,
    ]
    reinit_min = ImperativeAffect((m, o, ctx, integ) -> (; theta_pI = max(m.theta_pI, o.theta_p_min)); modified = (; theta_pI), observed = (; theta_p_min))
    reinit_max = ImperativeAffect((m, o, ctx, integ) -> (; theta_pI = min(m.theta_pI, o.theta_p_max)); modified = (; theta_pI), observed = (; theta_p_max))
    ev = SymbolicContinuousCallback([ifelse((theta_pI > theta_p_max) | (theta_pI < theta_p_min), rhs, 1.0) ~ 0],
        reinit_min; affect_neg = reinit_max, reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    after_event = SymbolicDiscreteCallback(((theta_pI > theta_p_max) & (rhs < 0)) | ((theta_pI < theta_p_min) & (rhs > 0)),
        ImperativeAffect((m, o, ctx, integ) -> (; theta_pI = max(min(m.theta_pI, o.theta_p_max), o.theta_p_min));
            modified = (; theta_pI), observed = (; theta_p_max, theta_p_min)); reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    System(eqs, t, vars, pars; name, initialization_eqs = [(Kp * phi - theta_pI) / Tp ~ 0],
        guesses = Dict(theta_p => theta_p0, theta_pI => theta_p0), continuous_events = [ev], discrete_events = [after_event])
end
