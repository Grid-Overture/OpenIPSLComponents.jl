# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSSE/BaseClasses/baseLoad.mo (partial; extends Electrical/Essentials/pfComponent.mo)
# Julia name PSSE_baseLoad (the PSAT base of the same leaf name is `baseLoad`). The Complex parameters S_p, S_i, S_y,
# a, b are Julia `Complex` keyword arguments; the derived S_P, S_I, S_Y and the initial pin values are computed before
# `@parameters` (F-22) and kept as real pairs (PLAN-02). `characteristic` (1 or 2) decides in Julia which kP/kI
# branch is written; the voltage thresholds of those branches (`v < PQBRAK/2`, `v < PQBRAK`, `v < 0.5`) are `ifelse`
# without state events (no Test crosses them). Start values: v, angle, kP, kI and the pin as `guesses` (F-20).
# Children (`Load`, `Load_variation`) `@unpack v, P, Q, kP, kI, p = base` and add the power-balance equations.
# Omitted: displayPF (disabled), graphical annotations.

@component function PSSE_baseLoad(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        S_p = complex(P_0, Q_0), S_i = complex(0.0, 0.0), S_y = complex(0.0, 0.0), a = complex(1.0, 0.0),
        b = complex(0.0, 1.0), PQBRAK = 0.7, characteristic = 1)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, PQBRAK = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, PQBRAK))   # F-21
    S_p, S_i, S_y, a, b = complex.(float.((S_p, S_i, S_y, a, b)))
    characteristic in (1, 2) || throw(ArgumentError("PSSE_baseLoad: characteristic must be 1 or 2"))
    char = characteristic   # the Julia-level branch below, decided before @parameters rebinds the name (F-22)
    p0 =(real(S_i) * v_0 + real(S_y) * v_0^2 + real(S_p)) / S_b
    q0 = (imag(S_i) * v_0 + imag(S_y) * v_0^2 + imag(S_p)) / S_b
    vr0 = v_0 * cos(angle_0)
    vi0 = v_0 * sin(angle_0)
    ir0 = (p0 * vr0 + q0 * vi0) / (vr0^2 + vi0^2)
    ii0 = (p0 * vi0 - q0 * vr0) / (vr0^2 + vi0^2)
    S_P = complex((1 - real(a) - real(b)) * real(S_p), (1 - imag(a) - imag(b)) * imag(S_p)) / S_b
    S_I = (S_i + complex(real(a) * real(S_p) / v_0, imag(a) * imag(S_p) / v_0)) / S_b
    S_Y = (S_y + complex(real(b) * real(S_p) / v_0^2, imag(b) * imag(S_p) / v_0^2)) / S_b
    a2, b2, a0, a1, b1, wp = 1.502, 1.769, 0.4881, -0.4999, 0.1389, 3.964
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack v_0, angle_0 = base
    pars = @parameters begin
        PQBRAK = PQBRAK, [description = "Constant power characteristic threshold (pu)"]
        characteristic = characteristic, [description = "Load characteristic (1 or 2)"]
        p0 = p0, [description = "Initial active power (pu)"]
        q0 = q0, [description = "Initial reactive power (pu)"]
        vr0 = vr0, [description = "Initial real voltage (pu)"]
        vi0 = vi0, [description = "Initial imaginary voltage (pu)"]
        ir0 = ir0, [description = "Initial real current (pu)"]
        ii0 = ii0, [description = "Initial imaginary current (pu)"]
        S_P_re = real(S_P), [description = "Constant power part, real (pu)"]
        S_P_im = imag(S_P), [description = "Constant power part, imaginary (pu)"]
        S_I_re = real(S_I), [description = "Constant current part, real (pu)"]
        S_I_im = imag(S_I), [description = "Constant current part, imaginary (pu)"]
        S_Y_re = real(S_Y), [description = "Constant admittance part, real (pu)"]
        S_Y_im = imag(S_Y), [description = "Constant admittance part, imaginary (pu)"]
        a2 = a2
        b2 = b2
        a0 = a0
        a1 = a1
        b1 = b1
        wp = wp
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        angle(t), [description = "Bus voltage angle (rad)"]
        v(t), [description = "Bus voltage magnitude (pu)"]
        P(t), [description = "Active power consumption (pu)"]
        Q(t), [description = "Reactive power consumption (pu)"]
        kP(t), [description = "Constant power factor"]
        kI(t), [description = "Constant current factor"]
    end
    kPQ = char == 1 ? Equation[
        kP ~ ifelse((v < PQBRAK / 2) & (v > 0), 2 * (v / PQBRAK)^2,
            ifelse((v > PQBRAK / 2) & (v < PQBRAK), 1 - 2 * ((v - PQBRAK) / PQBRAK)^2, 1)),
        kI ~ 1,
    ] : Equation[
        kP ~ ifelse(v < PQBRAK, a0 + a1 * cos(v * wp) + b1 * sin(v * wp), 1),
        kI ~ ifelse(v < 0.5, a2 * b2 * v^(b2 - 1) * exp(-a2 * v^b2), 1),
    ]
    eqs = Equation[
        P ~ p.vr * p.ir + p.vi * p.ii,
        Q ~ (-p.vr * p.ii) + p.vi * p.ir,
        angle ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
        v ~ sqrt(p.vr^2 + p.vi^2),
        kPQ...,
    ]
    # angle(start = angle_0), v(start = v_0), kP/kI(start = 1), p(vr(start = vr0), vi(start = vi0), ir(start = ir0), ii(start = ii0))
    extend(System(eqs, t, vars, pars; name, systems,
            guesses = Dict(angle => angle_0, v => v_0, kP => 1.0, kI => 1.0, p.vr => vr0, p.vi => vi0, p.ir => ir0, p.ii => ii0)),
        base)
end
