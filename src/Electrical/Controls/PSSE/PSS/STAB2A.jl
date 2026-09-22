# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/PSS/STAB2A.mo (extends nothing: its two ports are its own)
# Ports as plain variables: PELEC (input), VOTHSG (output). It does not extend `BasePSS`: it has one input, not two.
# Blocks: transferFunction = TransferFunction(b = {-K_2*T_2, 0}, a = {T_2, 1}, SteadyState),
# transferFunction1/transferFunction2 = TransferFunction(b = {K_2*T_2, 0}, a = {T_2, 1}, SteadyState),
# transferFunction3 = TransferFunction(b = {K_3}, a = {T_3, 1}, SteadyState),
# transferFunction4/transferFunction5 = TransferFunction(b = {K_5}, a = {T_5, 1}, SteadyState),
# K = Gain(K_4) (instance `K_`: the name would shadow the block inside the constructor), add = Add,
# limiter = Limiter(+-H_LIM). The causal connects are equalities.
# The six filters initialize with `Init.SteadyState` (`der(x) = 0`), the only models of the port that do; with a
# constant PELEC the three washouts then start at zero output and `VOTHSG = 0`.
# No Test of OpenIPSL 3.1.0 instantiates `STAB2A` and no other model uses it: it is validated by
# `test/test_STAB2A.jl`. Omitted: graphical annotations.

@component function STAB2A(; name, K_2 = 1, T_2 = 1, K_3 = 1, T_3 = 1, K_4 = 1, K_5 = 1, T_5 = 1, H_LIM = 5)
    K_2, T_2, K_3, T_3, K_4, K_5, T_5, H_LIM = float.((K_2, T_2, K_3, T_3, K_4, K_5, T_5, H_LIM))
    wo_b, wo_a = [-K_2 * T_2, 0.0], [T_2, 1.0]
    wi_b = [K_2 * T_2, 0.0]
    lp3_b, lp3_a = [K_3], [T_3, 1.0]
    lp5_b, lp5_a = [K_5], [T_5, 1.0]
    n = (; K_4, H_LIM)
    pars = @parameters begin
        K_2 = K_2, [description = "Input washout filter gain"]
        T_2 = T_2, [description = "Input washout filter time constant"]
        K_3 = K_3, [description = "Low-pass filter proportional gain"]
        T_3 = T_3, [description = "Low-pass filter time constant"]
        K_4 = K_4, [description = "Washout filter output proportional gain"]
        K_5 = K_5, [description = "Output low-pass filter proportional gain"]
        T_5 = T_5, [description = "Output low-pass filter time constant"]
        H_LIM = H_LIM, [description = "Limit value for stabilizer output"]
    end
    K_ = Gain(; name = :K, k = n.K_4)   # the .mo instance is named `K`
    systems = @named begin
        transferFunction = TransferFunction(; b = wo_b, a = wo_a, initType = :SteadyState)
        transferFunction1 = TransferFunction(; a = wo_a, initType = :SteadyState, b = wi_b)
        transferFunction2 = TransferFunction(; a = wo_a, initType = :SteadyState, b = wi_b)
        transferFunction3 = TransferFunction(; initType = :SteadyState, b = lp3_b, a = lp3_a)
        transferFunction4 = TransferFunction(; initType = :SteadyState, b = lp5_b, a = lp5_a)
        transferFunction5 = TransferFunction(; initType = :SteadyState, b = lp5_b, a = lp5_a)
        add = Add()
        limiter = Limiter(; uMax = n.H_LIM, uMin = -n.H_LIM)
    end
    push!(systems, K_)
    vars = @variables begin
        PELEC(t), [description = "Machine electrical power [pu]"]
        VOTHSG(t), [description = "PSS output signal"]
    end
    eqs = Equation[
        PELEC ~ transferFunction.u,                 # connect(PELEC, transferFunction.u)
        transferFunction.y ~ transferFunction1.u,   # connect(transferFunction.y, transferFunction1.u)
        transferFunction1.y ~ transferFunction2.u,  # connect(transferFunction1.y, transferFunction2.u)
        transferFunction2.y ~ transferFunction3.u,  # connect(transferFunction2.y, transferFunction3.u)
        transferFunction4.y ~ transferFunction5.u,  # connect(transferFunction4.y, transferFunction5.u)
        K_.u ~ transferFunction2.y,                 # connect(K.u, transferFunction2.y)
        add.y ~ transferFunction4.u,                # connect(add.y, transferFunction4.u)
        transferFunction3.y ~ add.u1,               # connect(transferFunction3.y, add.u1)
        K_.y ~ add.u2,                              # connect(K.y, add.u2)
        transferFunction5.y ~ limiter.u,            # connect(transferFunction5.y, limiter.u)
        VOTHSG ~ limiter.y,                         # connect(VOTHSG, limiter.y)
    ]
    System(eqs, t, vars, pars; name, systems)
end
