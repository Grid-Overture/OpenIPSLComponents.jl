# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/ElectricalController/BaseClasses/PIwithNoVariableLimiter.mo
# extends: nothing. Blocks with the .mo's names: integral = Integrator(k = K_I, InitialOutput, y_start),
# proportional = Gain(K_P), PI_add = Add, reset_switch = Switch, realExpression = RealExpression(0),
# limiter = Limiter(V_RMAX, V_RMIN), or1 = Or. Ports are plain variables (u, voltage_dip inputs; y output).
# The anti-windup relation is written **exactly as `PI_No_Windup.jl`** (F-44):
#   or1.u2 = if abs(V_RMAX - y) <= eps and der(integral.y) > 0 then true elseif ... else false
# is NOT reproduced -- OpenModelica 1.25 never sets it, and written literally it has no solution in saturation.
# `or1.u2 ~ 0` instead; the `Or`, the `Switch` and the `RealExpression` keep their names so that the OpenModelica
# columns `or1.y`, `reset_switch.y`, `integral.y` compare. Confirmed on this batch's own three oracles: all six
# anti-windup channels have `or1.u1 = or1.u2 = or1.y = 0` in every row (F-62).
# The freeze by `voltage_dip` on `or1.u1` **is** literal: it is the input that does act in the `REEC*` models.
# `use_reset = false` is not passed: the batch-1 `Integrator` has no reset port. Omitted: graphical annotations.

@component function PIwithNoVariableLimiter(; name, K_P, K_I, V_RMAX, V_RMIN, y_start)
    K_P, K_I, V_RMAX, V_RMIN = float.((K_P, K_I, V_RMAX, V_RMIN))
    pars = @parameters begin
        K_P = K_P, [description = "Voltage regulator proportional gain"]
        K_I = K_I, [description = "Voltage regulator integral gain"]
        V_RMAX = V_RMAX, [description = "Maximum regulator output"]
        V_RMIN = V_RMIN, [description = "Minimum regulator output"]
    end
    systems = @named begin
        integral = Integrator(; k = K_I, initType = :InitialOutput, y_start = y_start)
        proportional = Gain(; k = K_P)
        PI_add = Add()
        reset_switch = Switch()
        realExpression = RealExpression()
        limiter = Limiter(; uMax = V_RMAX, uMin = V_RMIN)
        or1 = Or()
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        voltage_dip(t), [description = "Connector of Boolean input signal (0/1)"]
        y(t), [description = "Connector of Real output signal"]
    end
    eqs = Equation[
        or1.u2 ~ 0,                      # the .mo's reset condition, never true in OpenModelica (F-44, F-62)
        reset_switch.u1 ~ realExpression.y,   # connect(reset_switch.u1, realExpression.y)
        integral.u ~ reset_switch.y,     # connect(reset_switch.y, integral.u)
        reset_switch.u3 ~ u,             # connect(reset_switch.u3, u)
        proportional.u ~ u,              # connect(proportional.u, u)
        proportional.y ~ PI_add.u2,      # connect(proportional.y, PI_add.u2)
        limiter.u ~ PI_add.y,            # connect(PI_add.y, limiter.u)
        y ~ limiter.y,                   # connect(limiter.y, y)
        PI_add.u1 ~ integral.y,          # connect(integral.y, PI_add.u1)
        or1.u1 ~ voltage_dip,            # connect(or1.u1, voltage_dip)
        reset_switch.u2 ~ or1.y,         # connect(or1.y, reset_switch.u2)
    ]
    System(eqs, t, vars, pars; name, systems)
end
