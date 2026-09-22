# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Loads/Dyn_wye_2Ph_balanced.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Variable balanced two-phase wye load: `P0`/`Q0` are the whole load and each phase takes half of it.
# `P_in`/`Q_in` are the two `RealInput`s, plain variables as everywhere in the port, and they are in per unit of the
# PHASE base and they are the TOTAL load: `P_a = P_in*S_p/2` while the pin equation is
# `P_a = (A.vr*A.ir + A.vi*A.ii)*S_p`, so each pin carries `P_in/2` per unit and the system base never appears
# (sic). `P_a`, `Q_a`, ... are `protected` in the `.mo`
# (OpenModelica does not write them to the result file): they are variables here, with the `start` values the `.mo`
# gives them as `guesses` (rule 6.2). Omitted: graphical annotations, the unused `import Modelica.Blocks.Interfaces.*`.
# Deviation, Julia only (F-16, the form of `WyeLoad_1Ph`): the two bilinear definitions per phase,
# `P_a = (A.vr*A.ir + A.vi*A.ii)*S_p` and `Q_a = (A.vi*A.ir - A.vr*A.ii)*S_p`, are written solved for the currents -
# identical for v != 0 and without the v = 0 branch ModelingToolkit's tearing falls into.

@component function Dyn_wye_2Ph_balanced(; name, S_b = 100e6, fn = 50, P0, Q0)
    @named base = ThreePhaseComponent(; S_b)
    @unpack S_p = base
    P0, Q0 = float.((P0, Q0))   # F-21
    n = (; P0, Q0)
    pars = @parameters begin
        P0 = P0, [description = "Initial active power (W)"]
        Q0 = Q0, [description = "Initial reactive power (var)"]
    end
    systems = @named begin
        A = PwPin()
        B = PwPin()
    end
    vars = @variables begin
        P_in(t), [description = "External P, total of the 2 phases (pu of the phase base)"]
        Q_in(t), [description = "External Q, total of the 2 phases (pu of the phase base)"]
        P_a(t), [description = "Active power of phase a (W)"]
        Q_a(t), [description = "Reactive power of phase a (var)"]
        P_b(t), [description = "Active power of phase b (W)"]
        Q_b(t), [description = "Reactive power of phase b (var)"]
    end
    eqs = Equation[
        P_a ~ P_in * S_p / 2,
        P_b ~ P_in * S_p / 2,
        Q_a ~ Q_in * S_p / 2,
        Q_b ~ Q_in * S_p / 2,
        A.ir ~ (P_a / S_p * A.vr + Q_a / S_p * A.vi) / (A.vr^2 + A.vi^2),   # P_a = (A.vr*A.ir + A.vi*A.ii)*S_p, F-16
        A.ii ~ (P_a / S_p * A.vi - Q_a / S_p * A.vr) / (A.vr^2 + A.vi^2),   # Q_a = (A.vi*A.ir - A.vr*A.ii)*S_p
        B.ir ~ (P_b / S_p * B.vr + Q_b / S_p * B.vi) / (B.vr^2 + B.vi^2),
        B.ii ~ (P_b / S_p * B.vi - Q_b / S_p * B.vr) / (B.vr^2 + B.vi^2),
    ]
    # P_a(start = P0 / 2), Q_a(start = Q0 / 2), ...
    extend(System(eqs, t, vars, pars; name, systems,
        guesses = Dict(P_a => n.P0 / 2,
            Q_a => n.Q0 / 2,
            P_b => n.P0 / 2,
            Q_b => n.Q0 / 2)), base)
end
