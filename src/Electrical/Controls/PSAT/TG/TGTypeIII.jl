# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/TG/TGTypeIII.mo, blocks as subsystems (the .mo's own names kept,
# `const` -> `const_`): four `Integrator(NoInit)` (y_start 0, 0, 0, int3), seven `Gain`, three `Feedback`, two
# `Limiter`, three `Add`, one `Add3`, two `Constant`. `G6` and `gain7` keep their .mo names.
# The four integrators keep MSL's `NoInit`, so they carry no initialization equation: the initialization of a user is
# four equations short and OpenModelica fixes those four states at their `y_start` (F-28). The Test supplies them
# through `u0`; with the Test's `P_0 = 0.1` and `int3 = 2.712336` the governor does not start in equilibrium
# (`pm(0) = 2.51` pu) and OpenModelica integrates it that way.
# The RealInput/RealOutput ports w, pm are plain variables; `deltaG` and `G` are the .mo's own display variables.
# Only `wref` has a default in the .mo; the other seventeen parameters are required keyword arguments.
# Omitted: graphical annotations.

@component function TGTypeIII(; name, P_0, wref = 1, Tg, gmax, gmin, vmax, vmin, Tp, Tr, delta, sigma, Tw, a11, a13,
        a21, a23, int3)
    P_0, wref, Tg, gmax, gmin, vmax, vmin, Tp, Tr, delta, sigma, Tw, a11, a13, a21, a23, int3 =
        float.((P_0, wref, Tg, gmax, gmin, vmax, vmin, Tp, Tr, delta, sigma, Tw, a11, a13, a21, a23, int3))   # F-21
    pars = @parameters begin
        P_0 = P_0, [description = "Active power (pu)"]
        wref = wref, [description = "Reference speed (pu)"]
        Tg = Tg, [description = "Pilot valve droop (pu)"]
        gmax = gmax, [description = "Maximum gate opening (pu)"]
        gmin = gmin, [description = "Minimum gate opening (pu)"]
        vmax = vmax, [description = "Maximum gate opening rate (pu)"]
        vmin = vmin, [description = "Minimum gate opening rate (pu)"]
        Tp = Tp, [description = "Pilot valve time constant (s)"]
        Tr = Tr, [description = "Dashpot time constant (s)"]
        delta = delta, [description = "Transient speed droop (pu/pu)"]
        sigma = sigma, [description = "Permanent speed droop (pu/pu)"]
        Tw = Tw, [description = "Water starting time (s)"]
        a11 = a11, [description = "Deriv. of flow rate vs. turbine head"]
        a13 = a13, [description = "Deriv. of flow rate vs. gate position"]
        a21 = a21, [description = "Deriv. of torque vs. turbine head"]
        a23 = a23, [description = "Deriv. of torque vs. gate position"]
        int3 = int3
    end
    systems = @named begin
        integrator = Integrator(; initType = :NoInit, y_start = 0)
        gain = Gain(; k = 1 / (Tg * Tp))
        gain1 = Gain(; k = 1 / Tp)
        integrator1 = Integrator(; initType = :NoInit, y_start = 0)
        feedback = Feedback()
        gain2 = Gain(; k = delta + sigma)
        gain3 = Gain(; k = sigma / Tr)
        gain5 = Gain(; k = 1 / Tr)
        integrator2 = Integrator(; initType = :NoInit, y_start = 0)
        feedback1 = Feedback()
        gain4 = Gain(; k = 1 / (a11 * Tw))
        integrator3 = Integrator(; initType = :NoInit, y_start = int3)
        feedback2 = Feedback()
        G6 = Gain(; k = (a11 * a23 - a13 * a21) / a11)
        gain7 = Gain(; k = a13 * a21 / (a11 * a11 * Tw))
        limiter = Limiter(; uMax = vmax, uMin = vmin)
        limiter1 = Limiter(; uMax = gmax, uMin = gmin)
        add = Add(; k1 = +1, k2 = -1)
        add3_1 = Add3(; k1 = -1, k2 = 1, k3 = 1)
        add1 = Add()
        add2 = Add()
        const_ = Constant(; k = P_0)
        const1 = Constant(; k = wref)
    end
    vars = @variables begin
        w(t), [description = "Rotor speed (pu)"]
        pm(t), [description = "Mechanical power (pu)"]
        deltaG(t), [description = "Gate position variation (pu)"]
        G(t), [description = "Gate position (pu)"]
    end
    eqs = Equation[
        deltaG ~ limiter1.y,
        G ~ add1.y,
        feedback.u2 ~ gain1.y,          # connect(gain1.y, feedback.u2)
        integrator1.u ~ feedback.y,     # connect(feedback.y, integrator1.u)
        feedback.u1 ~ gain.y,           # connect(gain.y, feedback.u1)
        feedback1.u2 ~ gain5.y,         # connect(gain5.y, feedback1.u2)
        integrator2.u ~ feedback1.y,    # connect(feedback1.y, integrator2.u)
        gain3.u ~ integrator2.y,        # connect(integrator2.y, gain3.u)
        feedback2.u2 ~ gain4.y,         # connect(gain4.y, feedback2.u2)
        integrator3.u ~ feedback2.y,    # connect(feedback2.y, integrator3.u)
        feedback2.u1 ~ gain7.y,         # connect(gain7.y, feedback2.u1)
        gain1.u ~ integrator1.y,        # connect(gain1.u, integrator1.y)
        gain5.u ~ integrator2.y,        # connect(integrator2.y, gain5.u)
        gain4.u ~ integrator3.y,        # connect(integrator3.y, gain4.u)
        limiter.u ~ integrator1.y,      # connect(integrator1.y, limiter.u)
        integrator.u ~ limiter.y,       # connect(limiter.y, integrator.u)
        limiter1.u ~ integrator.y,      # connect(integrator.y, limiter1.u)
        feedback1.u1 ~ limiter1.y,      # connect(feedback1.u1, limiter1.y)
        gain2.u ~ limiter1.y,           # connect(limiter1.y, gain2.u)
        add.u2 ~ w,                     # connect(w, add.u2)
        add3_1.u1 ~ gain2.y,            # connect(gain2.y, add3_1.u1)
        add3_1.u2 ~ add.y,              # connect(add.y, add3_1.u2)
        add3_1.u3 ~ gain3.y,            # connect(gain3.y, add3_1.u3)
        gain.u ~ add3_1.y,              # connect(add3_1.y, gain.u)
        add1.u2 ~ limiter1.y,           # connect(limiter1.y, add1.u2)
        G6.u ~ add1.y,                  # connect(add1.y, G6.u)
        gain7.u ~ add1.y,               # connect(add1.y, gain7.u)
        add2.u1 ~ G6.y,                 # connect(G6.y, add2.u1)
        add2.u2 ~ integrator3.y,        # connect(integrator3.y, add2.u2)
        add1.u1 ~ const_.y,             # connect(const.y, add1.u1)
        add.u1 ~ const1.y,              # connect(const1.y, add.u1)
        pm ~ add2.y,                    # connect(add2.y, pm)
    ]
    System(eqs, t, vars, pars; name, systems, guesses = Dict(w => 1.0, pm => P_0, deltaG => 0.0, G => P_0))
end
