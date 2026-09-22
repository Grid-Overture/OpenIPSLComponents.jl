# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/ElectricalController/BaseClasses/PIwithVariableLimiter.mo
# extends: nothing. Same block as PIwithNoVariableLimiter.jl with a `VariableLimiter` in place of the fixed
# `Limiter`: the two limits are inputs (limit1, limit2). Same F-44 / F-62 treatment of the anti-windup relation
# (`or1.u2 ~ 0`; the `.mo` compares `y` against `variableLimiter1.limit1/2` instead of V_RMAX/V_RMIN, and
# OpenModelica never sets it either). Omitted: graphical annotations.

@component function PIwithVariableLimiter(; name, K_P, K_I, y_start)
    K_P, K_I = float.((K_P, K_I))
    pars = @parameters begin
        K_P = K_P, [description = "Voltage regulator proportional gain"]
        K_I = K_I, [description = "Voltage regulator integral gain"]
    end
    systems = @named begin
        integral = Integrator(; k = K_I, initType = :InitialOutput, y_start = y_start)
        proportional = Gain(; k = K_P)
        PI_add = Add()
        reset_switch = Switch()
        realExpression = RealExpression()
        variableLimiter1 = VariableLimiter()
        or1 = Or()
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        limit1(t), [description = "Connector of Real input signal used as maximum"]
        limit2(t), [description = "Connector of Real input signal used as minimum"]
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
        variableLimiter1.u ~ PI_add.y,   # connect(PI_add.y, variableLimiter1.u)
        y ~ variableLimiter1.y,          # connect(variableLimiter1.y, y)
        variableLimiter1.limit1 ~ limit1,    # connect(variableLimiter1.limit1, limit1)
        variableLimiter1.limit2 ~ limit2,    # connect(variableLimiter1.limit2, limit2)
        PI_add.u1 ~ integral.y,          # connect(integral.y, PI_add.u1)
        or1.u1 ~ voltage_dip,            # connect(or1.u1, voltage_dip)
        reset_switch.u2 ~ or1.y,         # connect(or1.y, reset_switch.u2)
    ]
    System(eqs, t, vars, pars; name, systems)
end
