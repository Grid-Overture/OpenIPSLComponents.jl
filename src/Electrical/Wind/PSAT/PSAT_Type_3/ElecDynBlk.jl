# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSAT/PSAT_Type_3/ElecDynBlk.mo (extends nothing)
# Blocks: none. Ports are plain variables (omega_m, Vbus; idr, iqr -- the two outputs carry `start = idr0/iqr0`,
# guesses). The rotor-current controllers of the DFIG: `idrI`, `iqrI` are the unsaturated states, `idr`, `iqr`
# their saturated outputs (which feed back into the derivatives: anti-windup), `Vref` and `iqr_off` are states
# with `der = 0` -- the Modelica idiom for "a parameter that the initialization fixes" -- kept as **states** with
# their `initial equation`s in `initialization_eqs` (OpenModelica writes them as states in its CSV), not as
# `missing` parameters. `pwa = max(min(2*omega_m - 1, 1), 0)*Pnom/Sbase` is `max`/`min` on a variable (no event,
# F-27). The derived parameters are reordered to their dependency order as keyword defaults (ElecBlk.jl); `Vbase`,
# `freq`, `wbase`, `Hm`, `i2Hm` are declared and read by no equation (sic); `Tdmy = 1` is the protected time
# constant of `idrI`.
# The two `when iqrI > iqr_max and der(iqrI) < 0 then reinit(iqrI, iqr_max); elsewhen iqrI < iqr_min and
# der(iqrI) > 0 then reinit(iqrI, iqr_min)` (and the same for `idrI`) are SimpleLagLim's `when`: one continuous
# event per state on the right-hand side of its derivative, guarded by the conjunction (F-14, F-15, F-55), with
# self-limiting imperative affects, plus the F-41 discrete callback on the literal conditions.
# Omitted: graphical annotations.

