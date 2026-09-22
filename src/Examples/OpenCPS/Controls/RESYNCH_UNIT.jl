# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/OpenCPS/Controls/RESYNCH_UNIT.mo
# The resynchronization control system of `G2`: `volt_ctrl` on (V_IB, V_DN), `angle_ctrl` on (fi_IB, fi_DN),
# `freq_ctrl` on (SPEED, fi_IB) and `aCT_UNIT` on the two differences and the speed.
#   V_CTRL = volt_ctrl.y                       -> the stabilizer input of G2's SEXS
#   P_CTRL = PMECH0 + (angle_ctrl.y + freq_ctrl.P_REF)   -> the power reference of G2's IEESGO
#   TRIGGER = aCT_UNIT.TRIGGER                 -> the breaker, and `freq_ctrl.BLOCK`
# `aCT_UNIT.START_FREQ` (the voltage check, see ACT_UNIT.jl) enables `freq_ctrl` and `START_FI` (the frequency
# check) enables `angle_ctrl`: the crossed names are the .mo's.
# Ports are plain variables (SPEED, PMECH0, fi_DN, fi_IB, V_IB, V_DN RealInput; P_CTRL, V_CTRL RealOutput;
# TRIGGER BooleanOutput as Real 0/1). Omitted: graphical annotations.
# No upstream Test instantiates it: hand test in test/test_OpenCPS.jl.

@component function RESYNCH_UNIT(; name)
    systems = @named begin
        freq_ctrl = FREQ_CTRL()
        angle_ctrl = ANGLE_CTRL()
        volt_ctrl = VOLT_CTRL()
        add = Add(; k2 = +1)
        add2 = Add(; k2 = -1)
        add3 = Add(; k2 = -1)
        aCT_UNIT = ACT_UNIT()
        add1 = Add(; k2 = +1)
    end
    vars = @variables begin
        SPEED(t), [description = "Connector of Real input signal"]
        PMECH0(t), [description = "Connector of Real input signal"]
        fi_DN(t), [description = "Connector of Real input signal"]
        fi_IB(t), [description = "Connector of Real input signal"]
        V_IB(t), [description = "Connector of Real input signal"]
        V_DN(t), [description = "Connector of Real input signal"]
        P_CTRL(t), [description = "Connector of Real output signal"]
        V_CTRL(t), [description = "Connector of Real output signal"]
        TRIGGER(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    eqs = Equation[
        add.u1 ~ PMECH0,                    # connect(PMECH0, add.u1)
        V_CTRL ~ volt_ctrl.y,               # connect(V_CTRL, volt_ctrl.y)
        volt_ctrl.u1 ~ V_IB,                # connect(V_IB, volt_ctrl.u1)
        volt_ctrl.u2 ~ V_DN,                # connect(V_DN, volt_ctrl.u2)
        angle_ctrl.fi_IB ~ fi_IB,           # connect(fi_IB, angle_ctrl.fi_IB)
        angle_ctrl.fi_DN ~ fi_DN,           # connect(fi_DN, angle_ctrl.fi_DN)
        P_CTRL ~ add.y,                     # connect(add.y, P_CTRL)
        freq_ctrl.SPEED ~ SPEED,            # connect(SPEED, freq_ctrl.SPEED)
        add2.u1 ~ volt_ctrl.u1,             # connect(add2.u1, volt_ctrl.u1)
        add2.u2 ~ volt_ctrl.u2,             # connect(add2.u2, volt_ctrl.u2)
        add3.u1 ~ angle_ctrl.fi_IB,         # connect(add3.u1, angle_ctrl.fi_IB)
        add3.u2 ~ angle_ctrl.fi_DN,         # connect(add3.u2, angle_ctrl.fi_DN)
        aCT_UNIT.VOLT_DIFF ~ add2.y,        # connect(aCT_UNIT.VOLT_DIFF, add2.y)
        aCT_UNIT.FI_DIFF ~ add3.y,          # connect(aCT_UNIT.FI_DIFF, add3.y)
        aCT_UNIT.SPEED ~ freq_ctrl.SPEED,   # connect(aCT_UNIT.SPEED, freq_ctrl.SPEED)
        TRIGGER ~ aCT_UNIT.TRIGGER,         # connect(aCT_UNIT.TRIGGER, TRIGGER)
        angle_ctrl.TRIGGER ~ aCT_UNIT.START_FI,     # connect(aCT_UNIT.START_FI, angle_ctrl.TRIGGER)
        freq_ctrl.TRIGGER ~ aCT_UNIT.START_FREQ,    # connect(aCT_UNIT.START_FREQ, freq_ctrl.TRIGGER)
        freq_ctrl.BLOCK ~ TRIGGER,          # connect(freq_ctrl.BLOCK, TRIGGER)
        freq_ctrl.fi_IB ~ angle_ctrl.fi_IB, # connect(freq_ctrl.fi_IB, angle_ctrl.fi_IB)
        add1.u1 ~ angle_ctrl.y,             # connect(angle_ctrl.y, add1.u1)
        add1.u2 ~ freq_ctrl.P_REF,          # connect(freq_ctrl.P_REF, add1.u2)
        add.u2 ~ add1.y,                    # connect(add1.y, add.u2)
    ]
    System(eqs, t, vars, []; name, systems)
end
