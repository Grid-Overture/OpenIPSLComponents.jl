# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Loads/WyeLoad_2Ph.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Two-phase wye load over the phase base S_p, powers in W/var: WyeLoad_1Ph twice, see its header for the
# `ModelType` decision (F-50) and the current-explicit form of the pins (F-16). The protected matrices
# `TPhasePower` (a `parameter` here) and `ZIP_coef`, the variables `Va2`/`Vb2` and the eight `parameter` start
# values `var0`..`ibi0` are written inline, the last eight as `guesses` of the two pins (rule 6.2), which is the
# same expression the `.mo` uses. Note that the pin equations of this model carry no `S_p` (`Pa = A.vr*A.ir +
# A.vi*A.ii`, already per unit). Omitted: graphical annotations.

@component function WyeLoad_2Ph(; name, S_b = 100e6, fn = 50, ModelType = 0,
        P_a = 1e6, Q_a = 0, P_b = 1e6, Q_b = 0, VA = 1, AngA = 0, VB = 1, AngB = -2pi / 3,
        A_pa = 0, B_pa = 0, C_pa = 0, A_pb = 0, B_pb = 0, C_pb = 0)
    @named base = ThreePhaseComponent(; S_b)
    @unpack S_p = base
    P_a, Q_a, P_b, Q_b = float.((P_a, Q_a, P_b, Q_b))   # F-21
    VA, AngA, VB, AngB = float.((VA, AngA, VB, AngB))
    A_pa, B_pa, C_pa, A_pb, B_pb, C_pb = float.((A_pa, B_pa, C_pa, A_pb, B_pb, C_pb))
    n = (; P_a, Q_a, P_b, Q_b, VA, AngA, VB, AngB, S_p = float(S_b) / 3)
    pars = @parameters begin
        P_a = P_a, [description = "Active power for phase A (W)"]
        Q_a = Q_a, [description = "Reactive power for phase A (var)"]
        P_b = P_b, [description = "Active power for phase B (W)"]
        Q_b = Q_b, [description = "Reactive power for phase B (var)"]
        VA = VA, [description = "Guess value for phase A magnitude (pu)"]
        AngA = AngA, [description = "Guess value for phase A angle (rad)"]
        VB = VB, [description = "Guess value for phase B magnitude (pu)"]
        AngB = AngB, [description = "Guess value for phase B angle (rad)"]
        A_pa = A_pa, [description = "Percentage of constant power load for phase A (%)"]
        B_pa = B_pa, [description = "Percentage of constant current load for phase A (%)"]
        C_pa = C_pa, [description = "Percentage of constant impedance load for phase A (%)"]
        A_pb = A_pb, [description = "Percentage of constant power load for phase B (%)"]
        B_pb = B_pb, [description = "Percentage of constant current load for phase B (%)"]
        C_pb = C_pb, [description = "Percentage of constant impedance load for phase B (%)"]
    end
    systems = @named begin
        A = PwPin()
        B = PwPin()
    end
    vars = @variables begin
        Va(t), [description = "Voltage magnitude at pin A (pu)"]
        Vb(t), [description = "Voltage magnitude at pin B (pu)"]
        Coef_A(t), [description = "ZIP coefficient for phase A"]
        Coef_B(t), [description = "ZIP coefficient for phase B"]
        Pa(t), [description = "Active power of phase A (pu)"]
        Pb(t), [description = "Active power of phase B (pu)"]
        Qa(t), [description = "Reactive power of phase A (pu)"]
        Qb(t), [description = "Reactive power of phase B (pu)"]
    end
    # function Coefficients(in_coef, ModelType): [1, 1] or in_coef (F-50)
    CoefA, CoefB = ModelType == 0 ? (1, 1) : (Coef_A, Coef_B)
    eqs = Equation[
        Va ~ sqrt(A.vr^2 + A.vi^2),
        Vb ~ sqrt(B.vr^2 + B.vi^2),
        Coef_A ~ A_pa / 100 + B_pa / 100 * Va + C_pa / 100 * Va^2,
        Coef_B ~ A_pb / 100 + B_pb / 100 * Vb + C_pb / 100 * Vb^2,
        Pa ~ P_a / S_p * CoefA,
        Pb ~ P_b / S_p * CoefB,
        Qa ~ Q_a / S_p * CoefA,
        Qb ~ Q_b / S_p * CoefB,
        A.ir ~ (Pa * A.vr + Qa * A.vi) / (A.vr^2 + A.vi^2),   # Pa = A.vr*A.ir + A.vi*A.ii (F-16)
        A.ii ~ (Pa * A.vi - Qa * A.vr) / (A.vr^2 + A.vi^2),   # Qa = A.vi*A.ir - A.vr*A.ii
        B.ir ~ (Pb * B.vr + Qb * B.vi) / (B.vr^2 + B.vi^2),
        B.ii ~ (Pb * B.vi - Qb * B.vr) / (B.vr^2 + B.vi^2),
    ]
    var0, vai0 = n.VA * cos(n.AngA), n.VA * sin(n.AngA)
    vbr0, vbi0 = n.VB * cos(n.AngB), n.VB * sin(n.AngB)
    iar0 = (n.P_a / n.S_p * var0 + n.Q_a / n.S_p * vai0) / (var0^2 + vai0^2)
    iai0 = (n.P_a / n.S_p * vai0 - n.Q_a / n.S_p * var0) / (var0^2 + vai0^2)
    ibr0 = (n.P_b / n.S_p * vbr0 + n.Q_b / n.S_p * vbi0) / (vbr0^2 + vbi0^2)
    ibi0 = (n.P_b / n.S_p * vbi0 - n.Q_b / n.S_p * vbr0) / (vbr0^2 + vbi0^2)
    # A(vr(start = var0), vi(start = vai0), ir(start = iar0), ii(start = iai0)), B(...)
    extend(System(eqs, t, vars, pars; name, systems,
        guesses = Dict(A.vr => var0, A.vi => vai0, A.ir => iar0, A.ii => iai0,
            B.vr => vbr0, B.vi => vbi0, B.ir => ibr0, B.ii => ibi0)), base)
end
