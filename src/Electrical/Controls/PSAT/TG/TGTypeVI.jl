# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/TG/TGTypeVI.mo, blocks as subsystems (the .mo's own names kept,
# `Proportional`, `Gain10`, `one`, `square`, `w_fb`, `servo_fb` included; `const` -> `const_`):
# three `Integrator(NoInit)` (y_start po*(gmax - gmin), po, po*(gmax - gmin)), `Derivative(k = Kd, T = Td)`,
# `TransferFunction(a = {Ta, 1}, b = {Ka})`, three `MultiSum` with their own `k`, `MultiProduct(nu = 2)`,
# `Division`, `Product`, five `Gain`, four `Feedback`, two `Limiter`, two `Constant`, `RealToBoolean(0.5)` and
# `Switch`.
# The `RealToBoolean` + `Switch` pair selects between the gate opening and `pe - pref` according to `const_(k = dref)`;
# with `dref = 0` (its value in the only Test) the `pe - pref` branch wins. Both blocks are instantiated literally and
# `mtkcompile` reduces them.
# `Derivative` decides its `zeroGain` branch in Julia from the numeric `k`, so with `Kd = 0` it contributes nothing
# (the Test's value).
# The three integrators keep MSL's `NoInit`, so the initialization of a user is three equations short and
# OpenModelica fixes those states at their `y_start` (F-28); the Test supplies them through `u0`.
# The RealInput/RealOutput ports pe, pref, wref, we, Pm are plain variables; `G` is the .mo's own display variable.
# None of the sixteen parameters has a default in the .mo. Omitted: graphical annotations.

