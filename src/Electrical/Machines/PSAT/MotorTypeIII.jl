# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSAT/MotorTypeIII.mo (extends Electrical/Essentials/pfComponent.mo)
# Third-order induction machine: three states (s, epr, epm) with the .mo's `initial equation der = 0` for each.
# `V_b` is inert (`enableV_b = false`, never read); `fn` is used (Omegab = 2*pi*fn).
# The protected parameters are reordered to their dependency order: `S0` before `K2`, `K1`, `epm0`, `epr0` (the .mo
# declares S0 after them, which Modelica allows).
# The .mo reaches the pin through the crossed aliases `Vr = p.vi`, `Vm = p.vr`, `Im = p.ir`, `Ir = -p.ii` (sic: the
# names are swapped with respect to the real/imaginary parts); they are replicated as written. `Im` and `Ir` are
# defined explicitly by the two stator equations, so the pin currents are already current-explicit (F-16, F-21) and
# `P`, `Q` are output definitions, not current definitions.
# `Sup` and `tup` are declared and used nowhere in the .mo: accepted and dead.
# The equilibrium of `der(s) = 0` is `Tm(s) = Te` with `Tm` a parameter polynomial, so the motor does not start at its
# power-flow point (F-53): the `start` values are guesses.
# Omitted: graphical annotations, displayPF.

@component function MotorTypeIII(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        Sup = 1, Rs = 0.01, Xs = 0.15, Rr1 = 0.05, Xr1 = 0.15, Xm = 5, Hm = 3, a = 0.25, b = 0.0, c = 0.0, tup = 0)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Rs, Xs, Rr1, Xr1, Xm, Hm, a, b, c, tup =
        float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Rs, Xs, Rr1, Xr1, Xm, Hm, a, b, c, tup))   # F-21
    Omegab = 2 * pi * fn
    vr0 = v_0 * cos(angle_0)
    vi0 = v_0 * sin(angle_0)
    ir0 = (P_0 / S_b * vr0 + Q_0 / S_b * vi0) / (vr0^2 + vi0^2)
    ii0 = (P_0 / S_b * vi0 - Q_0 / S_b * vr0) / (vr0^2 + vi0^2)
    i2 = ir0 * ir0 + ii0 * ii0
    A = a + b + c
    B = (-b) - 2 * c
    C = c
    X0 = Xs + Xm
    Xp = Xs + Xr1 * Xm / (Xr1 + Xm)
    Tp0 = (Xr1 + Xm) / (Omegab * Rr1)
    RZs2 = 1 / (Rs * Rs + Xp * Xp)
    K = Rr1 / ((Xr1 + Xm) * A)
    S0 = K * ((-Q_0 / S_b) + X0 * i2)
    K2 = 1 + Tp0 * Tp0 * Omegab * Omegab * S0 * S0
    K1 = Tp0 * Omegab * S0
    a03 = Rs * Rs + Xp * Xp
    a13 = Rs / a03
    a23 = Xp / a03
    epm0 = (K1 * (X0 - Xp) * ir0 + (X0 - Xp) * (-1) * ii0) / K2
    epr0 = (K1 * (X0 - Xp) * (-1) * ii0 - (X0 - Xp) * ir0) / K2
    p00, q00 = P_0 / S_b, Q_0 / S_b
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    pars = @parameters begin
        Sup = Sup, [description = "Start up control (declared and unused in the .mo)"]
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
        Omegab = Omegab, [description = "Base freq (rad/s)"]
        vr0 = vr0, [description = "Init. val."]
        vi0 = vi0, [description = "Init. val."]
        ir0 = ir0, [description = "Init. val."]
        ii0 = ii0, [description = "Init. val."]
        i2 = i2, [description = "Init. val."]
        A = A, [description = "a + b + c"]
        B = B, [description = "-b - 2c"]
        C = C, [description = "c"]
        X0 = X0, [description = "Xs + Xm"]
        Xp = Xp, [description = "Xs + Xr1*Xm/(Xr1 + Xm)"]
        Tp0 = Tp0, [description = "(Xr1 + Xm)/(Omegab*Rr1) (s)"]
        RZs2 = RZs2, [description = "1/(Rs^2 + Xp^2)"]
        K = K, [description = "Rr1/((Xr1 + Xm)*A)"]
        K2 = K2, [description = "1 + Tp0^2*Omegab^2*S0^2"]
        K1 = K1, [description = "Tp0*Omegab*S0"]
        a03 = a03, [description = "Rs^2 + Xp^2"]
        a13 = a13, [description = "Rs/a03"]
        a23 = a23, [description = "Xp/a03"]
        S0 = S0, [description = "Init. val. slip"]
        epm0 = epm0, [description = "Init. val."]
        epr0 = epr0, [description = "Init. val."]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        v(t), [description = "Bus voltage magnitude (pu)"]
        anglev(t), [description = "Bus voltage angle (pu)"]
        s(t), [description = "Slip (pu)"]
        Tm(t), [description = "Mechanical torque (pu)"]
        Te(t), [description = "Electrical torque (pu)"]
        P(t), [description = "Active power (pu)"]
        Q(t), [description = "Reactive power (pu)"]
        Vr(t), [description = "Real axis voltage (pu)"]
        Vm(t), [description = "Imaginary axis voltage (pu)"]
        Ir(t), [description = "Real axis current (pu)"]
        Im(t), [description = "Imaginary axis current (pu)"]
        epr(t), [description = "Real axis transient voltage (pu)"]
        epm(t), [description = "Imaginary axis transient voltage (pu)"]
        I(t), [description = "Current magnitude (pu)"]
        anglei(t), [description = "Current angle (rad)"]
    end
    eqs = Equation[
        anglev ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
        anglei ~ atan(p.ii, p.ir),   # atan2(p.ii, p.ir)
        v ~ sqrt(p.vr^2 + p.vi^2),
        I ~ sqrt(p.ii^2 + p.ir^2),
        Vr ~ p.vi,
        Vm ~ p.vr,
        Im ~ p.ir,
        Ir ~ -p.ii,
        P ~ p.vr * p.ir + p.vi * p.ii,
        Q ~ (-p.vr * p.ii) + p.vi * p.ir,
        der(s) ~ (Tm - Te) / (2 * Hm),
        Tm ~ A + B * s + C * s * s,
        Te ~ epr * Ir + epm * Im,
        der(epr) ~ Omegab * s * epm - (epr + (X0 - Xp) * Im) / Tp0,
        der(epm) ~ (-Omegab * s * epr) - (epm - (X0 - Xp) * Ir) / Tp0,
        Im ~ (-a23 * ((-Vr) - epr)) + a13 * (Vm - epm),
        Ir ~ a13 * ((-Vr) - epr) + a23 * (Vm - epm),
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            guesses = Dict(v => v_0, anglev => angle_0, s => S0, P => p00, Q => q00, epr => epr0, epm => epm0,
                p.vr => vr0, p.vi => vi0, p.ir => ir0, p.ii => ii0),
            initialization_eqs = [der(s) ~ 0, der(epr) ~ 0, der(epm) ~ 0]), base)
end
