# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/PI_No_Windup.mo (model)
# Blocks: integral = Integrator(k = K_I, InitialOutput, y_start = y_start_int), proportional = Gain(k = K_P),
# add = MultiSum(nu), limiter = Limiter(uMax = V_RMAX, uMin = V_RMIN), reset_switch = Switch, zero = RealExpression.
# Ports are plain variables (u, y; SISO). `nu` (2) is a keyword argument so that PID_No_Windup can extend this model
# with add(nu = 3). The .mo's anti-windup `reset_switch.u2 = if abs(V_RMAX - y) <= eps and der(integral.y) > 0 then
# true elseif abs(V_RMIN - y) <= eps and der(integral.y) < 0 then true else false` is NOT reproduced: OpenModelica
# 1.25 never sets it (the `abs(...) <= eps` relation of F-40, and the Boolean has no consistent value anyway: with the
# switch selecting zero the derivative is zero), so the integrator winds up while the output stays clamped - verified
# on the DC4B and AC7B oracles, 1381 and 2075 saturated rows with `reset_switch.u2 = 0` throughout (F-44). Written
# literally, the self-referential equation has no solution at saturation and the DAE solve aborts (DC4B at the fault).
# The switch stays, with `u2 = 0`, so the block keeps the .mo's instances and variable names. Omitted: graphical
# annotations.

@component function PI_No_Windup(; name, K_P, K_I, V_RMAX, V_RMIN, y_start_int, nu = 2)
    K_P, K_I, V_RMAX, V_RMIN, y_start_int = float.((K_P, K_I, V_RMAX, V_RMIN, y_start_int))
    pars = @parameters begin
        K_P = K_P, [description = "Voltage regulator proportional gain"]
        K_I = K_I, [description = "Voltage regulator integral gain"]
        V_RMAX = V_RMAX, [description = "Maximum regulator output"]
        V_RMIN = V_RMIN, [description = "Minimum regulator output"]
        y_start_int = y_start_int, [description = "Initial output value"]
    end
    systems = @named begin
        integral = Integrator(; k = K_I, initType = :InitialOutput, y_start = y_start_int)
        proportional = Gain(; k = K_P)
        add = MultiSum(; nu)
        limiter = Limiter(; uMax = V_RMAX, uMin = V_RMIN)
        reset_switch = Switch()
        zero = RealExpression()
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    eqs = Equation[
        reset_switch.u2 ~ 0,             # the .mo's reset condition, never true in OpenModelica (F-44, header)
        limiter.u ~ add.y,               # connect(add.y, limiter.u)
        reset_switch.u1 ~ zero.y,        # connect(reset_switch.u1, zero.y)
        integral.u ~ reset_switch.y,     # connect(reset_switch.y, integral.u)
        reset_switch.u3 ~ u,             # connect(u, reset_switch.u3)
        proportional.u ~ u,              # connect(proportional.u, u)
        y ~ limiter.y,                   # connect(limiter.y, y)
        add.u[1] ~ integral.y,           # connect(integral.y, add.u[1])
        add.u[2] ~ proportional.y,       # connect(proportional.y, add.u[2])
    ]
    System(eqs, t, vars, pars; name, systems)
end