@component function TGTypeVI(; name, gmax, gmin, vmax, vmin, Ta, Tw, beta, Kp, Ki, Kd, Td, Rp, Ka, dref, po)
    gmax, gmin, vmax, vmin, Ta, Tw, beta, Kp, Ki, Kd, Td, Rp, Ka, dref, po =
        float.((gmax, gmin, vmax, vmin, Ta, Tw, beta, Kp, Ki, Kd, Td, Rp, Ka, dref, po))   # F-21
    tf_a, tf_b = [Ta, 1.0], [Ka]
    y_int = po * (gmax - gmin)
    Kdn, Tdn = Kd, Td   # `Derivative` decides its zeroGain branch in Julia from the numeric k (F-22, point 1)
    pars = @parameters begin
        gmax = gmax, [description = "Maximum gate opening (pu)"]
        gmin = gmin, [description = "Minimum gate opening (pu)"]
        vmax = vmax, [description = "Maximum gate opening rate (pu)"]
        vmin = vmin, [description = "Minimum gate opening rate (pu)"]
        Ta = Ta, [description = "Pilot valve time constant (s)"]
        Tw = Tw, [description = "Water starting time (s)"]
        beta = beta, [description = "Transient speed droop (pu/pu)"]
        Kp = Kp, [description = "Proportional droop (pu/pu)"]
        Ki = Ki, [description = "Integral droop (1/s)"]
        Kd = Kd, [description = "Derivative droop (s)"]
        Td = Td, [description = "Derivative droop time constant (s)"]
        Rp = Rp, [description = "Permanent droop (pu/pu)"]
        Ka = Ka, [description = "Pilot valve gain (pu/pu)"]
        dref = dref
        po = po
    end
    systems = @named begin
        integrator = Integrator(; initType = :NoInit, y_start = y_int)
        one = Constant(; k = 1)
        feedback = Feedback()
        integrator3 = Integrator(; initType = :NoInit, y_start = po)
        multiSum3 = MultiSum(; nu = 2, k = [1, -1])
        gain9 = Gain(; k = Kp)
        multiSum5 = MultiSum(; k = [1, 1, 1], nu = 3)
        feedback1 = Feedback()
        gain6 = Gain(; k = Rp)
        w_fb = Feedback()
        integrator5 = Integrator(; initType = :NoInit, y_start = y_int)
        Proportional = Gain(; k = beta)
        gain8 = Gain(; k = Ki)
        limiter = Limiter(; uMax = vmax, uMin = vmin)
        limiter1 = Limiter(; uMax = gmax, uMin = gmin)
        division = Division()
        product1 = Product()
        square = MultiProduct(; nu = 2)
        derivative = Derivative(; k = Kdn, T = Tdn)
        transferFunction = TransferFunction(; a = tf_a, b = tf_b)
        servo_fb = Feedback()
        Gain10 = Gain(; k = 1 / (gmax - gmin))
        multiSum4 = MultiSum(; nu = 2, k = [-1, 1])
        gain7 = Gain(; k = 1 / Tw)
        switch1 = Switch()
        realToBoolean = RealToBoolean(; threshold = 0.5)
        const_ = Constant(; k = dref)
    end
    vars = @variables begin
        pe(t), [description = "Active power (pu)"]
        pref(t), [description = "Active power reference (pu)"]
        wref(t), [description = "Rotor speed reference (pu)"]
        we(t), [description = "Rotor speed (pu)"]
        Pm(t), [description = "Mechanical power (pu)"]
        G(t), [description = "Gate opening (pu)"]
    end
    eqs = Equation[
        G ~ Gain10.y,
        square.u[1] ~ division.y,          # connect(division.y, square.u[1])
        square.u[2] ~ division.y,          # connect(division.y, square.u[2])
        multiSum3.u[1] ~ square.y,         # connect(square.y, multiSum3.u[1])
        Pm ~ product1.y,                   # connect(product1.y, Pm)
        integrator5.u ~ gain8.y,           # connect(gain8.y, integrator5.u)
        gain9.u ~ feedback1.y,             # connect(feedback1.y, gain9.u)
        gain8.u ~ feedback1.y,             # connect(feedback1.y, gain8.u)
        derivative.u ~ feedback1.y,        # connect(feedback1.y, derivative.u)
        Gain10.u ~ limiter1.y,             # connect(limiter1.y, Gain10.u)
        multiSum3.u[2] ~ Proportional.y,   # connect(Proportional.y, multiSum3.u[2])
        multiSum4.u[1] ~ multiSum3.y,      # connect(multiSum3.y, multiSum4.u[1])
        multiSum4.u[2] ~ one.y,            # connect(one.y, multiSum4.u[2])
        gain7.u ~ multiSum4.y,             # connect(multiSum4.y, gain7.u)
        integrator3.u ~ gain7.y,           # connect(gain7.y, integrator3.u)
        product1.u1 ~ multiSum3.y,         # connect(multiSum3.y, product1.u1)
        gain6.u ~ switch1.y,               # connect(switch1.y, gain6.u)
        switch1.u1 ~ limiter1.y,           # connect(limiter1.y, switch1.u1)
        Proportional.u ~ w_fb.y,           # connect(w_fb.y, Proportional.u)
        division.u1 ~ integrator3.y,       # connect(integrator3.y, division.u1)
        servo_fb.u2 ~ limiter1.y,          # connect(limiter1.y, servo_fb.u2)
        w_fb.u2 ~ we,                      # connect(we, w_fb.u2)
        w_fb.u1 ~ wref,                    # connect(wref, w_fb.u1)
        switch1.u3 ~ feedback.y,           # connect(feedback.y, switch1.u3)
        feedback.u1 ~ pe,                  # connect(pe, feedback.u1)
        feedback.u2 ~ pref,                # connect(pref, feedback.u2)
        switch1.u2 ~ realToBoolean.y,      # connect(switch1.u2, realToBoolean.y)
        realToBoolean.u ~ const_.y,        # connect(realToBoolean.u, const.y)
        feedback1.u2 ~ gain6.y,            # connect(feedback1.u2, gain6.y)
        feedback1.u1 ~ w_fb.y,             # connect(w_fb.y, feedback1.u1)
        multiSum5.u[1] ~ gain9.y,          # connect(gain9.y, multiSum5.u[1])
        multiSum5.u[2] ~ integrator5.y,    # connect(integrator5.y, multiSum5.u[2])
        multiSum5.u[3] ~ derivative.y,     # connect(derivative.y, multiSum5.u[3])
        servo_fb.u1 ~ multiSum5.y,         # connect(multiSum5.y, servo_fb.u1)
        transferFunction.u ~ servo_fb.y,   # connect(servo_fb.y, transferFunction.u)
        limiter.u ~ transferFunction.y,    # connect(transferFunction.y, limiter.u)
        integrator.u ~ limiter.y,          # connect(limiter.y, integrator.u)
        limiter1.u ~ integrator.y,         # connect(integrator.y, limiter1.u)
        division.u2 ~ Gain10.y,            # connect(Gain10.y, division.u2)
        product1.u2 ~ integrator3.y,       # connect(integrator3.y, product1.u2)
    ]
    System(eqs, t, vars, pars; name, systems,
        guesses = Dict(pe => po, pref => po, wref => 1.0, we => 1.0, Pm => po, G => po))
end
