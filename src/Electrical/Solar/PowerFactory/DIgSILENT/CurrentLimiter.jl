# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/DIgSILENT/CurrentLimiter.mo (extends nothing)
# Blocks, with the names of the .mo. d channel: dlim_normal_op = Limiter(+-maxAbsCur), dlim_frt_op =
# VariableLimiter(limit1 = gain.y, limit2 = add.y) with maximum_current = Constant(maxAbsCur), abs1 = Abs(duac),
# add = Add(k1 = -1, k2 = 1) = |duac| - maxAbsCur (sic, the lower limit), gain = Gain(-1), switch1(u2 = picdro.trip)
# -> idout. q channel: qlim_frt_op = Limiter(+-maxAbsCur), qlim_normal_op = VariableLimiter(limit1 = min.y,
# limit2 = gain1.y) with pythagoras = Pythagoras(u1IsHypotenuse = true)(u1 = const1 = Constant(maxAbsCur), u2 =
# iqin) (sic: the limit of iq is computed from iqin itself) -> limiter = Limiter(maxAbsCur, 0) -> min = Min(const =
# Constant(maxIq), .), gain1 = Gain(-1), switch_q_frt_normal(u2 = trip) -> iqout. Detection: deadZone(+-Deadband)
# -> abs -> greaterEqualThreshold(Deadband) -> picdro(Tdrop = if i_EEG then 0 else 0.5, Tpick = 0). The instances
# `abs`, `min` and `const` are `abs_`, `min_`, `const_` (Base functions / a keyword; `JULIA_RENAMES`). Ports are
# plain variables (idin, iqin, duac; idout, iqout). Omitted: graphical annotations.

@component function CurrentLimiter(; name, maxAbsCur, maxIq, Deadband, i_EEG)
    maxAbsCur, maxIq, Deadband = float.((maxAbsCur, maxIq, Deadband))
    pars = @parameters begin
        maxAbsCur = maxAbsCur, [description = "Max. allowed absolute current (pu)"]
        maxIq = maxIq, [description = "Max. abs reactive current in normal operation (pu)"]
        Deadband = Deadband, [description = "Deadband for dynamic AC voltage support (pu)"]
    end
    systems = @named begin
        dlim_normal_op = Limiter(; uMax = maxAbsCur, uMin = -maxAbsCur)
        qlim_frt_op = Limiter(; uMax = maxAbsCur, uMin = -maxAbsCur)
        qlim_normal_op = VariableLimiter()
        dlim_frt_op = VariableLimiter()
        maximum_current = OpenIPSLComponents.Constant(; k = maxAbsCur)
        add = Add(; k1 = -1, k2 = +1)
        abs1 = Abs()
        gain = Gain(; k = -1)
        min_ = Min()
        const_ = OpenIPSLComponents.Constant(; k = maxIq)
        gain1 = Gain(; k = -1)
        pythagoras = Pythagoras(; u1IsHypotenuse = true)
        const1 = OpenIPSLComponents.Constant(; k = maxAbsCur)
        limiter = Limiter(; uMax = maxAbsCur, uMin = 0)
        picdro = Picdro(; Tdrop = i_EEG ? 0.0 : 0.5, Tpick = 0.0)
        deadZone = DeadZone(; uMax = Deadband, uMin = -Deadband)
        greaterEqualThreshold = GreaterEqualThreshold(; threshold = Deadband)
        abs_ = Abs()
        switch_q_frt_normal = Switch()
        switch1 = Switch()
    end
    vars = @variables begin
        idin(t), [description = "d-axis current input (pu)"]
        iqin(t), [description = "q-axis current input (pu)"]
        duac(t), [description = "Voltage deviation (pu)"]
        idout(t), [description = "Limited d-axis current (pu)"]
        iqout(t), [description = "Limited q-axis current (pu)"]
    end
    eqs = Equation[
        abs1.u ~ duac,                                       # connect(abs1.u, duac)
        add.y ~ dlim_frt_op.limit2,                          # connect(add.y, dlim_frt_op.limit2)
        gain.u ~ add.y,                                      # connect(gain.u, add.y)
        const_.y ~ min_.u1,                                  # connect(const.y, min.u1)
        gain1.u ~ min_.y,                                    # connect(gain1.u, min.y)
        qlim_normal_op.u ~ iqin,                             # connect(qlim_normal_op.u, iqin)
        pythagoras.y ~ limiter.u,                            # connect(pythagoras.y, limiter.u)
        limiter.y ~ min_.u2,                                 # connect(limiter.y, min.u2)
        deadZone.u ~ duac,                                   # connect(deadZone.u, duac)
        deadZone.y ~ abs_.u,                                 # connect(deadZone.y, abs.u)
        abs_.y ~ greaterEqualThreshold.u,                    # connect(abs.y, greaterEqualThreshold.u)
        greaterEqualThreshold.y ~ picdro.condition,          # connect(greaterEqualThreshold.y, picdro.condition)
        switch_q_frt_normal.y ~ iqout,                       # connect(switch_q_frt_normal.y, iqout)
        switch_q_frt_normal.u2 ~ picdro.trip,                # connect(switch_q_frt_normal.u2, picdro.trip)
        pythagoras.u2 ~ iqin,                                # connect(pythagoras.u2, iqin)
        const1.y ~ pythagoras.u1,                            # connect(const1.y, pythagoras.u1)
        gain1.y ~ qlim_normal_op.limit2,                     # connect(gain1.y, qlim_normal_op.limit2)
        qlim_normal_op.limit1 ~ min_.y,                      # connect(qlim_normal_op.limit1, min.y)
        qlim_normal_op.y ~ switch_q_frt_normal.u3,           # connect(qlim_normal_op.y, switch_q_frt_normal.u3)
        qlim_frt_op.u ~ iqin,                                # connect(qlim_frt_op.u, iqin)
        qlim_frt_op.y ~ switch_q_frt_normal.u1,              # connect(qlim_frt_op.y, switch_q_frt_normal.u1)
        switch1.u2 ~ picdro.trip,                            # connect(switch1.u2, picdro.trip)
        dlim_normal_op.y ~ switch1.u3,                       # connect(dlim_normal_op.y, switch1.u3)
        dlim_frt_op.y ~ switch1.u1,                          # connect(dlim_frt_op.y, switch1.u1)
        switch1.y ~ idout,                                   # connect(switch1.y, idout)
        maximum_current.y ~ add.u1,                          # connect(maximum_current.y, add.u1)
        dlim_normal_op.u ~ idin,                             # connect(dlim_normal_op.u, idin)
        dlim_frt_op.u ~ idin,                                # connect(dlim_frt_op.u, idin)
        abs1.y ~ add.u2,                                     # connect(abs1.y, add.u2)
        gain.y ~ dlim_frt_op.limit1,                         # connect(gain.y, dlim_frt_op.limit1)
    ]
    System(eqs, t, vars, pars; name, systems)
end