@component function ElecDynBlk(; name, Sbase = 100000000, Vbus0 = 1, angle_0 = -0.00243, Pc = 0.0160000000000082,
        Qc = 0.030527374471207, Pnom = 10, Vbase = 400000, freq = 50, Rs = 0.1, Xs = 1, Rr = 0.1, Xr = 0.8, Xm = 30,
        Hm = 0.3, iqr_max, idr_max, iqr_min, idr_min, poles = 2, Kv = 10, Te = 0.01, Tdmy = 1,
        omega_m0 = min(max(0.5 * Pc * Sbase / Pnom + 0.5, 0.5), 1), x1 = Xm + Xs, x2 = Xm + Xr,
        wbase = 2 * pi * freq / poles, k = x1 * Pnom / Vbus0 / Xm / Sbase, vds0 = -Vbus0 * sin(angle_0),
        vqs0 = Vbus0 * cos(angle_0), iqr0 = -x1 * Pnom * (2 * omega_m0 - 1) / Vbus0 / Xm / Sbase / omega_m0,
        ids0 = ((-vds0^2) + vds0 * Xm * iqr0 - x1 * Qc) / (Rs * vds0 - x1 * vqs0),
        iqs0 = ((-vds0 * vqs0) + vqs0 * Xm * iqr0 - Rs * Qc) / (Rs * vds0 - x1 * vqs0),
        idr0 = -(vqs0 + Rs * iqs0 + x1 * ids0) / Xm,
        vdr0 = (-Rr * idr0) + (1 - omega_m0) * (x2 * iqr0 + Xm * iqs0),
        vqr0 = (-Rr * iqr0) - (1 - omega_m0) * (x2 * idr0 + Xm * ids0), i2Hm = 1 / (2 * Hm))
    Sbase, Vbus0, angle_0, Pc, Qc, Pnom, Vbase, freq, Rs, Xs, Rr, Xr, Xm, Hm, iqr_max, idr_max, iqr_min, idr_min, Kv, Te, Tdmy =
        float.((Sbase, Vbus0, angle_0, Pc, Qc, Pnom, Vbase, freq, Rs, Xs, Rr, Xr, Xm, Hm, iqr_max, idr_max, iqr_min, idr_min, Kv, Te, Tdmy))
    omega_m0, x1, x2, wbase, k, vds0, vqs0, iqr0, ids0, iqs0, idr0, vdr0, vqr0, i2Hm =
        float.((omega_m0, x1, x2, wbase, k, vds0, vqs0, iqr0, ids0, iqs0, idr0, vdr0, vqr0, i2Hm))
    pars = @parameters begin
        Sbase = Sbase, [description = "Power Rating [Normalization Factor] (VA)"]
        Vbus0 = Vbus0, [description = "Voltage from Power Flow (pu)"]
        angle_0 = angle_0, [description = "Angle from Power Flow (rad)"]
        Pc = Pc, [description = "Active Power, PowerFlow (pu)"]
        Qc = Qc, [description = "Reactive Power, Power Flow (pu)"]
        omega_m0 = omega_m0
        Pnom = Pnom, [description = "Nominal Power (VA)"]
        Vbase = Vbase, [description = "Voltage rating (V; unused)"]
        freq = freq, [description = "frequency rating (Hz; unused)"]
        Rs = Rs, [description = "stator Resistance (pu)"]
        Xs = Xs, [description = "stator Reactance (pu)"]
        Rr = Rr, [description = "Rotor Resitance (pu)"]
        Xr = Xr, [description = "rotor Reactance (pu)"]
        Xm = Xm, [description = "magnetisation reactance (pu)"]
        Hm = Hm, [description = "inertia (s; unused)"]
        x1 = x1, [description = "stator plus magnetisation impedances"]
        x2 = x2, [description = "rotor plus magnetisation impedances"]
        wbase = wbase, [description = "basis for angular speed (unused)"]
        iqr_max = iqr_max
        idr_max = idr_max
        iqr_min = iqr_min
        idr_min = idr_min
        poles = poles, [description = "Number of poles-pair"]
        Kv = Kv, [description = "Voltage control gain"]
        Te = Te, [description = "Power Control time constant (s)"]
        k = k, [description = "gain for iqr_off computation"]
        ids0 = ids0
        iqs0 = iqs0
        idr0 = idr0
        iqr0 = iqr0
        vds0 = vds0
        vqs0 = vqs0
        vdr0 = vdr0
        vqr0 = vqr0
        i2Hm = i2Hm, [description = "inverse inertia (unused)"]
        Tdmy = Tdmy, [description = "dummy time constant (s)"]
    end
    vars = @variables begin
        omega_m(t), [description = "Rotor Speed"]
        Vbus(t), [description = "Vbus"]
        idr(t), [description = "saturated idr"]
        iqr(t), [description = "saturated iqr"]
        idrI(t), [description = "internal, non saturated idr"]
        iqrI(t), [description = "internal, non saturated iqr"]
        Vref(t)
        iqr_off(t)
        pwa(t)
    end
    rhs_q = (-(Xs + Xm) * pwa / Vbus / Xm / omega_m) - iqr - iqr_off   # der(iqrI) = rhs_q/Te
    rhs_d = Kv * (Vbus - Vref) - Vbus / Xm - idr                       # der(idrI) = rhs_d/Tdmy
    eqs = Equation[
        der(Vref) ~ 0,
        der(iqr_off) ~ 0,
        pwa ~ max(min(2 * omega_m - 1, 1), 0) * Pnom / Sbase,
        der(iqrI) ~ rhs_q / Te,
        der(idrI) ~ rhs_d / Tdmy,
        iqr ~ min(max(iqrI, iqr_min), iqr_max),
        idr ~ min(max(idrI, idr_min), idr_max),
    ]
    BFBI = OrdinaryDiffEqCore.BrownFullBasicInit()
    q_min = ImperativeAffect((m, o, ctx, integ) -> (; iqrI = max(m.iqrI, o.iqr_min)); modified = (; iqrI), observed = (; iqr_min))
    q_max = ImperativeAffect((m, o, ctx, integ) -> (; iqrI = min(m.iqrI, o.iqr_max)); modified = (; iqrI), observed = (; iqr_max))
    d_min = ImperativeAffect((m, o, ctx, integ) -> (; idrI = max(m.idrI, o.idr_min)); modified = (; idrI), observed = (; idr_min))
    d_max = ImperativeAffect((m, o, ctx, integ) -> (; idrI = min(m.idrI, o.idr_max)); modified = (; idrI), observed = (; idr_max))
    ev_q = SymbolicContinuousCallback([ifelse((iqrI > iqr_max) | (iqrI < iqr_min), rhs_q, 1.0) ~ 0], q_min; affect_neg = q_max, reinitializealg = BFBI)
    ev_d = SymbolicContinuousCallback([ifelse((idrI > idr_max) | (idrI < idr_min), rhs_d, 1.0) ~ 0], d_min; affect_neg = d_max, reinitializealg = BFBI)
    after_event = SymbolicDiscreteCallback(((iqrI > iqr_max) & (rhs_q < 0)) | ((iqrI < iqr_min) & (rhs_q > 0)) |
                                           ((idrI > idr_max) & (rhs_d < 0)) | ((idrI < idr_min) & (rhs_d > 0)),
        ImperativeAffect((m, o, ctx, integ) -> (; iqrI = max(min(m.iqrI, o.iqr_max), o.iqr_min), idrI = max(min(m.idrI, o.idr_max), o.idr_min));
            modified = (; iqrI, idrI), observed = (; iqr_max, iqr_min, idr_max, idr_min)); reinitializealg = BFBI)
    System(eqs, t, vars, pars; name,
        initialization_eqs = [0 ~ (-(Xs + Xm) * pwa / Vbus / Xm / omega_m) - iqr - iqr_off,
            Vref ~ Vbus0 - (idrI + Vbus0 / Xm) / Kv,
            iqr_off ~ (-k * max(min(2 * omega_m0 - 1, 1), 0) / omega_m0) - iqrI],
        guesses = Dict(idr => idr0, iqr => iqr0, idrI => idr0, iqrI => iqr0, Vref => Vbus0, iqr_off => 0.0, Vbus => Vbus0),
        continuous_events = [ev_q, ev_d], discrete_events = [after_event])
end
