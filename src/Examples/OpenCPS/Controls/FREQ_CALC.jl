# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/OpenCPS/Controls/FREQ_CALC.mo
# Frequency out of a voltage angle: `d_FREQ` is the washed-out derivative of `ANGLE - fi_0`,
# `gain(k = 1)` -> `derivative(k = 1, T = T_f)` -> `firstOrder(k = 1, T = T_w)`, with the MSL default `initType`
# (`:NoInit` for both, as the .mo leaves them).
# `T_w`, `T_f` and `fi_0` have no default in the .mo and are required keyword arguments.
# In `FREQ_CTRL`, the only user of this block, the output `d_FREQ` is connected to nothing (sic): the block and its
# two states stay in the system and compute a value nobody reads. Ported literally.
# Ports are plain variables (ANGLE RealInput, d_FREQ RealOutput). Omitted: graphical annotations.
# No upstream Test instantiates it: hand test in test/test_OpenCPS.jl.

@component function FREQ_CALC(; name, T_w, T_f, fi_0)
    pars = @parameters begin
        T_w = T_w, [description = "Smoothing filter time constant (s)"]
        T_f = T_f, [description = "Derivative filter time constant (s)"]
        fi_0 = fi_0, [description = "Initial angle (rad)"]
    end
    systems = @named begin
        add = Add(; k2 = -1)
        const1 = Constant(; k = fi_0)
        gain = Gain(; k = 1)
        derivative = Derivative(; k = 1, T = T_f)
        firstOrder = FirstOrder(; k = 1, T = T_w)
    end
    vars = @variables begin
        ANGLE(t), [description = "Connector of Real input signal"]
        d_FREQ(t), [description = "Connector of Real output signal"]
    end
    eqs = Equation[
        add.u2 ~ const1.y,            # connect(const1.y, add.u2)
        add.u1 ~ ANGLE,               # connect(ANGLE, add.u1)
        gain.u ~ add.y,               # connect(gain.u, add.y)
        derivative.u ~ gain.y,        # connect(derivative.u, gain.y)
        firstOrder.u ~ derivative.y,  # connect(derivative.y, firstOrder.u)
        d_FREQ ~ firstOrder.y,        # connect(firstOrder.y, d_FREQ)
    ]
    System(eqs, t, vars, pars; name, systems)
end
