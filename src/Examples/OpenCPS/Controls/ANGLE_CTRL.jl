# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/OpenCPS/Controls/ANGLE_CTRL.mo
# Voltage-angle control of the resynchronization: `integrator(k = 0.01)` on `add1.y = -fi_DN + fi_IB`
# (`k1 = -1, k2 = +1` with `u1 = fi_DN`, `u2 = fi_IB`), gated by `switch1`. The gate is
# `xor(rSFlipFlop.Q, booleanStep2.y)`: the flip-flop latches on the rising `TRIGGER` (`R` is the constant false,
# so it never resets) and `booleanStep2(startTime = 45)` never fires inside a 10 s run, so the gate is simply the
# latched `TRIGGER`.
# Ports are plain variables (fi_IB, fi_DN RealInput, TRIGGER BooleanInput as Real 0/1, y RealOutput).
# Omitted: graphical annotations. No upstream Test instantiates it: hand test in test/test_OpenCPS.jl.

@component function ANGLE_CTRL(; name)
    systems = @named begin
        add1 = Add(; k1 = -1, k2 = +1)
        switch1 = Switch()
        const_ = Constant(; k = 0)          # `const` is a Julia keyword (JULIA_RENAMES, rule 6.5)
        booleanStep2 = BooleanStep(; startValue = false, startTime = 45)
        xor = Xor()
        rSFlipFlop = RSFlipFlop(; Qini = false)
        booleanConstant = BooleanConstant(; k = false)
        integrator = Integrator(; k = 0.01)
    end
    vars = @variables begin
        fi_IB(t), [description = "Connector of Real input signal"]
        fi_DN(t), [description = "Connector of Real input signal"]
        TRIGGER(t), [description = "Connector of Boolean input signal (0/1)"]
        y(t), [description = "Connector of Real output signal"]
    end
    eqs = Equation[
        add1.u2 ~ fi_IB,                 # connect(fi_IB, add1.u2)
        add1.u1 ~ fi_DN,                 # connect(fi_DN, add1.u1)
        switch1.u3 ~ const_.y,           # connect(const.y, switch1.u3)
        switch1.u1 ~ add1.y,             # connect(switch1.u1, add1.y)
        xor.u2 ~ booleanStep2.y,         # connect(booleanStep2.y, xor.u2)
        switch1.u2 ~ xor.y,              # connect(xor.y, switch1.u2)
        rSFlipFlop.S ~ TRIGGER,          # connect(rSFlipFlop.S, TRIGGER)
        xor.u1 ~ rSFlipFlop.Q,           # connect(rSFlipFlop.Q, xor.u1)
        rSFlipFlop.R ~ booleanConstant.y,   # connect(booleanConstant.y, rSFlipFlop.R)
        integrator.u ~ switch1.y,        # connect(switch1.y, integrator.u)
        y ~ integrator.y,                # connect(integrator.y, y)
    ]
    System(eqs, t, vars, []; name, systems)
end
