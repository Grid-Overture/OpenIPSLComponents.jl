# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/OpenCPS/Controls/VOLT_CTRL.mo
# Voltage-magnitude control of the resynchronization: a PI (`gain(k = 1)` + `integrator(k = 2)`) on `u1 - u2`,
# switched on by `booleanStep(startTime = 2)` -- before t = 2 s the switch passes `const1.y = 0` and the whole
# control, integrator included, sits at zero.
# Ports are plain variables (u1, u2 RealInput, y RealOutput). Omitted: graphical annotations.
# No upstream Test instantiates it: hand test in test/test_OpenCPS.jl.

@component function VOLT_CTRL(; name)
    systems = @named begin
        add = Add(; k2 = -1)
        switch1 = Switch()
        booleanStep = BooleanStep(; startValue = false, startTime = 2)
        const1 = Constant(; k = 0)
        gain = Gain(; k = 1)
        add1 = Add(; k2 = 1)
        integrator = Integrator(; k = 2)
    end
    vars = @variables begin
        u1(t), [description = "Connector of Real input signal 1"]
        u2(t), [description = "Connector of Real input signal 2"]
        y(t), [description = "Connector of Real output signal"]
    end
    eqs = Equation[
        switch1.u3 ~ const1.y,        # connect(const1.y, switch1.u3)
        add.u1 ~ u1,                  # connect(u1, add.u1)
        add.u2 ~ u2,                  # connect(u2, add.u2)
        gain.u ~ switch1.y,           # connect(gain.u, switch1.y)
        switch1.u1 ~ add.y,           # connect(add.y, switch1.u1)
        integrator.u ~ switch1.y,     # connect(integrator.u, switch1.y)
        y ~ add1.y,                   # connect(add1.y, y)
        add1.u2 ~ integrator.y,       # connect(integrator.y, add1.u2)
        add1.u1 ~ gain.y,             # connect(gain.y, add1.u1)
        switch1.u2 ~ booleanStep.y,   # connect(booleanStep.y, switch1.u2)
    ]
    System(eqs, t, vars, []; name, systems)
end
