# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/LeadLagLim.mo (block)
# Blocks: add2 = Add(k2 = 1), gain = Gain(k = T1/T2), add3 = Add(k2 = -1), integrator = Integrator(y_start, k = 1/T1,
# SteadyState), gain1 = Gain(k = T2/T1 - 1), limiter = Limiter(uMax = outMax, uMin = outMin). Ports are plain variables
# (u, y); the causal connects are equalities. Omitted: graphical annotations.

@component function LeadLagLim(; name, K, T1, T2, outMax, outMin, y_start)
    K, T1, T2, outMax, outMin, y_start = float.((K, T1, T2, outMax, outMin, y_start))
    pars = @parameters begin
        K = K, [description = "Gain"]
        T1 = T1, [description = "Lead time constant (s)"]
        T2 = T2, [description = "Lag time constant (s)"]
        outMax = outMax, [description = "Maximum output value"]
        outMin = outMin, [description = "Minimum output value"]
        y_start = y_start, [description = "Output start value"]
    end
    systems = @named begin
        add2 = Add(; k2 = 1)
        gain = Gain(; k = T1 / T2)
        add3 = Add(; k2 = -1)
        integrator = Integrator(; y_start, k = 1 / T1, initType = :SteadyState)
        gain1 = Gain(; k = T2 / T1 - 1)
        limiter = Limiter(; uMax = outMax, uMin = outMin)
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    eqs = Equation[
        gain.u ~ add2.y,           # connect(add2.y, gain.u)
        integrator.u ~ add3.y,     # connect(integrator.u, add3.y)
        add3.u2 ~ integrator.y,    # connect(integrator.y, add3.u2)
        gain1.u ~ add3.u2,         # connect(gain1.u, add3.u2)
        add2.u2 ~ gain1.y,         # connect(gain1.y, add2.u2)
        add2.u1 ~ u,               # connect(u, add2.u1)
        limiter.u ~ gain.y,        # connect(gain.y, limiter.u)
        y ~ limiter.y,             # connect(limiter.y, y)
        add3.u1 ~ y,               # connect(add3.u1, y)
    ]
    System(eqs, t, vars, pars; name, systems)
end
