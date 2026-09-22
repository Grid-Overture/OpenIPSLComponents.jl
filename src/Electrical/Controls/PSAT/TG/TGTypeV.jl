# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/TG/TGTypeV.mo, blocks as subsystems (the .mo's own names kept,
# `Integral`, `Proportional`, `one`, `square` included): two `Integrator(SteadyState, y_start = Pref)`,
# `Integrator(NoInit, Pref)`, `Integrator(NoInit, 0)`, seven `Gain`, two `MultiSum(nu = 2, k = {-1, 1})`,
# `Division`, `Product`, `MultiProduct(nu = 2)` (the block this model introduces), `Constant`, two `Feedback`,
# two `Limiter`, three `Add`.
# The two `NoInit` integrators carry no initialization equation, so the initialization of a user is two equations
# short and OpenModelica fixes those states at their `y_start` (F-28); the Test supplies them through `u0`.
# `gain(y(start = 0))` and `division(y(start = 1))` are start values of a *child's* output, so they are `guesses` of
# this parent (F-20).
# The RealInput/RealOutput ports w, wref, pref, Pm are plain variables; `G` is the .mo's own display variable.
# None of the eleven parameters has a default in the .mo. Omitted: graphical annotations.

@component function TGTypeV(; name, Tg, gmax, gmin, vmax, vmin, Tp, Tw, Kp, Ki, sigma, Pref)
    Tg, gmax, gmin, vmax, vmin, Tp, Tw, Kp, Ki, sigma, Pref =
        float.((Tg, gmax, gmin, vmax, vmin, Tp, Tw, Kp, Ki, sigma, Pref))   # F-21
    pars = @parameters begin
        Tg = Tg, [description = "Servomotor droop (pu)"]
        gmax = gmax, [description = "Maximum gate opening (pu)"]
        gmin = gmin, [description = "Minimum gate opening (pu)"]
        vmax = vmax, [description = "Maximum gate opening rate (pu)"]
        vmin = vmin, [description = "Minimum gate opening rate (pu)"]
        Tp = Tp, [description = "Pilot valve time constant (s)"]
        Tw = Tw, [description = "Water starting time (s)"]
        Kp = Kp, [description = "Proportional droop (pu/pu)"]
        Ki = Ki, [description = "Integral droop (pu/pu)"]
        sigma = sigma, [description = "Permanent speed droop (pu/pu)"]
        Pref = Pref
    end
    systems = @named begin
        integrator = Integrator(; initType = :NoInit, y_start = Pref)
        gain = Gain(; k = 1 / Tg)
        integrator3 = Integrator(; initType = :SteadyState, y_start = Pref)
        gain7 = Gain(; k = 1 / Tw)
        multiSum3 = MultiSum(; k = [-1, 1], nu = 2)
        integrator4 = Integrator(; initType = :SteadyState, y_start = Pref)
        Integral = Gain(; k = Ki)
        gain9 = Gain(; k = 1 / Tp)
        multiSum6 = MultiSum(; k = [-1, 1], nu = 2)
        gain6 = Gain(; k = sigma)
        integrator5 = Integrator(; initType = :NoInit, y_start = 0)
        Proportional = Gain(; k = Kp)
        gain8 = Gain(; k = 1 / Tp)
        division = Division()
        product1 = Product()
        square = MultiProduct(; nu = 2)
        one = Constant(; k = 1)
        p_feedback = Feedback()
        limiter2 = Limiter(; uMax = vmax, uMin = vmin)
        limiter3 = Limiter(; uMax = gmax, uMin = gmin)
        add1 = Add()
        add2 = Add(; k1 = +1, k2 = -1)
        add3 = Add(; k1 = +1, k2 = -1)
        w_feedback = Feedback()
    end
    vars = @variables begin
        w(t), [description = "Rotor speed (pu)"]
        wref(t), [description = "Reference rotor speed (pu)"]
        pref(t), [description = "Reference power (pu)"]
        Pm(t), [description = "Power Pm (pu)"]
        G(t), [description = "Gate opening (pu)"]
    end
    eqs = Equation[
        G ~ limiter3.y,
        square.u[1] ~ division.y,       # connect(division.y, square.u[1])
        square.u[2] ~ division.y,       # connect(division.y, square.u[2])
        product1.u1 ~ square.y,         # connect(square.y, product1.u1)
        multiSum3.u[1] ~ square.y,      # connect(square.y, multiSum3.u[1])
        multiSum3.u[2] ~ one.y,         # connect(one.y, multiSum3.u[2])
        division.u1 ~ integrator3.y,    # connect(integrator3.y, division.u1)
        division.u2 ~ limiter3.y,       # connect(limiter3.y, division.u2)
        p_feedback.u1 ~ add1.y,         # connect(add1.y, p_feedback.u1)
        add1.u2 ~ Proportional.y,       # connect(Proportional.y, add1.u2)
        add1.u1 ~ integrator4.y,        # connect(integrator4.y, add1.u1)
        add3.u2 ~ gain8.y,              # connect(gain8.y, add3.u2)
        integrator5.u ~ add3.y,         # connect(add3.y, integrator5.u)
        add2.u1 ~ add1.y,               # connect(add1.y, add2.u1)
        p_feedback.u2 ~ pref,           # connect(pref, p_feedback.u2)
        w_feedback.u1 ~ wref,           # connect(wref, w_feedback.u1)
        w_feedback.u2 ~ w,              # connect(w, w_feedback.u2)
        multiSum6.u[1] ~ gain6.y,       # connect(gain6.y, multiSum6.u[1])
        multiSum6.u[2] ~ w_feedback.y,  # connect(w_feedback.y, multiSum6.u[2])
        gain9.u ~ multiSum6.y,          # connect(multiSum6.y, gain9.u)
        add3.u1 ~ gain9.y,              # connect(gain9.y, add3.u1)
        gain6.u ~ p_feedback.y,         # connect(gain6.u, p_feedback.y)
        gain8.u ~ integrator5.y,        # connect(integrator5.y, gain8.u)
        Proportional.u ~ integrator5.y, # connect(integrator5.y, Proportional.u)
        Integral.u ~ integrator5.y,     # connect(integrator5.y, Integral.u)
        integrator4.u ~ Integral.y,     # connect(Integral.y, integrator4.u)
        add2.u2 ~ limiter3.y,           # connect(limiter3.y, add2.u2)
        limiter2.u ~ gain.y,            # connect(gain.y, limiter2.u)
        integrator.u ~ limiter2.y,      # connect(limiter2.y, integrator.u)
        limiter3.u ~ integrator.y,      # connect(integrator.y, limiter3.u)
        gain.u ~ add2.y,                # connect(add2.y, gain.u)
        integrator3.u ~ gain7.y,        # connect(gain7.y, integrator3.u)
        gain7.u ~ multiSum3.y,          # connect(multiSum3.y, gain7.u)
        product1.u2 ~ integrator3.y,    # connect(integrator3.y, product1.u2)
        Pm ~ product1.y,                # connect(product1.y, Pm)
    ]
    System(eqs, t, vars, pars; name, systems,
        guesses = Dict(w => 1.0, wref => 1.0, pref => Pref, Pm => Pref, G => Pref,
            gain.y => 0.0, division.y => 1.0))
end
