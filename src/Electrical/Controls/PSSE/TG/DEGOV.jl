# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/DEGOV.mo (extends TG/BaseClasses/BaseGovernor.mo)
# Blocks: transferFunction = TransferFunction(b = {-T3, -1}, a = {T2*T1, T1, 1}, InitialOutput, y_start = 0),
# integrator = Integrator(k = K, y_start = P0), leadLag = LeadLag(K = 1, T1 = T4, T2 = T5, y_start = P0),
# simpleLagLim = SimpleLagLim(K = 1, T = T6, y_start = P0, TMAX, TMIN), fixedDelay = FixedDelay(delayTime = TD),
# product1 = Product, add = Add, Constant = Constant(k = 1). The causal connects are equalities.
# The `.mo`'s instance is literally named `Constant`, which in Julia would shadow the block's own constructor inside
# the `@named` block: it is built with an explicit `name = :Constant` outside it, so the hierarchical name is the
# `.mo`'s.
# `P0(fixed = false)` is `initial equation P0 = PMECH0`, an input: a `missing` parameter with its equation in
# `initialization_eqs` (F-33), passed symbolically to the three blocks that start from it (F-38).
# With `TD > 0` the model is a delay-differential system (F-20 d, F-49): it is simulated as a `DDEProblem` with
# `constant_lags = [TD]` and `MethodOfSteps(Rodas5P())`; with `TD = 0` the `FixedDelay` degenerates to `y = u` and
# the model is an ODE. Because it also carries a `SimpleLagLim`, whose anti-windup events ModelingToolkit cannot
# evaluate inside a delayed system (F-51), the DDE path only works while that limiter does not have to act; the
# Julia-only `pade` keyword (forwarded to `FixedDelay`) is the fallback that turns the model into an ODE.
# No Test of OpenIPSL 3.1.0 instantiates `DEGOV` and no other model uses it: it is validated by
# `test/test_DEGOV.jl`. Omitted: graphical annotations.

@component function DEGOV(; name, T1, T2, T3, K, T4, T5, T6, TD, TMAX, TMIN, pade = 0)
    T1, T2, T3, K, T4, T5, T6, TD, TMAX, TMIN = float.((T1, T2, T3, K, T4, T5, T6, TD, TMAX, TMIN))
    n = (; T1, T2, T3, K, T4, T5, T6, TD, TMAX, TMIN)   # numeric copies for the sub-blocks (F-22)
    @named base = BaseGovernor()
    @unpack SPEED, PMECH0, PMECH = base
    pars = @parameters begin
        T1 = T1, [description = "Governor Mechanism Time Constant"]
        T2 = T2, [description = "Turbine Power Time Constant"]
        T3 = T3, [description = "Turbine Exhaust Temperature Time Constant"]
        K = K, [description = "Governor Gain"]
        T4 = T4, [description = "Governor Lead Time Constant"]
        T5 = T5, [description = "Governor Lag Time Constant"]
        T6 = T6, [description = "Actuator Time Constant"]
        TD = TD, [description = "Engine Time Delay"]
        TMAX = TMAX, [description = "Upper Limit"]
        TMIN = TMIN, [description = "Lower Limit"]
        P0, [guess = 1.0, description = "Power reference of the governor"]
    end
    Constant_ = Constant(; name = :Constant, k = 1)   # the .mo instance is named `Constant`
    systems = @named begin
        transferFunction = TransferFunction(; b = [-n.T3, -1.0], a = [n.T2 * n.T1, n.T1, 1.0],
            initType = :InitialOutput, y_start = 0)
        integrator = Integrator(; k = n.K, y_start = P0)
        leadLag = LeadLag(; K = 1, T1 = n.T4, T2 = n.T5, y_start = P0)
        simpleLagLim = SimpleLagLim(; K = 1, T = n.T6, y_start = P0, outMax = n.TMAX, outMin = n.TMIN)
        fixedDelay = FixedDelay(; delayTime = n.TD, pade)
        product1 = Product()
        add = Add()
    end
    push!(systems, Constant_)
    eqs = Equation[
        SPEED ~ transferFunction.u,          # connect(SPEED, transferFunction.u)
        transferFunction.y ~ integrator.u,   # connect(transferFunction.y, integrator.u)
        integrator.y ~ leadLag.u,            # connect(integrator.y, leadLag.u)
        leadLag.y ~ simpleLagLim.u,          # connect(leadLag.y, simpleLagLim.u)
        simpleLagLim.y ~ fixedDelay.u,       # connect(simpleLagLim.y, fixedDelay.u)
        fixedDelay.y ~ product1.u1,          # connect(fixedDelay.y, product1.u1)
        Constant_.y ~ add.u1,                # connect(Constant.y, add.u1)
        add.u2 ~ transferFunction.u,         # connect(add.u2, transferFunction.u)
        add.y ~ product1.u2,                 # connect(add.y, product1.u2)
        product1.y ~ PMECH,                  # connect(product1.y, PMECH)
    ]
    extend(System(eqs, t, [], pars; name, systems, initial_conditions = Dict(P0 => missing),
        initialization_eqs = [P0 ~ PMECH0]), base)
end
