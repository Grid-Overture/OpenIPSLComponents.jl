# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/OpenCPS/Controls/FREQ_CTRL.mo
# Frequency control of the resynchronization. `add(k1 = +1, k2 = -1)` has `u1 = const.y = 0` and `u2 = SPEED`, so
# its output is `-SPEED`; `switch1` passes it when `xor(TRIGGER, BLOCK)` is true and `const.y = 0` otherwise;
# `unit_conv(k = 50)` turns pu speed into Hz and feeds a PI in parallel (`gain1(k = 3)` and `integrator(k = 6)`,
# both on `unit_conv.y`), whose sum is `P_REF`.
# `fREQ_CALC` is fed by `fi_IB` and its output `d_FREQ` goes nowhere (sic): the block and its two states stay in
# the system. Ported literally. `fi_0 = -0.049263488930001` is the .mo's own number.
# Ports are plain variables (SPEED, fi_IB RealInput, TRIGGER, BLOCK BooleanInput as Real 0/1, P_REF RealOutput).
# Omitted: graphical annotations. No upstream Test instantiates it: hand test in test/test_OpenCPS.jl.

@component function FREQ_CTRL(; name)
    systems = @named begin
        switch1 = Switch()
        const_ = Constant(; k = 0)          # `const` is a Julia keyword (JULIA_RENAMES, rule 6.5)
        unit_conv = Gain(; k = 50)
        xor = Xor()
        add = Add(; k2 = -1, k1 = +1)
        fREQ_CALC = FREQ_CALC(; T_w = 0.05, T_f = 3 / 2 / pi / 50, fi_0 = -0.049263488930001)
        gain1 = Gain(; k = 3)
        add1 = Add(; k2 = 1)
        integrator = Integrator(; k = 6)
    end
    vars = @variables begin
        SPEED(t), [description = "Connector of Real input signal"]
        fi_IB(t), [description = "Connector of Real input signal"]
        TRIGGER(t), [description = "Connector of Boolean input signal (0/1)"]
        BLOCK(t), [description = "Connector of Boolean input signal (0/1)"]
        P_REF(t), [description = "Connector of Real output signal"]
    end
    eqs = Equation[
        switch1.u3 ~ const_.y,        # connect(const.y, switch1.u3)
        switch1.u2 ~ xor.y,           # connect(xor.y, switch1.u2)
        xor.u1 ~ TRIGGER,             # connect(TRIGGER, xor.u1)
        switch1.u1 ~ add.y,           # connect(add.y, switch1.u1)
        add.u2 ~ SPEED,               # connect(SPEED, add.u2)
        fREQ_CALC.ANGLE ~ fi_IB,      # connect(fi_IB, fREQ_CALC.ANGLE)
        xor.u2 ~ BLOCK,               # connect(BLOCK, xor.u2)
        unit_conv.u ~ switch1.y,      # connect(switch1.y, unit_conv.u)
        add1.u2 ~ integrator.y,       # connect(integrator.y, add1.u2)
        add1.u1 ~ gain1.y,            # connect(gain1.y, add1.u1)
        P_REF ~ add1.y,               # connect(add1.y, P_REF)
        gain1.u ~ unit_conv.y,        # connect(unit_conv.y, gain1.u)
        integrator.u ~ gain1.u,       # connect(integrator.u, gain1.u)
        add.u1 ~ switch1.u3,          # connect(add.u1, switch1.u3)
    ]
    System(eqs, t, vars, []; name, systems)
end
