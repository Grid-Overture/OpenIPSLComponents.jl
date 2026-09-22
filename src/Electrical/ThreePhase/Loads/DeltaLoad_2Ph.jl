# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Loads/DeltaLoad_2Ph.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Two-phase delta load over the phase base S_p, powers in W/var. Omitted: graphical annotations; `TPhasePower`,
# `ZIP_coef`, `Vab2` and `in_coef` are written inline and the local `function Coefficients` is an `if` on the
# parameter `ModelType`, decided in Julia (F-50). The pin currents are already explicit in the .mo and are copied
# literally, so the F-16 rewrite of the wye loads is not needed here.
# Quirk kept: the ZIP coefficient uses the line voltage divided by sqrt(3) (`Vabr`), while the current equations use
# the raw difference A - B.

@component function DeltaLoad_2Ph(; name, S_b = 100e6, fn = 50, ModelType = 0, VA = 1, AngA = 0, VB = 1, AngB = -2pi / 3,
        P_ab = 1e6, Q_ab = 0, A_ab = 0, B_ab = 0, C_ab = 0)
    @named base = ThreePhaseComponent(; S_b)
    @unpack S_p = base
    VA, AngA, VB, AngB, P_ab, Q_ab = float.((VA, AngA, VB, AngB, P_ab, Q_ab))   # F-21
    A_ab, B_ab, C_ab = float.((A_ab, B_ab, C_ab))
    n = (; VA, AngA, VB, AngB, P_ab, Q_ab, S_p = float(S_b) / 3)
    pars = @parameters begin
        VA = VA, [description = "Voltage magnitude for phase A (pu)"]
        AngA = AngA, [description = "Voltage angle for phase A (rad)"]
        VB = VB, [description = "Voltage magnitude for phase B (pu)"]
        AngB = AngB, [description = "Voltage angle for phase B (rad)"]
        P_ab = P_ab, [description = "Initial active power (W)"]
        Q_ab = Q_ab, [description = "Initial reactive power (var)"]
        A_ab = A_ab, [description = "Percentage of constant power load for line AB (%)"]
        B_ab = B_ab, [description = "Percentage of constant current load for line AB (%)"]
        C_ab = C_ab, [description = "Percentage of constant impedance load for line AB (%)"]
    end
    systems = @named begin
        A = PwPin()
        B = PwPin()
    end
    vars = @variables begin
        Vabr(t), [description = "Real part of the line voltage AB (pu)"]
        Vabi(t), [description = "Imaginary part of the line voltage AB (pu)"]
        Vab(t), [description = "Line voltage magnitude AB (pu)"]
        Coef_A(t), [description = "ZIP coefficient for line AB"]
        Pab(t), [description = "Active power of line AB (pu)"]
        Qab(t), [description = "Reactive power of line AB (pu)"]
    end
    Coef = ModelType == 0 ? 1 : Coef_A   # function Coefficients(in_coef, ModelType)
    dvr, dvi = A.vr - B.vr, A.vi - B.vi
    d2 = dvr^2 + dvi^2
    eqs = Equation[
        Vabr ~ dvr / sqrt(3),
        Vabi ~ dvi / sqrt(3),
        Vab ~ sqrt(Vabr^2 + Vabi^2),
        Coef_A ~ A_ab / 100 + B_ab / 100 * Vab + C_ab / 100 * Vab^2,
        Pab ~ P_ab / S_p * Coef,
        Qab ~ Q_ab / S_p * Coef,
        A.ir ~ (Pab * dvr + Qab * dvi) / d2,
        A.ii ~ (Pab * dvi - Qab * dvr) / d2,
        B.ir ~ -(Pab * dvr + Qab * dvi) / d2,
        B.ii ~ -(Pab * dvi - Qab * dvr) / d2,
    ]
    var0, vai0 = n.VA * cos(n.AngA), n.VA * sin(n.AngA)
    vbr0, vbi0 = n.VB * cos(n.AngB), n.VB * sin(n.AngB)
    dr0, di0 = var0 - vbr0, vai0 - vbi0
    iar0 = (n.P_ab / n.S_p * dr0 + n.Q_ab / n.S_p * di0) / (dr0^2 + di0^2)
    iai0 = (n.P_ab / n.S_p * di0 - n.Q_ab / n.S_p * dr0) / (dr0^2 + di0^2)
    # A(vr(start = var0), vi(start = vai0), ir(start = iar0), ii(start = iai0)), B(..., ir(start = -iar0), ...)
    extend(System(eqs, t, vars, pars; name, systems,
        guesses = Dict(A.vr => var0, A.vi => vai0, A.ir => iar0, A.ii => iai0,
            B.vr => vbr0, B.vi => vbi0, B.ir => -iar0, B.ii => -iai0)), base)
end
