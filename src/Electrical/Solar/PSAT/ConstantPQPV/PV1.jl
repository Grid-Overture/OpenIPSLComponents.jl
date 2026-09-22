# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PSAT/ConstantPQPV/PV1.mo (extends nothing; `outer SystemBase` -> keyword S_b,
# `Sn = SysData.S_b`; there is no `fn`)
# Blocks: none. PQ1 plus an **unlimited** PI voltage regulator, `der(x) = Ki*(vref - v); Qref = x + Kp*(vref - v)`,
# whose state `x` and output `Qref` are protected variables (OpenModelica does not write them to its CSV). The two
# files share no base: the .mo has none (rule 6). `P_0`, `Q_0` in pu of Sn; protected parameters in the order of
# the .mo (the `idref`/`iqref` of PV1 use `Q_0*CoB` directly). No `initial equation`: OpenModelica fixes `id`, `iq`
# and `x` at their `start` (F-11) -> `initial_conditions` (F-54); the algebraic `start`s are guesses. Pin currents
# explicit in the .mo (`p.ir = -iq`, `p.ii = id`); `atan2` is `atan(y, x)`. Omitted: graphical annotations.

@component function PV1(; name, S_b = 100e6, Sn = S_b, v_0 = 1.00018548610126, angle_0 = -0.0000253046024029618,
        P_0 = 0.4, Q_0 = 0.3, vref = 1.0002, Td = 0.15, Tq = 0.15, Ki = 50.9005, Kp = 0.0868)
    S_b, Sn, v_0, angle_0, P_0, Q_0, vref, Td, Tq, Ki, Kp =
        float.((S_b, Sn, v_0, angle_0, P_0, Q_0, vref, Td, Tq, Ki, Kp))   # F-21
    n = pq1_init(S_b, Sn, v_0, angle_0, P_0, Q_0)
    pars = @parameters begin
        S_b = S_b, [description = "System base power (VA)"]
        Sn = Sn, [description = "Nominal power (VA)"]
        v_0 = v_0, [description = "Voltage magnitude (pu)"]
        angle_0 = angle_0, [description = "Voltage angle (rad)"]
        P_0 = P_0, [description = "Active power (pu of Sn)"]
        Q_0 = Q_0, [description = "Reactive power (pu of Sn)"]
        vref = vref, [description = "Voltage reference (pu)"]
        Td = Td, [description = "d-axis inverter time constant (s)"]
        Tq = Tq, [description = "q-axis inverter time constant (s)"]
        Ki = Ki, [description = "Integral gain of the voltage controller"]
        Kp = Kp, [description = "Proportional gain of the voltage controller"]
        CoB = n.CoB
        Pref = n.Pref, [description = "active power initialization"]
        vd0 = n.vd0, [description = "d-axis voltage initialization"]
        vq0 = n.vq0, [description = "q-axis voltage initialization"]
        idref = n.idref, [description = "d-axis current initialization"]
        iqref = n.iqref, [description = "q-axis current initialization"]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        x(t), [description = "State of the voltage PI (protected)"]
        Qref(t), [description = "reactive power initialization (protected)"]
        v(t), [description = "Bus voltage magnitude"]
        anglev(t), [description = "Bus voltage angle"]
        idref1(t), [description = "d-axis current setpoint"]
        iqref1(t), [description = "q-axis current setpoint"]
        id(t), [description = "d-axis current"]
        iq(t), [description = "q-axis current"]
        vd(t), [description = "d-axis voltage"]
        vq(t), [description = "q-axs voltage"]
        P(t), [description = "Active power"]
        Q(t), [description = "Reactive power"]
    end
    eqs = Equation[
        der(x) ~ Ki * (vref - v),
        Qref ~ x + Kp * (vref - v),
        P ~ vd * id + vq * iq,
        Q ~ vq * id - vd * iq,
        idref1 ~ (vq * Qref + Pref * vd) / (vq^2 + vd^2),
        iqref1 ~ ((-vd * Qref) + Pref * vq) / (vq^2 + vd^2),
        der(id) ~ (idref1 - id) / Td,
        der(iq) ~ (iqref1 - iq) / Tq,
        v ~ sqrt(p.vr^2 + p.vi^2),
        anglev ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
        p.ir ~ -iq,
        p.ii ~ id,
        p.vr ~ vq,
        p.vi ~ -vd,
    ]
    System(eqs, t, vars, pars; name, systems,
        initial_conditions = Dict(id => n.idref, iq => n.iqref, x => Q_0 * n.CoB),
        guesses = Dict(Qref => Q_0 * n.CoB, v => v_0, anglev => angle_0, vd => n.vd0, vq => n.vq0, P => n.Pref,
            Q => Q_0 * n.CoB, idref1 => n.idref, iqref1 => n.iqref, p.vr => n.vq0, p.vi => -n.vd0))
end
