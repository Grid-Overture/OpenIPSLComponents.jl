# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/General/ElmGenstat.mo (extends Electrical/Essentials/pfComponent.mo:
# enablefn = enableS_b = enableangle_0 = enablev_0 = true; V_b, P_0, Q_0 accepted and inert; `fn` is enabled but
# appears in no equation)
# Blocks: none. The PowerFactory static generator: a current source in the dq frame of its own terminal voltage.
# `pll_connected` is a Boolean parameter: no user of OpenIPSL 3.1.0 sets it, so only the `false` branch is ported
# (`sinu = p.vi/v`, `cosu = p.vr/v`; the conditional inputs `sinref`/`cosref` do not exist) and `true` is refused
# (F-50). The two current equations `p.ir*S_b/M_b = -(...)` are written solved for the pin currents (a factor
# moved across, not a change of form: this is a current source). `P`, `Q` are in S_b (sic, `-P = vr*ir + vi*ii`
# with the pin currents in S_b); `i` is in M_b. `atan2` is `atan(y, x)`, which gives 0 for a zero current instead of
# a NaN. The `start` modifiers of the pin are guesses. Omitted: displayPF, graphical annotations.

@component function ElmGenstat(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b, pll_connected = false)
    pll_connected && error("ElmGenstat: pll_connected = true (the sinref/cosref PLL inputs) is not ported (F-50)")
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b))
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack S_b, v_0, angle_0 = base
    pars = @parameters begin
        M_b = M_b, [description = "Machine base power (VA)"]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        angle_i(t), [description = "Current angle (rad)"]
        angle_v(t), [description = "Voltage angle (rad)"]
        id_ref(t), [description = "d-axis current reference (pu of M_b)"]
        iq_ref(t), [description = "q-axis current reference (pu of M_b)"]
        i(t), [description = "Current magnitude (pu of M_b)"]
        v(t), [description = "Voltage magnitude (pu)"]
        P(t), [description = "Active power (pu of S_b)"]
        Q(t), [description = "Reactive power (pu of S_b)"]
        sinu(t), [description = "Internal sine of the voltage angle"]
        cosu(t), [description = "Internal cosine of the voltage angle"]
    end
    eqs = Equation[
        sinu ~ p.vi / v,
        cosu ~ p.vr / v,
        p.ir ~ -(M_b / S_b) * (id_ref * cosu - iq_ref * sinu),   # p.ir*S_b/M_b = -(id_ref*cosu - iq_ref*sinu)
        p.ii ~ -(M_b / S_b) * (id_ref * sinu + iq_ref * cosu),   # p.ii*S_b/M_b = -(id_ref*sinu + iq_ref*cosu)
        -P ~ p.vr * p.ir + p.vi * p.ii,
        -Q ~ p.vi * p.ir - p.vr * p.ii,
        v ~ sqrt(p.vr^2 + p.vi^2),
        angle_v ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
        i ~ sqrt(p.ii^2 + p.ir^2) * S_b / M_b,
        angle_i ~ atan(p.ii, p.ir),   # atan2(p.ii, p.ir)
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            guesses = Dict(p.vr => v_0 * cos(angle_0), p.vi => v_0 * sin(angle_0), v => v_0, angle_v => angle_0)), base)
end
