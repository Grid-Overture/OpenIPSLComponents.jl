# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Banks/CapacitorBank_3Ph.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Three-phase capacitor bank; same shape as CapacitorBank_1Ph, see its header for the current-explicit form (F-16)
# and the sign. Omitted: graphical annotations, the unused `import Modelica.Constants.pi`.

@component function CapacitorBank_3Ph(; name, S_b = 100e6, fn = 50,
        VA = 1, AngA = 0, VB = 1, AngB = -2pi / 3, VC = 1, AngC = 2pi / 3, Q_a = 0, Q_b = 0, Q_c = 0)
    @named base = ThreePhaseComponent(; S_b)
    @unpack S_p = base
    VA, AngA, VB, AngB, VC, AngC = float.((VA, AngA, VB, AngB, VC, AngC))   # F-21
    Q_a, Q_b, Q_c = float.((Q_a, Q_b, Q_c))
    n = (; VA, AngA, VB, AngB, VC, AngC)
    pars = @parameters begin
        VA = VA, [description = "Voltage magnitude (pu)"]
        AngA = AngA, [description = "Voltage angle for phase A (rad)"]
        VB = VB, [description = "Voltage magnitude (pu)"]
        AngB = AngB, [description = "Voltage angle for phase B (rad)"]
        VC = VC, [description = "Voltage magnitude (pu)"]
        AngC = AngC, [description = "Voltage angle for phase C (rad)"]
        Q_a = Q_a, [description = "Initial reactive power (var)"]
        Q_b = Q_b, [description = "Initial reactive power (var)"]
        Q_c = Q_c, [description = "Initial reactive power (var)"]
    end
    systems = @named begin
        A = PwPin()
        B = PwPin()
        C = PwPin()
    end
    vars = @variables begin
        Pa(t), [description = "Active power of phase A (pu)"]
        Pb(t), [description = "Active power of phase B (pu)"]
        Pc(t), [description = "Active power of phase C (pu)"]
        Qa(t), [description = "Reactive admittance of phase A (pu)"]
        Qb(t), [description = "Reactive admittance of phase B (pu)"]
        Qc(t), [description = "Reactive admittance of phase C (pu)"]
    end
    eqs = Equation[
        Pa ~ 0,
        Pb ~ 0,
        Pc ~ 0,
        Qa ~ Q_a / S_p,
        Qb ~ Q_b / S_p,
        Qc ~ Q_c / S_p,
        A.ir ~ -Qa * A.vi,   # 0 = A.vr*A.ir + A.vi*A.ii (CapacitorBank_1Ph header, F-16)
        A.ii ~ Qa * A.vr,    # Qa = (-A.vi*A.ir + A.vr*A.ii)/(A.vr^2 + A.vi^2)
        B.ir ~ -Qb * B.vi,
        B.ii ~ Qb * B.vr,
        C.ir ~ -Qc * C.vi,
        C.ii ~ Qc * C.vr,
    ]
    # A(vr(start = var0), vi(start = vai0)), B(...), C(...)
    extend(System(eqs, t, vars, pars; name, systems,
        guesses = Dict(A.vr => n.VA * cos(n.AngA), A.vi => n.VA * sin(n.AngA),
            B.vr => n.VB * cos(n.AngB), B.vi => n.VB * sin(n.AngB),
            C.vr => n.VC * cos(n.AngC), C.vi => n.VC * sin(n.AngC))), base)
end
