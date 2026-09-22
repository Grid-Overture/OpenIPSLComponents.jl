# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Buses/InfiniteBus.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Named `ThreePhase_InfiniteBus` in Julia: the PSAT `Electrical/Buses/InfiniteBus.mo` of batch 2 keeps the plain name
# (package rule 6.5), the file keeps its mirror path. Fixes the three pin voltages and reports the power each phase
# supplies in W/var over the PHASE base S_p. Omitted: graphical annotations.
# `V_b`, `fn` and `P_A..Q_C` are accepted and inert: `P_*`/`Q_*` are the "initial power" of the icon display and no
# equation reads them. `Qa = -(vr*ii - vi*ir)*S_p` keeps the sign of the PSAT infinite bus, sic.
# `IEEE13` passes `angle_B = -120`, `angle_C = 120` in radians (F-79); here they enter the equations as given.

@component function ThreePhase_InfiniteBus(; name, S_b = 100e6, V_b = 400e3, fn = 50,
        V_A = 1, angle_A = 0, V_B = 1, angle_B = -2pi / 3, V_C = 1, angle_C = 2pi / 3,
        P_A = 1e6, Q_A = 0, P_B = 1e6, Q_B = 0, P_C = 1e6, Q_C = 0)
    @named base = ThreePhaseComponent(; S_b)
    @unpack S_p = base
    V_A, angle_A, V_B, angle_B, V_C, angle_C = float.((V_A, angle_A, V_B, angle_B, V_C, angle_C))   # F-21
    P_A, Q_A, P_B, Q_B, P_C, Q_C = float.((P_A, Q_A, P_B, Q_B, P_C, Q_C))
    pars = @parameters begin
        V_b = float(V_b), [description = "Base voltage of the bus (V)"]
        V_A = V_A, [description = "Voltage magnitude for phase A (pu)"]
        angle_A = angle_A, [description = "Voltage angle for phase A (rad)"]
        V_B = V_B, [description = "Voltage magnitude for phase B (pu)"]
        angle_B = angle_B, [description = "Voltage angle for phase B (rad)"]
        V_C = V_C, [description = "Voltage magnitude for phase C (pu)"]
        angle_C = angle_C, [description = "Voltage angle for phase C (rad)"]
        P_A = P_A, [description = "Initial active power (W)"]
        Q_A = Q_A, [description = "Initial reactive power (var)"]
        P_B = P_B, [description = "Initial active power (W)"]
        Q_B = Q_B, [description = "Initial reactive power (var)"]
        P_C = P_C, [description = "Initial active power (W)"]
        Q_C = Q_C, [description = "Initial reactive power (var)"]
        fn = float(fn), [description = "System frequency (Hz)"]
    end
    systems = @named begin
        p1 = PwPin()
        p2 = PwPin()
        p3 = PwPin()
    end
    vars = @variables begin
        Pa(t), [description = "Active power supplied by the infinite bus, phase a (W)"]
        Qa(t), [description = "Reactive power supplied by the infinite bus, phase a (var)"]
        Pb(t), [description = "Active power supplied by the infinite bus, phase b (W)"]
        Qb(t), [description = "Reactive power supplied by the infinite bus, phase b (var)"]
        Pc(t), [description = "Active power supplied by the infinite bus, phase c (W)"]
        Qc(t), [description = "Reactive power supplied by the infinite bus, phase c (var)"]
        P(t), [description = "Active power for icon display (W)"]
        Q(t), [description = "Reactive power for icon display (var)"]
    end
    eqs = Equation[
        P ~ Pa + Pb + Pc,
        Q ~ Qa + Qb + Qc,
        # Equations for Phase A
        p1.vr ~ V_A * cos(angle_A),
        p1.vi ~ V_A * sin(angle_A),
        Pa ~ -(p1.vr * p1.ir + p1.vi * p1.ii) * S_p,
        Qa ~ -(p1.vr * p1.ii - p1.vi * p1.ir) * S_p,
        # Equations for Phase B
        p2.vr ~ V_B * cos(angle_B),
        p2.vi ~ V_B * sin(angle_B),
        Pb ~ -(p2.vr * p2.ir + p2.vi * p2.ii) * S_p,
        Qb ~ -(p2.vr * p2.ii - p2.vi * p2.ir) * S_p,
        # Equations for Phase C
        p3.vr ~ V_C * cos(angle_C),
        p3.vi ~ V_C * sin(angle_C),
        Pc ~ -(p3.vr * p3.ir + p3.vi * p3.ii) * S_p,
        Qc ~ -(p3.vr * p3.ii - p3.vi * p3.ir) * S_p,
    ]
    extend(System(eqs, t, vars, pars; name, systems), base)
end
