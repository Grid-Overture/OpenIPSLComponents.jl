# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSAT/BaseClasses/baseMachine.mo (partial; extends Electrical/Essentials/pfComponent.mo)
# Base of the PSAT machines: the power-flow initialization in Julia complex arithmetic (Modelica.ComplexMath.fromPolar
# -> cis, conj -> conj, arg -> angle; the complex intermediates Vt0, S0, I0, Vdq0, Idq0 stay Julia locals), the
# electromechanical equations and the dq <-> network transforms. `xq0` (used for delta0) is the child's choice
# (`extends baseMachine(xq0 = x1d)` in Order2, `xq0 = xq` in Order3): a required keyword argument. The RealInput/
# RealOutput ports vf, pm, delta, w, v, P, Q, vf0, pm0 are plain variables. Start values: the states delta = delta0,
# w = 1 as `initial_conditions`, the algebraic ones as `guesses` (F-20); a child overrides them after `@unpack`.
# `vf(start = vf00)` belongs to the child (vf00 is defined there). `Order4.jl` (batch 0) carries this base flattened.
# `psat_machine_init` returns the derived parameters so that the children compute their own (e1q0, vf00) from the same
# numbers. Omitted: displayPF (disabled), graphical annotations.

function psat_machine_init(S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, xq0)
    w_b = 2 * pi * fn
    S_SBtoMB = S_b / Sn
    I_MBtoSB = (Sn * V_b) / (S_b * Vn)
    V_MBtoSB = Vn / V_b
    Z_MBtoSB = (S_b * Vn^2) / (Sn * V_b^2)
    p0 = P_0 / S_b
    q0 = Q_0 / S_b
    Vt0 = v_0 * cis(angle_0)
    S0 = complex(p0, -q0)
    I0 = S0 / conj(Vt0)
    vr0 = real(Vt0)
    vi0 = imag(Vt0)
    ir0 = -real(I0)
    ii0 = -imag(I0)
    delta0 = angle(Vt0 + ((ra + im * xq0) * Z_MBtoSB * I0))
    Vdq0 = Vt0 * cis(-delta0 + (pi / 2)) / V_MBtoSB
    Idq0 = I0 * cis(-delta0 + (pi / 2)) / I_MBtoSB
    vd0 = real(Vdq0)
    vq0 = imag(Vdq0)
    id0 = real(Idq0)
    iq0 = imag(Idq0)
    pm00 = ((vq0 + ra * iq0) * iq0 + (vd0 + ra * id0) * id0) / S_SBtoMB
    (; w_b, S_SBtoMB, I_MBtoSB, V_MBtoSB, Z_MBtoSB, p0, q0, vr0, vi0, ir0, ii0, delta0, vd0, vq0, id0, iq0, pm00)
end

@component function baseMachine(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        Sn, Vn, ra, x1d, M, D, xq0)
    # Real parameters as floats: a Modelica Integer literal is converted to Real, and Sn*V_b^2 overflows Int64 (F-21)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xq0 =
        float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xq0))
    i0 = psat_machine_init(S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, xq0)
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack S_b, V_b, v_0, angle_0 = base
    pars = @parameters begin
        Sn = Sn, [description = "Power rating (VA)"]
        Vn = Vn, [description = "Voltage rating (V)"]
        ra = ra, [description = "Armature resistance (pu)"]
        x1d = x1d, [description = "d-axis transient reactance (pu)"]
        M = M, [description = "Mechanical starting time, 2H (Ws/VA)"]
        D = D, [description = "Damping coefficient"]
        w_b = i0.w_b, [description = "Base frequency (rad/s)"]
        S_SBtoMB = i0.S_SBtoMB, [description = "S(system base) -> S(machine base)"]
        I_MBtoSB = i0.I_MBtoSB, [description = "I(machine base) -> I(system base)"]
        V_MBtoSB = i0.V_MBtoSB, [description = "V(machine base) -> V(system base)"]
        Z_MBtoSB = i0.Z_MBtoSB, [description = "Z(machine base) -> Z(system base)"]
        p0 = i0.p0, [description = "Initial active power generation (pu, system base)"]
        q0 = i0.q0, [description = "Initial reactive power generation (pu, system base)"]
        vr0 = i0.vr0, [description = "Init. val."]
        vi0 = i0.vi0, [description = "Init. val."]
        ir0 = i0.ir0, [description = "Init. val."]
        ii0 = i0.ii0, [description = "Init. val."]
        xq0 = xq0, [description = "used for setting the initial rotor angle"]
        delta0 = i0.delta0, [description = "Init. val. rotor angle"]
        vd0 = i0.vd0, [description = "Init. val."]
        vq0 = i0.vq0, [description = "Init. val."]
        id0 = i0.id0, [description = "Init. val."]
        iq0 = i0.iq0, [description = "Init. val."]
        pm00 = i0.pm00, [description = "Initial value (system base)"]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        delta(t), [description = "Rotor angle (rad)"]
        w(t), [description = "Rotor speed (pu)"]
        v(t), [description = "Generator terminal voltage (pu)"]
        P(t), [description = "Active power (pu)"]
        Q(t), [description = "Reactive power (pu)"]
        vf(t), [description = "Field voltage (pu)"]
        vf0(t), [description = "Initial field voltage (pu)"]
        pm0(t), [description = "Initial mechanical power (pu)"]
        pm(t), [description = "Mechanical power (pu)"]
        anglev(t), [description = "Bus voltage angle (rad)"]
        vd(t), [description = "d-axis voltage (pu)"]
        vq(t), [description = "q-axis voltage (pu)"]
        id(t), [description = "d-axis current (pu)"]
        iq(t), [description = "q-axis current (pu)"]
        pe(t), [description = "Electrical power transmitted through the air-gap (pu)"]
        vf_MB(t), [description = "Field voltage on machine base (pu)"]
    end
    eqs = Equation[
        v ~ sqrt(p.vr^2 + p.vi^2),
        anglev ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
        der(delta) ~ w_b * (w - 1),
        der(w) ~ ifelse(D > Modelica.Constants.eps, (pm * S_SBtoMB - pe - D * (w - 1)) / M, (pm * S_SBtoMB - pe) / M),
        p.ir ~ -(sin(delta) * id + cos(delta) * iq) * I_MBtoSB,
        p.ii ~ -(-cos(delta) * id + sin(delta) * iq) * I_MBtoSB,
        p.vr ~ (sin(delta) * vd + cos(delta) * vq) * V_MBtoSB,
        p.vi ~ (-cos(delta) * vd + sin(delta) * vq) * V_MBtoSB,
        P ~ -p.vr * p.ir - p.vi * p.ii,
        Q ~ -p.vi * p.ir + p.vr * p.ii,
        pe ~ (vq + ra * iq) * iq + (vd + ra * id) * id,
        pm0 ~ pm00,
        vf_MB ~ vf * V_b / Vn,
    ]
    # delta(start = delta0), w(start = 1), v(start = v_0), P(start = p0), Q(start = q0), pm0/pm(start = pm00),
    # anglev(start = angle_0), vd/vq/id/iq(start = ..0), pe(start = pm00), p(vr(start = vr0), ..., ii(start = ii0))
    extend(System(eqs, t, vars, pars; name, systems,
            initial_conditions = Dict(delta => delta0, w => 1.0),
            guesses = Dict(v => v_0, P => p0, Q => q0, pm0 => pm00, pm => pm00, anglev => angle_0, vd => vd0,
                vq => vq0, id => id0, iq => iq0, pe => pm00, p.vr => vr0, p.vi => vi0, p.ir => ir0, p.ii => ii0)),
        base)
end
