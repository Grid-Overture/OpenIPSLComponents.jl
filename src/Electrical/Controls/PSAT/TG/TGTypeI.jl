# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/TG/TGTypeI.mo
# Flat model, no blocks: three states xg1, xg2, xg3, all with `fixed = true`, so their start values are
# `initial_conditions` (F-11, F-20). The protected parameters pin0, xg10, xg20, xg30 are Julia arithmetic in the
# .mo's own order, which is their dependency order.
# The .mo's three-branch `if` is on the *variable* `pinstar`, not on a parameter expression, so it is a nested
# `ifelse` and not a Julia decision (F-50 applies to parameter conditions only); it is written as the .mo spells it,
# not as `clamp(pinstar, pmin, pmax)`.
# The RealInput/RealOutput ports w, pm are plain variables; `pin`, `pinstar` are the .mo's own variables.
# Only `wref` has a default in the .mo; the other nine parameters are required keyword arguments.
# Omitted: graphical annotations.

@component function TGTypeI(; name, wref = 1, pref, R, pmax, pmin, Ts, Tc, T3, T4, T5)
    wref, pref, R, pmax, pmin, Ts, Tc, T3, T4, T5 =
        float.((wref, pref, R, pmax, pmin, Ts, Tc, T3, T4, T5))   # F-21
    pin0 = pref
    xg10 = pin0
    xg20 = (1 - T3 / Tc) * xg10
    xg30 = (1 - T4 / T5) * (xg20 + T3 * xg10 / Tc)
    pars = @parameters begin
        wref = wref, [description = "Speed reference (pu)"]
        pref = pref, [description = "Active power reference (pu)"]
        R = R, [description = "Droop (pu)"]
        pmax = pmax, [description = "Maximum turbine output (pu)"]
        pmin = pmin, [description = "Minimum turbine output (pu)"]
        Ts = Ts, [description = "Governor time constant (s)"]
        Tc = Tc, [description = "Servo time constant (s)"]
        T3 = T3, [description = "Transient gain time constant (s)"]
        T4 = T4, [description = "Power fraction time constant (s)"]
        T5 = T5, [description = "Reheat time constant (s)"]
        pin0 = pin0, [description = "Initialization"]
        xg10 = xg10, [description = "Initialization"]
        xg20 = xg20, [description = "Initialization"]
        xg30 = xg30, [description = "Initialization"]
    end
    vars = @variables begin
        w(t), [description = "Rotor speed (pu)"]
        pm(t), [description = "Mechanical power (pu)"]
        pin(t), [description = "Turbine output (pu)"]
        pinstar(t)
        xg1(t)
        xg2(t)
        xg3(t)
    end
    eqs = Equation[
        pinstar ~ pref + (wref - w) / R,
        # if pinstar >= pmin and pinstar <= pmax then pin = pinstar; elseif pinstar > pmax then pin = pmax;
        # else pin = pmin; end if;
        pin ~ ifelse((pinstar >= pmin) & (pinstar <= pmax), pinstar, ifelse(pinstar > pmax, pmax, pmin)),
        der(xg1) ~ (pin - xg1) / Ts,
        der(xg2) ~ ((1 - T3 / Tc) * xg1 - xg2) / Tc,
        der(xg3) ~ ((1 - T4 / T5) * (xg2 + T3 * xg1 / Tc) - xg3) / T5,
        pm ~ xg3 + (xg2 + T3 * xg1 / Tc) * T4 / T5,
    ]
    System(eqs, t, vars, pars; name,
        initial_conditions = Dict(xg1 => xg10, xg2 => xg20, xg3 => xg30),
        guesses = Dict(w => 1.0, pm => pref, pin => pin0, pinstar => pin0))
end
