# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PSAT/ConstantPQPV/PQ1.mo (extends nothing; the `outer SystemBase` is the keyword
# argument S_b, and `Sn = SysData.S_b` its default; there is no `fn`)
# Blocks: none. The PSAT constant-PQ solar inverter: `P_0`, `Q_0` are **per unit of Sn** (Types.PerUnit, defaults
# 0.4 / 0.3), not W, because this model is not a pfComponent. The protected parameters (CoB, Pref, Qref, vd0, vq0,
# idref, iqref) are computed in the order of the .mo. The dq frame is `vq = p.vr`, `vd = -p.vi` and the pin currents
# are explicit in the .mo itself (`p.ir = -iq`, `p.ii = id`, "change of sign"): F-16 does not apply.
# No `initial equation`: OpenModelica fixes the two states at their `start` (F-11), `id = idref`, `iq = iqref`,
# which are `initial_conditions` entries here (F-54); the `start` of the algebraic variables are guesses.
# `atan2(p.vi, p.vr)` is `atan(p.vi, p.vr)`. Omitted: graphical annotations.

@component function PQ1(; name, S_b = 100e6, Sn = S_b, v_0 = 1.00018548610126, angle_0 = -0.0000253046024029618,
        P_0 = 0.4, Q_0 = 0.3, Td = 15, Tq = 15)
    S_b, Sn, v_0, angle_0, P_0, Q_0, Td, Tq = float.((S_b, Sn, v_0, angle_0, P_0, Q_0, Td, Tq))   # F-21
    n = pq1_init(S_b, Sn, v_0, angle_0, P_0, Q_0)
    pars = @parameters begin
        S_b = S_b, [description = "System base power (VA)"]
        Sn = Sn, [description = "Nominal power (VA)"]
        v_0 = v_0, [description = "Voltage magnitude (pu)"]
        angle_0 = angle_0, [description = "Voltage angle (rad)"]
        P_0 = P_0, [description = "Active power (pu of Sn)"]
        Q_0 = Q_0, [description = "Reactive power (pu of Sn)"]
        Td = Td, [description = "d-axis inverter time constant (s)"]
        Tq = Tq, [description = "q-axis inverter time constant (s)"]
        CoB = n.CoB
        Pref = n.Pref, [description = "active power initialization"]
        Qref = n.Qref, [description = "reactive power initialization"]
        vd0 = n.vd0, [description = "d-axis voltage initialization"]
        vq0 = n.vq0, [description = "q-axis voltage initialization"]
        idref = n.idref, [description = "d-axis current initialization"]
        iqref = n.iqref, [description = "q-axis current initialization"]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        v(t), [description = "Bus voltage magnitude"]
        anglev(t), [description = "Bus voltage angle"]
        id(t), [description = "d-axis current"]
        iq(t), [description = "q-axis current"]
        vd(t), [description = "d-axis voltage"]
        vq(t), [description = "q-axis voltage"]
        P(t), [description = "Active power"]
        Q(t), [description = "Reactive power"]
        idref1(t), [description = "d-axis current setpoint"]
        iqref1(t), [description = "q-axis current setpoint"]
    end
    eqs = Equation[
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
        initial_conditions = Dict(id => n.idref, iq => n.iqref),
        guesses = Dict(v => v_0, anglev => angle_0, vd => n.vd0, vq => n.vq0, P => n.Pref, Q => n.Qref,
            idref1 => n.idref, iqref1 => n.iqref, p.vr => n.vq0, p.vi => -n.vd0))
end

# The protected parameters of PQ1.mo / PV1.mo, in the order of the .mo (PV1 has no `Qref` parameter: it uses
# Q_0*CoB directly, which is the same number).
function pq1_init(S_b, Sn, v_0, angle_0, P_0, Q_0)
    CoB = Sn / S_b
    Pref = P_0 * CoB
    Qref = Q_0 * CoB
    vd0 = -v_0 * sin(angle_0)
    vq0 = v_0 * cos(angle_0)
    idref = (vq0 * Qref + Pref * vd0) / (vq0^2 + vd0^2)
    iqref = ((-vd0 * Qref) + Pref * vq0) / (vq0^2 + vd0^2)
    (; CoB, Pref, Qref, vd0, vq0, idref, iqref)
end
