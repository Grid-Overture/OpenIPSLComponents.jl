# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSSE/BaseClasses/baseMachine.mo (partial; extends Electrical/Essentials/pfComponent.mo)
# Base of the PSSE machines. Julia name `PSSE_baseMachine`: `baseMachine` is already the PSAT base. The eleven causal
# ports (SPEED, PMECH, PMECH0, ETERM, EFD, EFD0, PELEC, ISORCE, ANGLE, XADIFD, QELEC) are plain variables; the two
# inputs PMECH and EFD carry no equation here, the Test (`gENROU.PMECH ~ gENROU.PMECH0`) or `Plant` closes them.
# `w(start = w0, fixed = true)` is the only initial condition of the base; `delta` has no start here (each child adds
# `delta(start = delta0, fixed = true)`), every other `start` is a guess (F-20). `QELEC(start = p0)` is the .mo's own
# value, p0 and not q0: replicated. The protected constants CoB, p0, q0, vr0, vi0, ir0, ii0, w_b are declared only
# here; GENROU/GENROE/GENTPJ redeclare them identically in the .mo (Modelica merges identical declarations) and the
# Julia children take them with `@unpack`. The 2x2 rotation matrices are written by components. Omitted: displayPF
# (disabled), the Dialog groups and graphical annotations.

@component function PSSE_baseMachine(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0, M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq, Xpd, Xppd, Xppq, Xl, S10, S12, R_a = 0, w0 = 0)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq, Xpd, Xppd, Xppq, Xl, S10, S12,
    R_a, w0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Tpd0, Tppd0, Tppq0, H, D, Xd, Xq, Xpd, Xppd, Xppq,
        Xl, S10, S12, R_a, w0))   # F-21
    w_b = 2 * pi * fn
    CoB = M_b / S_b
    p0 = P_0 / M_b
    q0 = Q_0 / M_b
    vr0 = v_0 * cos(angle_0)
    vi0 = v_0 * sin(angle_0)
    ir0 = -CoB * (p0 * vr0 + q0 * vi0) / (vr0^2 + vi0^2)
    ii0 = -CoB * (p0 * vi0 - q0 * vr0) / (vr0^2 + vi0^2)
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack S_b, P_0, Q_0, v_0, angle_0 = base
    pars = @parameters begin
        M_b = M_b, [description = "Machine base power (VA)"]
        Tpd0 = Tpd0, [description = "d-axis transient open-circuit time constant (s)"]
        Tppd0 = Tppd0, [description = "d-axis sub-transient open-circuit time constant (s)"]
        Tppq0 = Tppq0, [description = "q-axis sub-transient open-circuit time constant (s)"]
        H = H, [description = "Inertia constant (s)"]
        D = D, [description = "Speed damping"]
        Xd = Xd, [description = "d-axis reactance (pu)"]
        Xq = Xq, [description = "q-axis reactance (pu)"]
        Xpd = Xpd, [description = "d-axis transient reactance (pu)"]
        Xppd = Xppd, [description = "d-axis sub-transient reactance (pu)"]
        Xppq = Xppq, [description = "q-axis sub-transient reactance (pu)"]
        Xl = Xl, [description = "leakage reactance (pu)"]
        S10 = S10, [description = "Saturation factor at 1.0 pu"]
        S12 = S12, [description = "Saturation factor at 1.2 pu"]
        R_a = R_a, [description = "Armature resistance (pu)"]
        w0 = w0, [description = "Initial speed deviation from nominal (pu)"]
        w_b = w_b, [description = "System base speed (rad/s)"]
        CoB = CoB, [description = "Change from system to machine base"]
        vr0 = vr0, [description = "Real component of initial terminal voltage"]
        vi0 = vi0, [description = "Imaginary component of initial terminal voltage"]
        ir0 = ir0, [description = "Real component of initial armature current (system base)"]
        ii0 = ii0, [description = "Imaginary component of initial armature current (system base)"]
        p0 = p0, [description = "Initial active power generation (machine base)"]
        q0 = q0, [description = "Initial reactive power generation (machine base)"]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        SPEED(t), [description = "Machine speed deviation from nominal (pu)"]
        PMECH(t), [description = "Turbine mechanical power (machine base)"]
        PMECH0(t), [description = "Initial value of machine electrical power (machine base)"]
        ETERM(t), [description = "Machine terminal voltage (pu)"]
        EFD(t), [description = "Generator main field voltage (pu)"]
        EFD0(t), [description = "Initial generator main field voltage (pu)"]
        PELEC(t), [description = "Machine electrical power (machine base)"]
        ISORCE(t), [description = "Machine source current (pu)"]
        ANGLE(t), [description = "Machine relative rotor angle"]
        XADIFD(t), [description = "Machine field current (pu)"]
        QELEC(t), [description = "Machine electrical power (machine base)"]
        w(t), [description = "Machine speed deviation"]
        delta(t), [description = "Rotor angle"]
        Vt(t), [description = "Bus voltage magnitude"]
        anglev(t), [description = "Bus voltage angle"]
        I(t), [description = "Terminal current magnitude"]
        anglei(t), [description = "Terminal current angle"]
        P(t), [description = "Active power (system base)"]
        Q(t), [description = "Reactive power (system base)"]
        Te(t), [description = "Electrical torque (pu)"]
        id(t), [description = "d-axis armature current (pu)"]
        iq(t), [description = "q-axis armature current (pu)"]
        ud(t), [description = "d-axis terminal voltage (pu)"]
        uq(t), [description = "q-axis terminal voltage (pu)"]
    end
    eqs = Equation[
        ANGLE ~ delta,
        SPEED ~ w,
        ETERM ~ Vt,
        PELEC ~ P / CoB,
        QELEC ~ Q / CoB,
        p.ir ~ -CoB * (sin(delta) * id + cos(delta) * iq),
        p.ii ~ -CoB * (-cos(delta) * id + sin(delta) * iq),
        p.vr ~ sin(delta) * ud + cos(delta) * uq,
        p.vi ~ -cos(delta) * ud + sin(delta) * uq,
        -P ~ p.vr * p.ir + p.vi * p.ii,
        -Q ~ p.vi * p.ir - p.vr * p.ii,
        Vt ~ sqrt(p.vr^2 + p.vi^2),
        anglev ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
        I ~ sqrt(p.ii^2 + p.ir^2),
        anglei ~ atan(p.ii, p.ir),   # atan2(p.ii, p.ir)
        der(w) ~ ((PMECH - D * w) / (w + 1) - Te) / (2 * H),
        der(delta) ~ w_b * w,
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            initial_conditions = Dict(w => w0),
            guesses = Dict(ETERM => v_0, PELEC => p0, QELEC => p0, Vt => v_0, anglev => angle_0,
                I => sqrt(ir0^2 + ii0^2), anglei => atan(ii0, ir0), P => P_0 / S_b, Q => Q_0 / S_b,
                p.vr => vr0, p.vi => vi0, p.ir => ir0, p.ii => ii0)),
        base)
end
