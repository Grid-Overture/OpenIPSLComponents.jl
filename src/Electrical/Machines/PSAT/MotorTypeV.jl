# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSAT/MotorTypeV.mo (extends Electrical/Essentials/pfComponent.mo)
# Fifth-order induction machine: five states (s, e1r, e1m, e2r, e2m) with the .mo's `initial equation der = 0` for
# each of them. `V_b` is inert (`enableV_b = false`, never read); `fn` is used (Omegab = 2*pi*fn).
# The protected parameters are reordered to their dependency order (`i2`, `K`, `S0` before `K2`, `K1`, `epm0`, `epr0`).
# **`ir0`/`ii0` are computed without the `/S_b` that MotorTypeI and MotorTypeIII carry** (sic, the .mo's own scaling
# error): with the Test's data i2 = 1.07e11, S0 = 3.1e10 and epr0 = epm0 ~ 3.5e-7. Those are only `start` values, i.e.
# guesses (F-20): the five `der = 0` determine the states, and OpenModelica converges from them to the braking-region
# root s = 3.76, which is the oracle (F-53).
# `der(e1r)` and `der(e1m)` appear on the right-hand side of `der(e2r)` and `der(e2m)`: written literally, the linear
# system in the derivatives is what `mtkcompile` solves.
# The .mo reaches the pin through the crossed aliases `Vr = p.vi`, `Vm = p.vr`, `Im = p.ir`, `Ir = -p.ii` (sic), with
# `Ir`/`Im` defined explicitly by the two stator equations: the pin currents are already current-explicit (F-16, F-21).
# `Sup` and `tup` are declared and used nowhere in the .mo: accepted and dead.
# Omitted: graphical annotations, displayPF.

