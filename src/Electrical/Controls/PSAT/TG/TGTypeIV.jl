# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/TG/TGTypeIV.mo, blocks as subsystems (the .mo's own names kept):
# five `Integrator(NoInit)` (y_start int1..int5), nine `Gain` (`G6` keeps its name), three `Feedback`, two `Limiter`,
# three `Add`, one `Add3`, one `Constant`. The output port is called `Pm` (capital, sic).
# The protected parameters int1..int5 are Julia arithmetic before `@parameters` (F-22, point 1).
# The five integrators keep MSL's `NoInit`, so the initialization of a user is five equations short and OpenModelica
# fixes those states at their `y_start` (F-28); the Test supplies them through `u0`.
# The RealInput/RealOutput ports w, Pm are plain variables; `deltaG` and `v` are the .mo's own display variables.
# None of the eighteen parameters has a default in the .mo. Omitted: graphical annotations.

@component function TGTypeIV(; name, wref, Tg, gmax, gmin, vmax, vmin, Tp, Tr, sigma, delta, Tw, a11, a13, a21, a23,
        Kp, Ki, Pref)
    wref, Tg, gmax, gmin, vmax, vmin, Tp, Tr, sigma, delta, Tw, a11, a13, a21, a23, Kp, Ki, Pref =
        float.((wref, Tg, gmax, gmin, vmax, vmin, Tp, Tr, sigma, delta, Tw, a11, a13, a21, a23, Kp, Ki, Pref))  # F-21
    int1 = sigma * Pref
    int2 = 0.0
    int3 = Pref
    int4 = Tr * Pref
    int5 = a13 * a21 / a11 * Pref
    pars = @parameters begin
        wref = wref, [description = "Reference speed (pu)"]
        Tg = Tg, [description = "Pilot valve droop (pu)"]
        gmax = gmax, [description = "Maximum gate opening (pu)"]
        gmin = gmin, [description = "Minimum gate opening (pu)"]
        vmax = vmax, [description = "Maxmimum gate opening rate (pu)"]
        vmin = vmin, [description = "Maximum gate opening rate (pu)"]
        Tp = Tp, [description = "Pilot valve time constant (s)"]
        Tr = Tr, [description = "Dashpot time constant (s)"]
        sigma = sigma, [description = "Permanent speed droop (pu/pu)"]
        delta = delta, [description = "Transient speed droop (pu/pu)"]
        Tw = Tw, [description = "Water starting time (s)"]
        a11 = a11, [description = "Deriv. of flow rate vs. turbine head"]
        a13 = a13, [description = "Deriv. of flow rate vs. gate position"]
        a21 = a21, [description = "Deriv. of torque vs. turbine head"]
        a23 = a23, [description = "Deriv. of torque vs. gate position"]
        Kp = Kp, [description = "Proportional droop"]
        Ki = Ki, [description = "Integral droop"]
        Pref = Pref
        int1 = int1, [description = "sigma*Pref"]
        int2 = int2
        int3 = int3, [description = "Pref"]
        int4 = int4, [description = "Tr*Pref"]
        int5 = int5, [description = "a13*a21/a11*Pref"]
    end
    systems = @named begin
        integrator3 = Integrator(; initType = :NoInit, y_start = int3)
        gain = Gain(; k = 1 / (Tg * Tp))
        gain1 = Gain(; k = 1 / Tp)
        integrator2 = Integrator(; initType = :NoInit, y_start = int2)
        feedback = Feedback()
        gain2 = Gain(; k = delta + sigma)
        gain3 = Gain(; k = delta / Tr)
        gain5 = Gain(; k = 1 / Tr)
        integrator4 = Integrator(; initType = :NoInit, y_start = int4)
        feedback1 = Feedback()
        gain4 = Gain(; k = 1 / (a11 * Tw))
        integrator5 = Integrator(; initType = :NoInit, y_start = int5)
        feedback2 = Feedback()
        G6 = Gain(; k = (a11 * a23 - a13 * a21) / a11)
        gain7 = Gain(; k = a13 * a21 / (a11 * a11 * Tw))
        integrator1 = Integrator(; initType = :NoInit, y_start = int1)
        gain6 = Gain(; k = Ki)
        gain8 = Gain(; k = Kp)
        limiter = Limiter(; uMax = vmax, uMin = vmin)
        limiter1 = Limiter(; uMax = gmax, uMin = gmin)
        add1 = Add(; k1 = +1, k2 = -1)
        add2 = Add()
        add3_1 = Add3(; k1 = -1, k2 = +1, k3 = +1)
        add3 = Add()
        const1 = Constant(; k = wref)
    end
    vars = @variables begin
        w(t), [description = "Rotor speed (pu)"]
        Pm(t), [description = "Mechanical power (pu)"]
        deltaG(t), [description = "Gate position variation (pu)"]
        v(t), [description = "Gate opening rate (pu)"]
    end
    eqs = Equation[
        deltaG ~ limiter1.y,
        v ~ limiter.y,
        feedback.u2 ~ gain1.y,          # connect(gain1.y, feedback.u2)
        integrator2.u ~ feedback.y,     # connect(feedback.y, integrator2.u)
        feedback.u1 ~ gain.y,           # connect(gain.y, feedback.u1)
        feedback1.u2 ~ gain5.y,         # connect(gain5.y, feedback1.u2)
        integrator4.u ~ feedback1.y,    # connect(feedback1.y, integrator4.u)
        gain3.u ~ integrator4.y,        # connect(integrator4.y, gain3.u)
        feedback2.u2 ~ gain4.y,         # connect(gain4.y, feedback2.u2)
        integrator5.u ~ feedback2.y,    # connect(feedback2.y, integrator5.u)
        feedback2.u1 ~ gain7.y,         # connect(gain7.y, feedback2.u1)
        gain1.u ~ integrator2.y,        # connect(gain1.u, integrator2.y)
        gain5.u ~ integrator4.y,        # connect(integrator4.y, gain5.u)
        gain4.u ~ integrator5.y,        # connect(integrator5.y, gain4.u)
        integrator1.u ~ gain6.y,        # connect(gain6.y, integrator1.u)
        integrator3.u ~ limiter.y,      # connect(limiter.y, integrator3.u)
        limiter.u ~ integrator2.y,      # connect(integrator2.y, limiter.u)
        limiter1.u ~ integrator3.y,     # connect(integrator3.y, limiter1.u)
        gain2.u ~ limiter1.y,           # connect(limiter1.y, gain2.u)
        feedback1.u1 ~ limiter1.y,      # connect(limiter1.y, feedback1.u1)
        gain8.u ~ add1.y,               # connect(add1.y, gain8.u)
        gain6.u ~ add1.y,               # connect(add1.y, gain6.u)
        add1.u2 ~ w,                    # connect(add1.u2, w)
        add2.u2 ~ integrator1.y,        # connect(integrator1.y, add2.u2)
        add2.u1 ~ gain8.y,              # connect(add2.u1, gain8.y)
        add3_1.u1 ~ gain2.y,            # connect(gain2.y, add3_1.u1)
        add3_1.u2 ~ add2.y,             # connect(add2.y, add3_1.u2)
        add3_1.u3 ~ gain3.y,            # connect(add3_1.u3, gain3.y)
        add3.u1 ~ G6.y,                 # connect(G6.y, add3.u1)
        add3.u2 ~ integrator5.y,        # connect(integrator5.y, add3.u2)
        Pm ~ add3.y,                    # connect(add3.y, Pm)
        G6.u ~ limiter1.y,              # connect(limiter1.y, G6.u)
        gain7.u ~ limiter1.y,           # connect(limiter1.y, gain7.u)
        add1.u1 ~ const1.y,             # connect(const1.y, add1.u1)
        gain.u ~ add3_1.y,              # connect(add3_1.y, gain.u)
    ]
    System(eqs, t, vars, pars; name, systems, guesses = Dict(w => 1.0, Pm => Pref, deltaG => Pref, v => 0.0))
end
