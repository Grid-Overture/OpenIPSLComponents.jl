# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/OpenCPS/Controls/ACT_UNIT.mo
# The unit that decides when the breaker may close: three `LimitCheck` with `dt = 5` s on the voltage difference
# (+-0.01), the machine speed (+-5e-5) and the angle difference (+-1 rad); their `START` flags go into
# `and1 = MathBoolean.And(nu = 3)` and set an `RSFlipFlop` whose `R` is the constant false, so `TRIGGER` latches.
# Quirk of the .mo kept: the two exported flags are crossed with their names -- `START_FREQ` is the **voltage**
# check (`v_limit_check.START`) and `START_FI` is the **frequency** one (`f_limit_check.START`); downstream,
# `RESYNCH_UNIT` feeds `START_FREQ` to `freq_ctrl.TRIGGER` and `START_FI` to `angle_ctrl.TRIGGER`.
# Ports are plain variables (VOLT_DIFF, SPEED, FI_DIFF RealInput; START_FREQ, START_FI, TRIGGER BooleanOutput as
# Real 0/1). Omitted: graphical annotations. No upstream Test instantiates it: hand test in test/test_OpenCPS.jl.

@component function ACT_UNIT(; name)
    systems = @named begin
        fi_limit_check = LimitCheck(; dt = 5, upperLim = 1, lowerLim = -1)
        v_limit_check = LimitCheck(; dt = 5, upperLim = 0.01, lowerLim = -0.01)
        f_limit_check = LimitCheck(; dt = 5, upperLim = 5e-5, lowerLim = -5e-5)
        and1 = And(; nu = 3)
        rSFlipFlop = RSFlipFlop(; Qini = false)
        disable = BooleanConstant(; k = false)
    end
    vars = @variables begin
        VOLT_DIFF(t), [description = "Connector of Real input signal"]
        SPEED(t), [description = "Connector of Real input signal"]
        FI_DIFF(t), [description = "Connector of Real input signal"]
        START_FREQ(t), [description = "Connector of Boolean output signal (0/1)"]
        START_FI(t), [description = "Connector of Boolean output signal (0/1)"]
        TRIGGER(t), [description = "Connector of Boolean output signal (0/1)"]
    end
    eqs = Equation[
        START_FREQ ~ v_limit_check.START,   # connect(START_FREQ, v_limit_check.START)
        v_limit_check.u ~ VOLT_DIFF,        # connect(VOLT_DIFF, v_limit_check.u)
        START_FI ~ f_limit_check.START,     # connect(START_FI, f_limit_check.START)
        f_limit_check.u ~ SPEED,            # connect(SPEED, f_limit_check.u)
        fi_limit_check.u ~ FI_DIFF,         # connect(FI_DIFF, fi_limit_check.u)
        and1.u[1] ~ v_limit_check.START,    # connect(and1.u[1], v_limit_check.START)
        and1.u[2] ~ f_limit_check.START,    # connect(and1.u[2], f_limit_check.START)
        and1.u[3] ~ fi_limit_check.START,   # connect(fi_limit_check.START, and1.u[3])
        TRIGGER ~ rSFlipFlop.Q,             # connect(TRIGGER, rSFlipFlop.Q)
        rSFlipFlop.S ~ and1.y,              # connect(and1.y, rSFlipFlop.S)
        rSFlipFlop.R ~ disable.y,           # connect(disable.y, rSFlipFlop.R)
    ]
    System(eqs, t, vars, []; name, systems)
end
