# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSSE/BaseClasses/baseMotor.mo (partial; extends Electrical/Essentials/pfComponent.mo)
# Base of the PSSE three-phase induction motors. Blocks: we_fix = Gain(k = 1), we_source_fix = Constant(k = 0)
# (only `if not Ctrl`). `Ctrl` decides in Julia, before `@parameters` (F-22), three things the .mo writes as
# conditional declarations or `if` expressions: whether the `we` input exists (and therefore whether `we_fix.u` is
# fed by the input or by `we_source_fix`), whether `w_sync` follows `we_fix.y` or the base speed, and whether the
# active power carries the speed ratio. The pin currents are in system base and Ir/Ii in motor base (1/CoB).
# Omitted: displayPF (disabled), graphical annotations.

@component function baseMotor(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b = 15e6, Sup = true, Ctrl = true, N = 1, H = 0.4)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, N, H =
        float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, N, H))   # F-21
    p0 = P_0 / M_b
    q0 = Q_0 / M_b
    w_b = 2 * pi * fn / N
    vr0 = v_0 * cos(angle_0)
    vi0 = v_0 * sin(angle_0)
    ir0 = (p0 * vr0 + q0 * vi0) / (vr0^2 + vi0^2)
    ii0 = (p0 * vi0 - q0 * vr0) / (vr0^2 + vi0^2)
    CoB = M_b / S_b
    ir0_sys = CoB * ir0
    ii0_sys = CoB * ii0
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack S_b = base
    pars = @parameters begin
        M_b = M_b, [description = "Machine base power (VA)"]
        N = N, [description = "Number of pair of Poles"]
        H = H, [description = "Inertia constant (s)"]
        p0 = p0, [description = "Initial active power"]
        q0 = q0, [description = "Initial reactive power"]
        w_b = w_b, [description = "Base freq in rad/s"]
        vr0 = vr0, [description = "Initial real voltage"]
        vi0 = vi0, [description = "Initial imaginary voltage"]
        ir0 = ir0, [description = "Initial real current in motor base"]
        ii0 = ii0, [description = "Initial imaginary current in motor base"]
        ir0_sys = ir0_sys, [description = "Initial real current in system base"]
        ii0_sys = ii0_sys, [description = "Initial imaginary current in system base"]
        CoB = CoB, [description = "Change of base"]
    end
    systems = @named begin
        we_fix = Gain(; k = 1)
        p = PwPin()
    end
    vars = @variables begin
        v(t), [description = "Bus voltage magnitude"]
        anglev(t), [description = "Bus voltage angle"]
        delta(t), [description = "Bus voltage angle"]
        s(t), [description = "Induction motor slip"]
        P(t), [description = "Active power"]
        Q(t), [description = "Reactive power"]
        nr(t), [description = "Rotor speed (rad/s)"]
        ns(t), [description = "Synchronous speed (rad/s)"]
        w_sync(t), [description = "Controllable synchronous speed (rad/s)"]
        P_motor(t), [description = "Active power in motor base power"]
        Q_motor(t), [description = "Reactive power in motor base power"]
        Vr(t), [description = "Real part of terminal voltage"]
        Vi(t), [description = "Imaginary part of terminal voltage"]
        Ir(t), [description = "Real part of terminal current"]
        Ii(t), [description = "Imaginary part of terminal current"]
        Imag(t), [description = "Terminal current magnitude"]
        Te_motor(t), [description = "Electromagnetic torque in motor base"]
        Te_sys(t), [description = "Electromagnetic torque in system base"]
        wr(t), [description = "Absolute angular velocity of flange as output signal (rad/s)"]
    end
    # `we` is declared `if Ctrl` and `we_source_fix` `if not Ctrl` in the .mo: only one of the two connects exists
    if Ctrl
        @variables we(t) [description = "Input for controllable synchronous speed functionality (rad/s)"]
        push!(vars, we)
        we_eq = we_fix.u ~ we          # connect(we, we_fix.u)
    else
        @named we_source_fix = Constant(; k = 0)
        push!(systems, we_source_fix)
        we_eq = we_fix.u ~ we_source_fix.y   # connect(we_source_fix.y, we_fix.u)
    end
    eqs = Equation[
        we_eq,
        w_sync ~ (Ctrl ? we_fix.y : w_b),
        Vr ~ p.vr,
        Vi ~ p.vi,
        Ir ~ (1 / CoB) * p.ir,
        Ii ~ (1 / CoB) * p.ii,
        Imag ~ sqrt(Ir^2 + Ii^2),
        v ~ sqrt(p.vr^2 + p.vi^2),
        anglev ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
        delta ~ anglev,
        P ~ (Ctrl ? Te_sys * nr / w_b : Te_sys),
        Q ~ (-p.vr * p.ii) + p.vi * p.ir,
        P_motor ~ P / CoB,
        Q_motor ~ Q / CoB,
        ns ~ w_sync / N,
        nr ~ (1 - s) * ns,
        wr ~ nr,
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            guesses = Dict(p.vr => vr0, p.vi => vi0, p.ir => ir0_sys, p.ii => ii0_sys)),
        base)
end
