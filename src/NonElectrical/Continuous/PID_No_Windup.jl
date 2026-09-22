# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/PID_No_Windup.mo (model; extends PI_No_Windup(add(nu = 3)))
# Blocks: gain1 = Gain(k = K_D*kd), derivative_add = Add(k2 = -1), derivative = Integrator(InitialOutput, y_start = 0),
# gain2 = Gain(k = kd). The base is extended with `@unpack u, add = base` (F-20) and built with a plain call, not
# `@named`: `extend` merges it at this level and `@named` would scope a symbolic `y_start_int` (an exciter's
# `fixed = false` parameter) one level too far (F-39). Omitted: graphical annotations.

@component function PID_No_Windup(; name, K_P, K_I, V_RMAX, V_RMIN, y_start_int, K_D, T_D)
    K_D, T_D = float.((K_D, T_D))
    kd = T_D <= Modelica.Constants.eps ? 1.0 : 1 / T_D
    base = PI_No_Windup(; name = :base, K_P, K_I, V_RMAX, V_RMIN, y_start_int, nu = 3)
    @unpack u, add = base
    pars = @parameters begin
        K_D = K_D, [description = "Voltage regulator derivative gain"]
        T_D = T_D, [description = "Voltage regulator derivative channel time constant (s)"]
        kd = kd
    end
    systems = @named begin
        gain1 = Gain(; k = K_D * kd)
        derivative_add = Add(; k2 = -1)
        derivative = Integrator(; initType = :InitialOutput, y_start = 0)
        gain2 = Gain(; k = kd)
    end
    eqs = Equation[
        derivative_add.u1 ~ gain1.y,       # connect(gain1.y, derivative_add.u1)
        derivative_add.u2 ~ derivative.y,  # connect(derivative.y, derivative_add.u2)
        derivative.u ~ gain2.y,            # connect(gain2.y, derivative.u)
        gain1.u ~ u,                       # connect(u, gain1.u)
        gain2.u ~ derivative_add.y,        # connect(gain2.u, derivative_add.y)
        add.u[3] ~ derivative_add.y,       # connect(derivative_add.y, add.u[3])
    ]
    extend(System(eqs, t, [], pars; name, systems), base)
end
