# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Sources/SourceBehindImpedance/BaseClasses/baseVoltageSource.mo (partial; extends
# Electrical/Essentials/pfComponent.mo)
# Base of the voltage sources behind an impedance: the pin p (PwPin_p) with its start values, the RealOutputs Emag,
# Edelta, Emag0, Eang0 as plain variables, the internal phasor Er + j Ei. The protected initial values are computed
# before `@parameters` (F-22); every `start` is a guess (F-20). Children `@unpack E, delta, Er, Ei, Er0, Ei0, E0,
# delta0 = base` and add the equations that fix the internal source. Deviation, Julia only (F-16/F-21): the two
# equations that link the internal phasor to the pin, E = V - CoB (R_a + j X_d) I, are written solved for the pin
# current, I = (V - E) conj(Z)/|Z|^2 with Z = CoB (R_a + j X_d), so that the tearing never pivots on a quantity that is
# zero at the initial guess (the residual form gave `Inf` in the SMIB Tests). Same relation for Z != 0 (OpenIPSL's
# defaults R_a = 1e-3, X_d = 0.2). Omitted: displayPF (disabled), graphical annotations.

@component function baseVoltageSource(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b = S_b, R_a = 1e-3, X_d = 0.2)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, R_a, X_d = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, R_a, X_d))   # F-21
    CoB = M_b / S_b
    p0 = P_0 / M_b
    q0 = Q_0 / M_b
    vr0 = v_0 * cos(angle_0)
    vi0 = v_0 * sin(angle_0)
    ir0 = -CoB * (p0 * vr0 + q0 * vi0) / (vr0^2 + vi0^2)
    ii0 = -CoB * (p0 * vi0 - q0 * vr0) / (vr0^2 + vi0^2)
    Er0 = vr0 + CoB * R_a * ir0 - CoB * X_d * ii0
    Ei0 = vi0 + CoB * R_a * ii0 + CoB * X_d * ir0
    E0 = sqrt(Er0^2 + Ei0^2)
    delta0 = atan(Ei0, Er0)   # atan2
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack S_b, P_0, Q_0, v_0, angle_0 = base
    pars = @parameters begin
        M_b = M_b, [description = "Voltage source base power rating (VA)"]
        R_a = R_a, [description = "Internal source resistance (pu, system base)"]
        X_d = X_d, [description = "Internal source d-axis reactance (pu, system base)"]
        CoB = CoB, [description = "Change from system to machine base"]
        p0 = p0, [description = "Initial active power (machine base, pu)"]
        q0 = q0, [description = "Initial reactive power (machine base, pu)"]
        vr0 = vr0, [description = "Initial value of the real part of the terminal voltage (pu)"]
        vi0 = vi0, [description = "Initial value of the imaginary part of the terminal voltage (pu)"]
        ir0 = ir0, [description = "Initial value of the real part of the current (pu)"]
        ii0 = ii0, [description = "Initial value of the imaginary part of the current (pu)"]
        Er0 = Er0, [description = "Initial value of the real part of the internal voltage source phasor (pu)"]
        Ei0 = Ei0, [description = "Initial value of the imaginary part of the internal voltage source phasor (pu)"]
        E0 = E0, [description = "Initial value of the internal voltage source phasor magnitude (pu)"]
        delta0 = delta0, [description = "Initial value of the internal voltage source phasor angle (rad)"]
    end
    systems = @named begin
        p = PwPin_p()
    end
    vars = @variables begin
        Emag(t), [description = "Internal voltage magnitude (pu)"]
        Edelta(t), [description = "Internal voltage angle (rad)"]
        Emag0(t), [description = "Initial value of the internal voltage source magnitude (pu)"]
        Eang0(t), [description = "Initial value of the internal voltage angle (rad)"]
        V(t), [description = "Bus voltage magnitude (pu)"]
        anglev(t), [description = "Bus voltage angle (rad)"]
        P(t), [description = "Active power (system base, pu)"]
        Q(t), [description = "Reactive power (system base, pu)"]
        delta(t), [description = "Internal voltage source angle (rad)"]
        E(t), [description = "Internal voltage source magnitude (pu)"]
        Er(t), [description = "Internal voltage source, real part (pu)"]
        Ei(t), [description = "Internal voltage source, imaginary part (pu)"]
    end
    Zr, Zi = CoB * R_a, CoB * X_d   # E = V - Z I  ->  I = (V - E) conj(Z)/|Z|^2 (see header)
    eqs = Equation[
        p.ir ~ ((p.vr - Er) * Zr + (p.vi - Ei) * Zi) / (Zr^2 + Zi^2),
        p.ii ~ ((p.vi - Ei) * Zr - (p.vr - Er) * Zi) / (Zr^2 + Zi^2),
        -P ~ p.vr * p.ir + p.vi * p.ii,
        -Q ~ p.vi * p.ir - p.vr * p.ii,
        V ~ sqrt(p.vr^2 + p.vi^2),
        anglev ~ atan(p.vi, p.vr),   # atan2
        Emag ~ sqrt(Er^2 + Ei^2),
        Edelta ~ atan(Ei, Er),   # atan2
        Emag0 ~ E0,
        Eang0 ~ delta0,
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            guesses = Dict(p.vr => vr0, p.vi => vi0, p.ir => ir0, p.ii => ii0, Emag => E0, Edelta => delta0, Emag0 => E0,
                Eang0 => delta0, V => v_0, anglev => angle_0, P => P_0 / S_b, Q => Q_0 / S_b, delta => delta0, E => E0,
                Er => Er0, Ei => Ei0)),
        base)
end
