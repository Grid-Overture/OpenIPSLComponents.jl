# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSSE/GENCLS.mo (extends Electrical/Essentials/pfComponent.mo)
# Classical generator that also serves as an infinite bus (H = 0). `if abs(H) > eps` is decided in Julia on the
# keyword argument (H = 0: `der(delta) = der(omega) = 0`, the states stay at delta0 and 0). The protected initial
# values are computed before `@parameters`; delta, omega and eq have `fixed = true` in the .mo (initial_conditions),
# the other start values are guesses (F-20). The 2x2 rotation matrices are written out. `Icons.VerifiedModel` (G) is
# omitted, as are displayPF (disabled) and graphical annotations.

@component function GENCLS(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b = 100e6, H = 0, D = 0, R_a = 0, X_d = 0.2)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, H, D, R_a, X_d =
        float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, H, D, R_a, X_d))   # F-21
    CoB = M_b / S_b
    p0 = P_0 / M_b
    q0 = Q_0 / M_b
    vr0 = v_0 * cos(angle_0)
    vi0 = v_0 * sin(angle_0)
    ir0 = (p0 * vr0 + q0 * vi0) / (vr0^2 + vi0^2)
    ii0 = (p0 * vi0 - q0 * vr0) / (vr0^2 + vi0^2)
    delta0 = atan(vi0 + R_a * ii0 + X_d * ir0, vr0 + R_a * ir0 - X_d * ii0)   # atan2
    vd0 = vr0 * cos(pi / 2 - delta0) - vi0 * sin(pi / 2 - delta0)
    vq0 = vr0 * sin(pi / 2 - delta0) + vi0 * cos(pi / 2 - delta0)
    id0 = ir0 * cos(pi / 2 - delta0) - ii0 * sin(pi / 2 - delta0)
    iq0 = ir0 * sin(pi / 2 - delta0) + ii0 * cos(pi / 2 - delta0)
    vf0 = vq0 + R_a * iq0 + X_d * id0
    inertial = abs(H) > Modelica.Constants.eps   # decided before @parameters rebinds H (F-22)
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    @unpack S_b, fn, P_0, v_0, angle_0 = base
    pars = @parameters begin
        M_b = M_b, [description = "Machine base power rating (VA)"]
        H = H, [description = "Inertia constant (s)"]
        D = D, [description = "Damping coefficient"]
        R_a = R_a, [description = "Armature resistance (pu)"]
        X_d = X_d, [description = "d-axis transient reactance (pu)"]
        CoB = CoB, [description = "Change from system to machine base"]
        p0 = p0, [description = "Initial active power (machine base, pu)"]
        q0 = q0, [description = "Initial reactive power (machine base, pu)"]
        vr0 = vr0
        vi0 = vi0
        ir0 = ir0
        ii0 = ii0
        delta0 = delta0
        vd0 = vd0
        vq0 = vq0
        id0 = id0
        iq0 = iq0
        vf0 = vf0
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        delta(t), [description = "Rotor angle (rad)"]
        omega(t), [description = "Rotor speed deviation (pu)"]
        V(t), [description = "Bus voltage magnitude (pu)"]
        anglev(t), [description = "Bus voltage angle (rad)"]
        eq(t), [description = "Constant emf behind transient reactance (pu)"]
        vd(t), [description = "d-axis voltage (pu)"]
        vq(t), [description = "q-axis voltage (pu)"]
        id(t), [description = "d-axis current (pu)"]
        iq(t), [description = "q-axis current (pu)"]
        P(t), [description = "Active power (system base, pu)"]
        Q(t), [description = "Reactive power (system base, pu)"]
    end
    swing = inertial ? Equation[
        der(delta) ~ omega * 2 * pi * fn,
        der(omega) ~ (P_0 / S_b - P - D * omega) / (2 * H),
    ] : Equation[
        der(delta) ~ 0,
        der(omega) ~ 0,
    ]
    eqs = Equation[
        swing...,
        der(eq) ~ 0,   # classical model assumes constant emf
        vq ~ eq - R_a * iq - X_d * id,
        vd ~ X_d * iq - R_a * id,
        p.ir ~ -CoB * (sin(delta) * id + cos(delta) * iq),
        p.ii ~ -CoB * (-cos(delta) * id + sin(delta) * iq),
        p.vr ~ sin(delta) * vd + cos(delta) * vq,
        p.vi ~ -cos(delta) * vd + sin(delta) * vq,
        -P ~ p.vr * p.ir + p.vi * p.ii,
        -Q ~ p.vi * p.ir - p.vr * p.ii,
        V ~ sqrt(p.vr^2 + p.vi^2),
        anglev ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            initial_conditions = Dict(delta => delta0, omega => 0.0, eq => vf0),
            guesses = Dict(V => v_0, anglev => angle_0, vd => vd0, vq => vq0, id => id0, iq => iq0, P => P_0 / S_b,
                Q => q0 * CoB, p.vr => vr0, p.vi => vi0, p.ir => ir0, p.ii => ii0)),
        base)
end
