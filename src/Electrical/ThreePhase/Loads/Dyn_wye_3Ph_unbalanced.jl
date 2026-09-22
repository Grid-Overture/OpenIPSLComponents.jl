# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Loads/Dyn_wye_3Ph_unbalanced.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Variable unbalanced three-phase wye load: each phase follows its own element of the two input vectors.
# `P_in`/`Q_in` are the two `RealInput`s, plain variables as everywhere in the port, and they are in per unit of the
# PHASE base: `P_a = P_in*S_p` while the pin equation is `P_a = (A.vr*A.ir + A.vi*A.ii)*S_p`, so the pin carries
# `P_in` per unit and the system base never appears (sic). `P_a`, `Q_a`, ... are `protected` in the `.mo`
# (OpenModelica does not write them to the result file): they are variables here, with the `start` values the `.mo`
# gives them as `guesses` (rule 6.2). Omitted: graphical annotations, the unused `import Modelica.Blocks.Interfaces.*`.
# Deviation, Julia only (F-16, the form of `WyeLoad_1Ph`): the two bilinear definitions per phase,
# `P_a = (A.vr*A.ir + A.vi*A.ii)*S_p` and `Q_a = (A.vi*A.ir - A.vr*A.ii)*S_p`, are written solved for the currents -
# identical for v != 0 and without the v = 0 branch ModelingToolkit's tearing falls into.
# `P_in` and `Q_in` are declared `RealInput[3]` in the `.mo`: array variables indexed after `getproperty`
# (rule 6.5), which is what the transcribed Test connects element by element.

@component function Dyn_wye_3Ph_unbalanced(; name, S_b = 100e6, fn = 50, P0_a, Q0_a, P0_b, Q0_b, P0_c, Q0_c)
    @named base = ThreePhaseComponent(; S_b)
    @unpack S_p = base
    P0_a, Q0_a, P0_b, Q0_b, P0_c, Q0_c = float.((P0_a, Q0_a, P0_b, Q0_b, P0_c, Q0_c))   # F-21
    n = (; P0_a, Q0_a, P0_b, Q0_b, P0_c, Q0_c)
    pars = @parameters begin
        P0_a = P0_a, [description = "Initial active power (W)"]
        Q0_a = Q0_a, [description = "Initial reactive power (var)"]
        P0_b = P0_b, [description = "Initial active power (W)"]
        Q0_b = Q0_b, [description = "Initial reactive power (var)"]
        P0_c = P0_c, [description = "Initial active power (W)"]
        Q0_c = Q0_c, [description = "Initial reactive power (var)"]
    end
    systems = @named begin
        A = PwPin()
        B = PwPin()
        C = PwPin()
    end
    vars = @variables begin
        (P_in(t))[1:3], [description = "External P (pu of the phase base)"]
        (Q_in(t))[1:3], [description = "External Q (pu of the phase base)"]
        P_a(t), [description = "Active power of phase a (W)"]
        Q_a(t), [description = "Reactive power of phase a (var)"]
        P_b(t), [description = "Active power of phase b (W)"]
        Q_b(t), [description = "Reactive power of phase b (var)"]
        P_c(t), [description = "Active power of phase c (W)"]
        Q_c(t), [description = "Reactive power of phase c (var)"]
    end
    eqs = Equation[
        P_a ~ P_in[1] * S_p,
        P_b ~ P_in[2] * S_p,
        P_c ~ P_in[3] * S_p,
        Q_a ~ Q_in[1] * S_p,
        Q_b ~ Q_in[2] * S_p,
        Q_c ~ Q_in[3] * S_p,
        A.ir ~ (P_a / S_p * A.vr + Q_a / S_p * A.vi) / (A.vr^2 + A.vi^2),   # P_a = (A.vr*A.ir + A.vi*A.ii)*S_p, F-16
        A.ii ~ (P_a / S_p * A.vi - Q_a / S_p * A.vr) / (A.vr^2 + A.vi^2),   # Q_a = (A.vi*A.ir - A.vr*A.ii)*S_p
        B.ir ~ (P_b / S_p * B.vr + Q_b / S_p * B.vi) / (B.vr^2 + B.vi^2),
        B.ii ~ (P_b / S_p * B.vi - Q_b / S_p * B.vr) / (B.vr^2 + B.vi^2),
        C.ir ~ (P_c / S_p * C.vr + Q_c / S_p * C.vi) / (C.vr^2 + C.vi^2),
        C.ii ~ (P_c / S_p * C.vi - Q_c / S_p * C.vr) / (C.vr^2 + C.vi^2),
    ]
    # P_a(start = P0_a), Q_a(start = Q0_a), ...
    extend(System(eqs, t, vars, pars; name, systems,
        guesses = Dict(P_a => n.P0_a,
            Q_a => n.Q0_a,
            P_b => n.P0_b,
            Q_b => n.Q0_b,
            P_c => n.P0_c,
            Q_c => n.Q0_c)), base)
end
