# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Loads/WyeDynLoad_3Ph.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Three-phase wye load whose per-phase powers are parameters and whose whole load is scaled by the `RealInput`
# `DynFact` (a load curve). Same ZIP shape as WyeLoad_3Ph, see its header and WyeLoad_1Ph's for the `ModelType`
# decision (F-50) and the current-explicit form of the pins (F-16); the difference is `DynFact` and the fact that
# the pin equations of this model carry NO `S_p` (`Pa = A.vr*A.ir + A.vi*A.ii`, already per unit), so `Pa` is
# `P_a/S_p*DynFact*Coef` where WyeLoad_3Ph has `P_a/S_p*Coef`.
# The protected matrices `TPhasePower`, `ZIP_coef`, `in_coef`, `Coef` and `Power` and the variables `Va2`, `Vb2`,
# `Vc2` are written inline. Both local functions branch on `ModelType` alone, a parameter, so the branch is taken
# in Julia (F-50): `Coefficients` gives [1, 1, 1] or `in_coef`, and `PowerDefinition` then either passes
# `TPhasePower` through or multiplies it by those coefficients - which is the same thing, because the coefficients
# are 1 in exactly the branch that does not multiply. Omitted: graphical annotations, the unused
# `import Modelica.Blocks.Interfaces.*`.

@component function WyeDynLoad_3Ph(; name, S_b = 100e6, fn = 50, ModelType = 0,
        P_a = 1e6, Q_a = 0, P_b = 1e6, Q_b = 0, P_c = 1e6, Q_c = 0,
        A_pa = 0, B_pa = 0, C_pa = 0, A_pb = 0, B_pb = 0, C_pb = 0, A_pc = 0, B_pc = 0, C_pc = 0)
    @named base = ThreePhaseComponent(; S_b)
    @unpack S_p = base
    P_a, Q_a, P_b, Q_b, P_c, Q_c = float.((P_a, Q_a, P_b, Q_b, P_c, Q_c))   # F-21
    A_pa, B_pa, C_pa, A_pb, B_pb, C_pb, A_pc, B_pc, C_pc =
        float.((A_pa, B_pa, C_pa, A_pb, B_pb, C_pb, A_pc, B_pc, C_pc))
    pars = @parameters begin
        P_a = P_a, [description = "Base active power for phase A (W)"]
        Q_a = Q_a, [description = "Base reactive power for phase A (var)"]
        P_b = P_b, [description = "Base active power for phase B (W)"]
        Q_b = Q_b, [description = "Base reactive power for phase B (var)"]
        P_c = P_c, [description = "Base active power for phase C (W)"]
        Q_c = Q_c, [description = "Base reactive power for phase C (var)"]
        A_pa = A_pa, [description = "Percentage of constant power load for phase A (%)"]
        B_pa = B_pa, [description = "Percentage of constant current load for phase A (%)"]
        C_pa = C_pa, [description = "Percentage of constant impedance load for phase A (%)"]
        A_pb = A_pb, [description = "Percentage of constant power load for phase B (%)"]
        B_pb = B_pb, [description = "Percentage of constant current load for phase B (%)"]
        C_pb = C_pb, [description = "Percentage of constant impedance load for phase B (%)"]
        A_pc = A_pc, [description = "Percentage of constant power load for phase C (%)"]
        B_pc = B_pc, [description = "Percentage of constant current load for phase C (%)"]
        C_pc = C_pc, [description = "Percentage of constant impedance load for phase C (%)"]
    end
    systems = @named begin
        A = PwPin()
        B = PwPin()
        C = PwPin()
    end
    vars = @variables begin
        DynFact(t), [description = "Load curve (pu)"]
        Va(t), [description = "Voltage magnitude at pin A (pu)"]
        Vb(t), [description = "Voltage magnitude at pin B (pu)"]
        Vc(t), [description = "Voltage magnitude at pin C (pu)"]
        Coef_A(t), [description = "ZIP coefficient for phase A"]
        Coef_B(t), [description = "ZIP coefficient for phase B"]
        Coef_C(t), [description = "ZIP coefficient for phase C"]
        Pa(t), [description = "Active power of phase A (pu)"]
        Pb(t), [description = "Active power of phase B (pu)"]
        Pc(t), [description = "Active power of phase C (pu)"]
        Qa(t), [description = "Reactive power of phase A (pu)"]
        Qb(t), [description = "Reactive power of phase B (pu)"]
        Qc(t), [description = "Reactive power of phase C (pu)"]
    end
    # function Coefficients(in_coef, ModelType): [1, 1, 1] or in_coef (F-50)
    CoefA, CoefB, CoefC = ModelType == 0 ? (1, 1, 1) : (Coef_A, Coef_B, Coef_C)
    eqs = Equation[
        Va ~ sqrt(A.vr^2 + A.vi^2),
        Vb ~ sqrt(B.vr^2 + B.vi^2),
        Vc ~ sqrt(C.vr^2 + C.vi^2),
        Coef_A ~ A_pa / 100 + B_pa / 100 * Va + C_pa / 100 * Va^2,
        Coef_B ~ A_pb / 100 + B_pb / 100 * Vb + C_pb / 100 * Vb^2,
        Coef_C ~ A_pc / 100 + B_pc / 100 * Vc + C_pc / 100 * Vc^2,
        Pa ~ P_a / S_p * DynFact * CoefA,
        Pb ~ P_b / S_p * DynFact * CoefB,
        Pc ~ P_c / S_p * DynFact * CoefC,
        Qa ~ Q_a / S_p * DynFact * CoefA,
        Qb ~ Q_b / S_p * DynFact * CoefB,
        Qc ~ Q_c / S_p * DynFact * CoefC,
        A.ir ~ (Pa * A.vr + Qa * A.vi) / (A.vr^2 + A.vi^2),   # Pa = A.vr*A.ir + A.vi*A.ii (F-16)
        A.ii ~ (Pa * A.vi - Qa * A.vr) / (A.vr^2 + A.vi^2),   # Qa = A.vi*A.ir - A.vr*A.ii
        B.ir ~ (Pb * B.vr + Qb * B.vi) / (B.vr^2 + B.vi^2),
        B.ii ~ (Pb * B.vi - Qb * B.vr) / (B.vr^2 + B.vi^2),
        C.ir ~ (Pc * C.vr + Qc * C.vi) / (C.vr^2 + C.vi^2),
        C.ii ~ (Pc * C.vi - Qc * C.vr) / (C.vr^2 + C.vi^2),
    ]
    extend(System(eqs, t, vars, pars; name, systems), base)
end
