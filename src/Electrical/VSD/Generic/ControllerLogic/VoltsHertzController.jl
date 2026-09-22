# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/VSD/Generic/ControllerLogic/VoltsHertzController.mo
# extends: Electrical/Essentials/pfComponent.mo with `enableS_b = true` and the rest false (`V_b` is nevertheless
# used by `gain2 = Gain(1/V_b)` on the input `Vc`, so it stays a keyword argument).
# The V/Hz control of a variable-speed drive: a PI on the speed error whose output, added to the measured speed,
# is the synchronous speed `we`; `we` times `Kf = 1/(2*pi*fn)` limited to [0, 1] and lagged is the modulation
# index `m`.
# **`gain2`'s output feeds nothing**: the V/Hz control does not use the DC-link voltage (sic). The input `Vc` and
# the block are instantiated anyway, because the `.mo` has them and the OpenModelica CSV carries the column.
# `Kf` is a **variable** with a binding equation in the `.mo`, not a `parameter`: it is written as an algebraic
# variable with `Kf ~ 1/(2*pi*fn)`, which `realExpression(y = Kf)` reads (F-22: the equation lives here).
# Two different start constants, both copied: `Speed_Sensor(y_start = 0.1*1.9*pi*fn)` (sic, `1.9*pi`) and
# `we(start = 0.01*2*pi*fn)`. `we`'s is a guess.
# Omitted: graphical annotations.

@component function VoltsHertzController(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0,
        v_0 = 1, angle_0 = 0, f_max = 80, f_min = 40, m0 = 0.1, Tr = 0.01, Kp = 5, Ki = 0.1)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0))
    f_max, f_min, m0, Tr, Kp, Ki = float.((f_max, f_min, m0, Tr, Kp, Ki))
    we_max = 2 * pi * f_max
    we_min = 2 * pi * f_min
    n = (; Tr, Kp, Ki, we_max, we_min, m0, V_b, sensor0 = 0.1 * 1.9 * pi * fn, we0 = 0.01 * 2 * pi * fn)
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    pars = @parameters begin
        f_max = f_max, [description = "Maximum input voltage frequency (Hz)"]
        f_min = f_min, [description = "Minimum input voltage frequency (Hz)"]
        m0 = m0, [description = "Initial PWM Modulation Value"]
        Tr = Tr, [description = "Time constant for speed sensor filter (s)"]
        Kp = Kp, [description = "PI proportional gain"]
        Ki = Ki, [description = "PI integrator gain"]
        we_max = we_max, [description = "Maximum Synchronous Speed (rad/s)"]
        we_min = we_min, [description = "Minimum Synchronous Speed (rad/s)"]
    end
    systems = @named begin
        Speed_Sensor = SimpleLag(; K = 1, T = n.Tr, y_start = n.sensor0)
        add = Add(; k1 = -1)
        limiter = Limiter(; uMax = n.we_max, uMin = n.we_min)
        gain = Gain(; k = n.Kp)
        integrator = Integrator(; k = n.Ki, initType = :InitialState, y_start = 0)
        add1 = Add(; k1 = 1)
        add2 = Add(; k1 = 1)
        gain1 = Gain(; k = 1)
        limiter1 = Limiter(; uMax = 1.0, uMin = 0.0)
        gain2 = Gain(; k = 1 / n.V_b)
        realExpression = RealExpression(; expr = nothing)   # y = Kf, a variable of this model (F-22)
        product1 = Product()
        firstOrder = FirstOrder(; T = 0.01, initType = :InitialState, y_start = n.m0)
    end
    vars = @variables begin
        motor_speed(t), [description = "Motor speed from motor model"]
        we(t), [guess = n.we0, description = "Synchronous speed (rad/s)"]
        m(t), [description = "PWM modulation index"]
        Vc(t), [description = "Capacitor voltage value"]
        W_ref(t), [description = "Synchronous speed reference (rad/s)"]
        Kf(t), [description = "Gain value multiplied with input signal"]
    end
    eqs = Equation[
        Kf ~ 1 / (2 * pi * fn),
        realExpression.y ~ Kf,
        motor_speed ~ Speed_Sensor.u,        # connect(motor_speed, Speed_Sensor.u)
        Speed_Sensor.y ~ add.u1,             # connect(Speed_Sensor.y, add.u1)
        add.y ~ gain.u,                      # connect(add.y, gain.u)
        gain.y ~ add1.u1,                    # connect(gain.y, add1.u1)
        integrator.y ~ add1.u2,              # connect(integrator.y, add1.u2)
        add2.u1 ~ Speed_Sensor.y,            # connect(add2.u1, Speed_Sensor.y)
        add.u2 ~ W_ref,                      # connect(add.u2, W_ref)
        Vc ~ gain2.u,                        # connect(Vc, gain2.u)
        gain1.u ~ we,                        # connect(gain1.u, we)
        add1.y ~ add2.u2,                    # connect(add1.y, add2.u2)
        add2.y ~ limiter.u,                  # connect(add2.y, limiter.u)
        limiter.y ~ we,                      # connect(limiter.y, we)
        integrator.u ~ add.y,                # connect(integrator.u, add.y)
        gain1.y ~ product1.u2,               # connect(gain1.y, product1.u2)
        realExpression.y ~ product1.u1,      # connect(realExpression.y, product1.u1)
        product1.y ~ limiter1.u,             # connect(product1.y, limiter1.u)
        limiter1.y ~ firstOrder.u,           # connect(limiter1.y, firstOrder.u)
        firstOrder.y ~ m,                    # connect(firstOrder.y, m)
    ]
    extend(System(eqs, t, vars, pars; name, systems), base)
end
