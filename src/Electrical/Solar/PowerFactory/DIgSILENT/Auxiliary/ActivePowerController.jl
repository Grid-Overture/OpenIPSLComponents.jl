# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/DIgSILENT/Auxiliary/ActivePowerController.mo (extends nothing)
# Blocks, with the names of the .mo: I = LimIntegrator(InitialOutput, k = K/T, **limitsAtInit = false**, outMax =
# yo_max, outMin = yo_min, y_start = id0) if with_I, disable = Constant(0) if not with_I, add, P = Gain(K),
# tracker = Integrator(InitialOutput, k = 1/0.1, y_start = id0), feedback, limiter, limiter1 = Limiter(yo_max,
# yo_min), product. Ports are plain variables (yi, pred; yo) plus `yo1`, `yo2`, `x`, public outputs in the .mo (the
# `//protected` is a comment, sic). `with_I = if T > 0 then true else false` is a parameter expression, decided in
# Julia (F-50; every user passes T = Tip = 0.03, the I branch). The first `limitsAtInit = false` of the port: inert
# with a `y_start` inside the limits (LimIntegrator.jl accepts the keyword). `yo = if pred < 1 then min(yo1, yo2)
# else yo1` and `if pred < 1 then tracker.u = feedback.y else tracker.u = 0` are on the **input** `pred`: symbolic
# `ifelse`; PV_Plant passes `pred = 1`, so `yo = yo1` and the tracker is a state that integrates 0, kept.
# Omitted: graphical annotations.

@component function ActivePowerController(; name, K = 0.005, T = 0.03, yo_min, yo_max, id0)
    K, T, yo_min, yo_max, id0 = float.((K, T, yo_min, yo_max, id0))
    with_I = T > 0
    systems = @named begin
        add = Add()
        P = Gain(; k = K)
        tracker = Integrator(; initType = :InitialOutput, k = 1 / 0.1, y_start = id0)
        feedback = Feedback()
        limiter = Limiter(; uMax = yo_max, uMin = yo_min)
        product = Product()
        limiter1 = Limiter(; uMax = yo_max, uMin = yo_min)
    end
    if with_I
        @named I = LimIntegrator(; initType = :InitialOutput, k = K / T, limitsAtInit = false, outMax = yo_max,
            outMin = yo_min, y_start = id0)
        push!(systems, I)
    else
        @named disable = OpenIPSLComponents.Constant(; k = 0)
        push!(systems, disable)
    end
    pars = @parameters begin
        K = K, [description = "Gain of the PI-Controller"]
        T = T, [description = "Integration Time Constant of the PI controller (s)"]
        yo_min = yo_min, [description = "Minimum d-axis current (pu)"]
        yo_max = yo_max, [description = "Maximum d-axis current (pu)"]
        id0 = id0, [description = "Initial d-axis current (pu)"]
    end
    vars = @variables begin
        yi(t), [description = "Controller input"]
        yo(t), [description = "Controller output"]
        pred(t), [description = "FRT prediction input"]
        yo1(t)
        yo2(t)
        x(t)
    end
    eqs = Equation[
        yo ~ ifelse(pred < 1, min(yo1, yo2), yo1),
        tracker.u ~ ifelse(pred < 1, feedback.y, 0),
        P.y ~ add.u1,                    # connect(P.y, add.u1)
        yi ~ P.u,                        # connect(yi, P.u)
        feedback.u2 ~ tracker.y,         # connect(feedback.u2, tracker.y)
        product.y ~ limiter.u,           # connect(product.y, limiter.u)
        product.u1 ~ tracker.y,          # connect(product.u1, tracker.y)
        pred ~ product.u2,               # connect(pred, product.u2)
        limiter.y ~ yo2,                 # connect(limiter.y, yo2)
        x ~ add.u2,                      # connect(x, add.u2)
        feedback.u1 ~ yo1,               # connect(feedback.u1, yo1)
        limiter1.u ~ add.y,              # connect(limiter1.u, add.y)
        yo1 ~ limiter1.y,                # connect(yo1, limiter1.y)
    ]
    if with_I
        push!(eqs, I.u ~ yi)             # connect(I.u, yi)
        push!(eqs, I.y ~ x)              # connect(I.y, x)
    else
        push!(eqs, disable.y ~ x)        # connect(disable.y, x)
    end
    System(eqs, t, vars, pars; name, systems)
end
