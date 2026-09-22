# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Loads/WyeLoad_1Ph.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Single-phase wye load over the phase base S_p, powers in W/var. Omitted: graphical annotations. The protected
# matrices `TPhasePower` and `ZIP_coef` and the variable `Va2` are written inline; the local `function Coefficients`
# is an `if` on the parameter `ModelType`, decided in Julia as OpenModelica decides it at translation time (F-50).
# Deviation, Julia only (F-16): the bilinear definitions  Pa = A.vr*A.ir + A.vi*A.ii  and  Qa = A.vi*A.ir - A.vr*A.ii
# are written solved for the currents, A.ir = (Pa*vr + Qa*vi)/v^2 and A.ii = (Pa*vi - Qa*vr)/v^2 - identical for
# v != 0 and without the v = 0 branch ModelingToolkit tearing falls into; it is the same formula the .mo itself
# uses for the start values iar0, iai0.

@component function WyeLoad_1Ph(; name, S_b = 100e6, fn = 50, ModelType = 0, VA = 1, AngA = 0, P_a = 1e6, Q_a = 0,
        A_pa = 0, B_pa = 0, C_pa = 0)
    @named base = ThreePhaseComponent(; S_b)
    @unpack S_p = base
    VA, AngA, P_a, Q_a, A_pa, B_pa, C_pa = float.((VA, AngA, P_a, Q_a, A_pa, B_pa, C_pa))   # F-21
    n = (; VA, AngA, P_a, Q_a, S_p = float(S_b) / 3)
    pars = @parameters begin
        VA = VA, [description = "Voltage magnitude (pu)"]
        AngA = AngA, [description = "Voltage angle for phase A (rad)"]
        P_a = P_a, [description = "Initial active power (W)"]
        Q_a = Q_a, [description = "Initial reactive power (var)"]
        A_pa = A_pa, [description = "Percentage of constant power load for phase A (%)"]
        B_pa = B_pa, [description = "Percentage of constant current load for phase A (%)"]
        C_pa = C_pa, [description = "Percentage of constant impedance load for phase A (%)"]
    end
    systems = @named begin
        A = PwPin()
    end
    vars = @variables begin
        Va(t), [description = "Voltage magnitude at the pin (pu)"]
        Coef_A(t), [description = "ZIP coefficient for phase A"]
        Pa(t), [description = "Active power of phase A (pu)"]
        Qa(t), [description = "Reactive power of phase A (pu)"]
    end
    Coef = ModelType == 0 ? 1 : Coef_A   # function Coefficients(Coef_A, ModelType)
    eqs = Equation[
        Va ~ sqrt(A.vr^2 + A.vi^2),
        Coef_A ~ A_pa / 100 + B_pa / 100 * Va + C_pa / 100 * Va^2,
        Pa ~ P_a / S_p * Coef,
        Qa ~ Q_a / S_p * Coef,
        A.ir ~ (Pa * A.vr + Qa * A.vi) / (A.vr^2 + A.vi^2),   # Pa = A.vr*A.ir + A.vi*A.ii (see header)
        A.ii ~ (Pa * A.vi - Qa * A.vr) / (A.vr^2 + A.vi^2),   # Qa = A.vi*A.ir - A.vr*A.ii
    ]
    var0, vai0 = n.VA * cos(n.AngA), n.VA * sin(n.AngA)
    iar0 = (n.P_a / n.S_p * var0 + n.Q_a / n.S_p * vai0) / (var0^2 + vai0^2)
    iai0 = (n.P_a / n.S_p * vai0 - n.Q_a / n.S_p * var0) / (var0^2 + vai0^2)
    # A(vr(start = var0), vi(start = vai0), ir(start = iar0), ii(start = iai0))
    extend(System(eqs, t, vars, pars; name, systems,
        guesses = Dict(A.vr => var0, A.vi => vai0, A.ir => iar0, A.ii => iai0)), base)
end
