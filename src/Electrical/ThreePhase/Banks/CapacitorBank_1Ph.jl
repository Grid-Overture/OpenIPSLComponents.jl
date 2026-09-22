# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Banks/CapacitorBank_1Ph.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Single-phase capacitor bank over the phase base S_p, Q_a in var. Omitted: graphical annotations.
# The .mo writes  Pa = A.vr*A.ir + A.vi*A.ii  with Pa = 0  and
# Qa = (-A.vi*A.ir + A.vr*A.ii)/(A.vr^2 + A.vi^2)  with Qa = Q_a/S_p, i.e. the constant admittance j*Qa (note that
# Qa is divided by v^2 there, so it is an admittance and not a power, sic).
# Deviation, Julia only (F-16): the pair is written solved for the currents, A.ir = -Qa*A.vi, A.ii = Qa*A.vr -
# its exact solution for v != 0, without the v = 0 branch ModelingToolkit tearing falls into.
# Sign: with V = 1 angle 0 the absorbed reactive power vi*ir - vr*ii is -Qa, so the bank injects Q_a (capacitive).

@component function CapacitorBank_1Ph(; name, S_b = 100e6, fn = 50, VA = 1, AngA = 0, Q_a = 0)
    @named base = ThreePhaseComponent(; S_b)
    @unpack S_p = base
    VA, AngA, Q_a = float.((VA, AngA, Q_a))   # F-21
    n = (; VA, AngA)
    pars = @parameters begin
        VA = VA, [description = "Voltage magnitude (pu)"]
        AngA = AngA, [description = "Voltage angle for phase A (rad)"]
        Q_a = Q_a, [description = "Initial reactive power (var)"]
    end
    systems = @named begin
        A = PwPin()
    end
    vars = @variables begin
        Pa(t), [description = "Active power of phase A (pu)"]
        Qa(t), [description = "Reactive admittance of phase A (pu)"]
    end
    eqs = Equation[
        Pa ~ 0,
        Qa ~ Q_a / S_p,
        A.ir ~ -Qa * A.vi,   # 0 = A.vr*A.ir + A.vi*A.ii (see header)
        A.ii ~ Qa * A.vr,    # Qa = (-A.vi*A.ir + A.vr*A.ii)/(A.vr^2 + A.vi^2)
    ]
    # A(vr(start = var0), vi(start = vai0))
    extend(System(eqs, t, vars, pars; name, systems,
        guesses = Dict(A.vr => n.VA * cos(n.AngA), A.vi => n.VA * sin(n.AngA))), base)
end
