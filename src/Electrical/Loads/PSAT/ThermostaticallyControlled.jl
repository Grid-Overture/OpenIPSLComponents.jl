# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSAT/ThermostaticallyControlled.mo (extends BaseClasses/baseLoad.mo)
# Blocks: NonElectrical.Continuous.SimpleLag (firstOrder), Blocks.Math.Gain (gain, gain1, gain2), Blocks.Math.Add
# (add, add1, add4), Blocks.Continuous.LimIntegrator (Limiter, InitialOutput), Blocks.Math.Product (product),
# Blocks.Nonlinear.Limiter (Limiter1), Blocks.Sources.RealExpression (realExpression, `y = v^2`: written as the
# parent's equation `realExpression.y ~ v^2`, PLAN-02). The inputs t_ref, t_a are plain variables. G0 = P_0/100*v_0^2
# and K1 = (T_ref - T0)/P_0 are OpenIPSL's own (P_0 in W); Gmin = 0, K3 = 1 are literal too. The derived parameters
# are computed before `@parameters` so that the sub-blocks receive numbers (F-22). Omitted: graphical annotations.

@component function ThermostaticallyControlled(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0, Sn = S_b, Kl = 2, Kp = 10, Ki = 25, Ti = 10, T1 = 1200, T_ref = 70, T0 = 10, K3 = 1)
    Kl, Kp, Ki, Ti, T1, T_ref, T0, K3, P_0n, v_0n = float.((Kl, Kp, Ki, Ti, T1, T_ref, T0, K3, P_0, v_0))
    G0 = P_0n / 100 * v_0n^2
    Gmax = Kl * G0
    Gmin = 0.0
    K1 = (T_ref - T0) / P_0n
    @named base = baseLoad(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn)
    @unpack v, P, Q, S_b, Q_0 = base
    # sub-blocks built before @parameters, with numbers (F-22)
    systems = @named begin
        firstOrder = SimpleLag(; K = 1, T = T1, y_start = 0)
        gain = Gain(; k = K1)
        gain1 = Gain(; k = Kp)
        add = Add(; k2 = -1, k1 = +1)
        product = Product()
        add1 = Add(; k2 = +1, k1 = +1)
        Limiter1 = OpenIPSLComponents.Limiter(; strict = false, uMax = Gmax, uMin = Gmin)   # the local `Limiter` below shadows the constructor
        add4 = Add(; k2 = +1, k1 = +1)
        gain2 = Gain(; k = K3)
        realExpression = RealExpression(; expr = nothing)
        Limiter = LimIntegrator(; outMax = Gmax, outMin = Gmin, k = Ki / Ti, limitsAtInit = true,
            initType = :InitialOutput, y_start = G0 - Kp * (T_ref - T0))
    end
    pars = @parameters begin
        Kl = Kl, [description = "Ceiling conductance output"]
        Kp = Kp, [description = "Gain of the proportional controller (pu/pu)"]
        Ki = Ki, [description = "Gain of the integral controller (pu/pu)"]
        Ti = Ti, [description = "Time constant of integral controller (s)"]
        T1 = T1, [description = "Time constant of the thermal load (s)"]
        T_ref = T_ref, [description = "Reference temperature (degC)"]
        T0 = T0, [description = "Initial temperature (degC)"]
        G0 = G0, [description = "Initial conductance (pu)"]
        Gmax = Gmax, [description = "Maximum conductance (pu)"]
        Gmin = Gmin, [description = "Minimum conductance (pu)"]
        K1 = K1, [description = "Active power gain (pu/pu)"]
        K3 = K3, [description = "Gain anti wind-up"]
    end
    vars = @variables begin
        t_ref(t), [description = "Reference temperature (degC)"]
        t_a(t), [description = "Ambient temperature (degC)"]
    end
    eqs = Equation[
        P ~ ((Limiter1.y) * (v^2)) / S_b,
        Q ~ Q_0 / S_b,
        t_ref ~ add.u1,   # connect(t_ref, add.u1)
        product.y ~ gain.u,   # connect(product.y, gain.u)
        gain1.y ~ add1.u1,   # connect(gain1.y, add1.u1)
        Limiter.y ~ add1.u2,   # connect(Limiter.y, add1.u2)
        add1.y ~ Limiter1.u,   # connect(add1.y, Limiter1.u)
        Limiter1.y ~ product.u2,   # connect(Limiter1.y, product.u2)
        gain.y ~ add4.u2,   # connect(gain.y, add4.u2)
        add4.u1 ~ t_a,   # connect(add4.u1, t_a)
        firstOrder.u ~ add4.y,   # connect(firstOrder.u, add4.y)
        gain1.u ~ add.y,   # connect(gain1.u, add.y)
        gain2.u ~ add.y,   # connect(gain2.u, add.y)
        gain2.y ~ Limiter.u,   # connect(gain2.y, Limiter.u)
        realExpression.y ~ product.u1,   # connect(realExpression.y, product.u1)
        firstOrder.y ~ add.u2,   # connect(firstOrder.y, add.u2)
        realExpression.y ~ v^2,   # realExpression(y = v^2)
    ]
    extend(System(eqs, t, vars, pars; name, systems), base)
end