@component function MotorTypeV(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        Sup = 1, Rs = 0.01, Xs = 0.15, Rr1 = 0.05, Xr1 = 0.15, Rr2 = 0.001, Xr2 = 0.04, Xm = 5, Hm = 3, a = 0.13,
        b = 0.02, c = 0.024, tup = 0)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Rs, Xs, Rr1, Xr1, Rr2, Xr2, Xm, Hm, a, b, c, tup =
        float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Rs, Xs, Rr1, Xr1, Rr2, Xr2, Xm, Hm, a, b, c, tup))   # F-21
    Omegab = 2 * pi * fn
    vr0 = v_0 * cos(angle_0)
    vi0 = v_0 * sin(angle_0)
    ir0 = (P_0 * vr0 + Q_0 * vi0) / (vr0^2 + vi0^2)   # sic: no /S_b (F-53)
    ii0 = (P_0 * vi0 - Q_0 * vr0) / (vr0^2 + vi0^2)   # sic: no /S_b (F-53)
    A = a + b + c
    B = (-b) - 2 * c
    C = c
    X0 = Xs + Xm
    X1 = Xs + Xr1 * Xm / (Xr1 + Xm)
    T10 = (Xr1 + Xm) / (Omegab * Rr1)
    X2 = Xs + Xr1 * Xm * Xr2 / (Xr1 * Xr2 + Xr1 * Xm + Xr2 * Xm)
    T20 = (Xr2 + Xr1 * Xm / (Xr1 + Xm)) / (Omegab * Rr2)
    a05 = Rs^2 + X2^2
    a15 = Rs / a05
    a25 = X2 / a05
    a35 = X0 - X1
    a45 = X1 - X2
    i2 = ir0 * ir0 + ii0 * ii0
    K = Rr1 / ((Xr1 + Xm) * A)
    S0 = K * ((-Q_0 / S_b) + X0 * i2)
    K2 = 1 + T10 * T10 * Omegab * Omegab * S0 * S0
    K1 = T10 * Omegab * S0
    epm0 = (K1 * (X0 - X1) * ir0 + (X0 - X1) * (-1) * ii0) / K2
    epr0 = (K1 * (X0 - X1) * (-1) * ii0 - (X0 - X1) * ir0) / K2
    p00, q00 = P_0 / S_b, Q_0 / S_b
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    pars = @parameters begin
        Sup = Sup, [description = "Start up control (declared and unused in the .mo)"]
        Rs = Rs, [description = "Stator resistance (pu)"]
        Xs = Xs, [description = "Stator reactance (pu)"]
        Rr1 = Rr1, [description = "1st cage rotor resistance (pu)"]
        Xr1 = Xr1, [description = "1st cage rotor reactance (pu)"]
        Rr2 = Rr2, [description = "2nd cage rotor resistance (pu)"]
        Xr2 = Xr2, [description = "2nd cage rotor reactance (pu)"]
        Xm = Xm, [description = "Magnetizing reactance (pu)"]
        Hm = Hm, [description = "Inertia constant (Ws/VA)"]
        a = a, [description = "1st coefficient of tau_m(w) (pu)"]
        b = b, [description = "2nd coefficient of tau_m(w) (pu)"]
        c = c, [description = "3rd coefficient of tau_m(w) (pu)"]
        tup = tup, [description = "Start up time (s; declared and unused in the .mo)"]
        Omegab = Omegab, [description = "Base freq in rad/s"]
        vr0 = vr0, [description = "Init. val."]
        vi0 = vi0, [description = "Init. val."]
        ir0 = ir0, [description = "Init. val. (no /S_b, sic)"]
        ii0 = ii0, [description = "Init. val. (no /S_b, sic)"]
        A = A, [description = "a + b + c"]
        B = B, [description = "-b - 2c"]
        C = C, [description = "c"]
        X0 = X0, [description = "Xs + Xm"]
        X1 = X1, [description = "Xs + Xr1*Xm/(Xr1 + Xm)"]
        T10 = T10, [description = "(Xr1 + Xm)/(Omegab*Rr1) (s)"]
        X2 = X2, [description = "Xs + Xr1*Xm*Xr2/(Xr1*Xr2 + Xr1*Xm + Xr2*Xm)"]
        T20 = T20, [description = "(Xr2 + Xr1*Xm/(Xr1 + Xm))/(Omegab*Rr2) (s)"]
        a05 = a05, [description = "Rs^2 + X2^2"]
        a15 = a15, [description = "Rs/a05"]
        a25 = a25, [description = "X2/a05"]
        a35 = a35, [description = "X0 - X1"]
        a45 = a45, [description = "X1 - X2"]
        i2 = i2, [description = "Init. val."]
        K = K, [description = "Rr1/((Xr1 + Xm)*A)"]
        K2 = K2, [description = "1 + T10^2*Omegab^2*S0^2"]
        K1 = K1, [description = "T10*Omegab*S0"]
        S0 = S0, [description = "Init. val. slip"]
        epm0 = epm0, [description = "Init. val."]
        epr0 = epr0, [description = "Init. val."]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        v(t), [description = "Bus voltage magnitude (pu)"]
        anglev(t), [description = "Bus voltage angle (rad)"]
        s(t), [description = "Slip (pu)"]
        Tm(t), [description = "Mechanical torque (pu)"]
        Te(t), [description = "Electrical torque (pu)"]
        P(t), [description = "Active power (pu)"]
        Q(t), [description = "Reactive power (pu)"]
        e1r(t), [description = "Real axis transient voltage (pu)"]
        e1m(t), [description = "Imaginary axis transient voltage (pu)"]
        e2r(t), [description = "Real axis sub-transient voltage (pu)"]
        e2m(t), [description = "Imaginary axis sub-transient voltage (pu)"]
        Vr(t), [description = "Real axis voltage (pu)"]
        Vm(t), [description = "Imaginary axis voltage (pu)"]
        Ir(t), [description = "Real axis current (pu)"]
        Im(t), [description = "Imaginary axis current (pu)"]
    end
    eqs = Equation[
        anglev ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
        v ~ sqrt(p.vr^2 + p.vi^2),
        Vr ~ p.vi,
        Vm ~ p.vr,
        Im ~ p.ir,
        Ir ~ -p.ii,
        P ~ p.vr * p.ir + p.vi * p.ii,
        Q ~ (-p.vr * p.ii) + p.vi * p.ir,
        Ir ~ a15 * ((-Vr) - e2r) + a25 * (Vm - e2m),
        Im ~ (-a25 * ((-Vr) - e2r)) + a15 * (Vm - e2m),
        der(s) ~ (Tm - Te) / (2 * Hm),
        Te ~ e2r * Ir + e2m * Im,
        der(e1r) ~ Omegab * s * e1m - (e1r + a35 * Im) / T10,
        der(e1m) ~ (-Omegab * s * e1r) - (e1m - a35 * Ir) / T10,
        der(e2r) ~ (-Omegab * s * (e1m - e2m)) + der(e1r) + (e1r - e2r - a45 * Im) / T20,
        der(e2m) ~ Omegab * s * (e1r - e2r) + der(e1m) + (e1m - e2m + a45 * Ir) / T20,
        Tm ~ A + B * s + C * s * s,
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            guesses = Dict(v => v_0, anglev => angle_0, s => S0, P => p00, Q => q00, e1r => epr0, e1m => epm0,
                e2r => 0.0353, e2m => 0.9995, p.vr => vr0, p.vi => vi0, p.ir => ir0, p.ii => ii0),
            initialization_eqs = [der(e2r) ~ 0, der(e2m) ~ 0, der(s) ~ 0, der(e1r) ~ 0, der(e1m) ~ 0]), base)
end
