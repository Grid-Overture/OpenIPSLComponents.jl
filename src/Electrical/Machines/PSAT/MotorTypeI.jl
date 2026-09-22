# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSAT/MotorTypeI.mo (extends Electrical/Essentials/pfComponent.mo)
# First-order induction machine: one state, the slip `s`, with the .mo's `initial equation der(s) = 0`.
# `V_b` is inert here (`enableV_b = false` and the model never reads it) and `fn` is not used either, but both stay
# keyword arguments for uniformity with pfComponent. The pin currents are already written explicitly in the .mo
# (an admittance in Re, Xe and Xm), so no change of form is needed (F-16, F-21).
# `Sup` (start-up control) and `tup` (start-up time) are declared and used nowhere in the .mo: accepted and dead.
# The equilibrium of `der(s) = 0` is `Tm(s) = P` with `Tm = A + B*s + C*s^2` a parameter polynomial, so the motor does
# not start at its power-flow point; the `start` values of `s`, `P`, `Q` are only guesses (F-53).
# Omitted: graphical annotations, displayPF.

@component function MotorTypeI(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        Sup = 1, Rs = 0.01, Xs = 0.15, Rr1 = 0.05, Xr1 = 0.15, Xm = 5, Hm = 3, a = 0.5, b = 0.0, c = 0.0, tup = 0)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Rs, Xs, Rr1, Xr1, Xm, Hm, a, b, c, tup =
        float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Rs, Xs, Rr1, Xr1, Xm, Hm, a, b, c, tup))   # F-21
    vr0 = v_0 * cos(angle_0)
    vi0 = v_0 * sin(angle_0)
    ir0 = (P_0 / S_b * vr0 + Q_0 / S_b * vi0) / (vr0^2 + vi0^2)
    ii0 = (P_0 / S_b * vi0 - Q_0 / S_b * vr0) / (vr0^2 + vi0^2)
    A = a + b + c
    B = (-b) - 2 * c
    C = c
    Xe = Xs + Xr1
    s0 = Rr1 * P_0 / S_b * (Q_0 / S_b + v_0 * v_0 / Xm) / (v_0 * v_0 * v_0 * v_0 * (Xs + Xr1))
    p00, q00 = P_0 / S_b, Q_0 / S_b
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    pars = @parameters begin
        Sup = Sup, [description = "Start-up control (declared and unused in the .mo)"]
        Rs = Rs, [description = "Stator resistance (pu)"]
        Xs = Xs, [description = "Stator reactance (pu)"]
        Rr1 = Rr1, [description = "1st cage rotor resistance (pu)"]
        Xr1 = Xr1, [description = "1st cage rotor reactance (pu)"]
        Xm = Xm, [description = "Magnetizing reactance (pu)"]
        Hm = Hm, [description = "Inertia constant (Ws/VA)"]
        a = a, [description = "1st coefficient of tau_m(w) (pu)"]
        b = b, [description = "2nd coefficient of tau_m(w) (pu)"]
        c = c, [description = "3rd coefficient of tau_m(w) (pu)"]
        tup = tup, [description = "Start up time (s; declared and unused in the .mo)"]
        vr0 = vr0, [description = "Init. val."]
        vi0 = vi0, [description = "Init. val."]
        ir0 = ir0, [description = "Init. val."]
        ii0 = ii0, [description = "Init. val."]
        A = A, [description = "a + b + c"]
        B = B, [description = "-b - 2c"]
        C = C, [description = "c"]
        Xe = Xe, [description = "Xs + Xr1"]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        v(t), [description = "Bus voltage magnitude (pu)"]
        anglev(t), [description = "Bus voltage angle (rad)"]
        s(t), [description = "Slip (pu)"]
        Tm(t), [description = "Mechanical torque (pu)"]
        P(t), [description = "Active power (pu)"]
        Q(t), [description = "Reactive power (pu)"]
        Re(t), [description = "Equivalent resistance (pu)"]
    end
    eqs = Equation[
        P ~ p.vr * p.ir + p.vi * p.ii,
        Q ~ (-p.vr * p.ii) + p.vi * p.ir,
        anglev ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
        v ~ sqrt(p.vr^2 + p.vi^2),
        Tm ~ A + B * s + C * s * s,
        Re ~ Rs + Rr1 / s,
        der(s) ~ (Tm - P) / (2 * Hm),
        p.ii ~ (-p.vr / Xm) + (p.vi * Re - p.vr * Xe) / (Re * Re + Xe * Xe),
        p.ir ~ p.vi / Xm + (p.vr * Re + p.vi * Xe) / (Re * Re + Xe * Xe),
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            guesses = Dict(v => v_0, anglev => angle_0, s => s0, P => p00, Q => q00,
                p.vr => vr0, p.vi => vi0, p.ir => ir0, p.ii => ii0),
            initialization_eqs = [der(s) ~ 0]), base)
end
