# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Loads/DeltaDynLoad_3Ph.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Three-phase delta load whose branch powers are parameters and whose whole load is scaled by the `RealInput`
# `DynFact` (a load curve): the delta sibling of WyeDynLoad_3Ph and the dynamic sibling of DeltaLoad_3Ph. The
# `ModelType` branch of the local `function Coefficients` is taken in Julia (F-50); `PowerDefinition` has no branch
# at all here, it always multiplies by `Coef`, which is [1, 1, 1] for `ModelType = 0`. The protected matrices
# `TPhasePower`, `ZIP_coef`, `in_coef`, `Coef` and `Power` and the squares `Vab2`, `Vbc2`, `Vca2` are written
# inline. No F-16 deviation is needed: unlike the wye family this `.mo` already gives the pin currents explicitly,
# through the branch currents `Iabr`..`Icai`, which are kept as variables and with the `.mo`'s own division by
# sqrt(3) (`Vabr = (A.vr - B.vr)/sqrt(3)`, `A.ir = (Iabr - Icar)/sqrt(3)`) rather than folded as in
# DeltaLoad_3Ph.jl, whose `.mo` is folded already. Omitted: graphical annotations, the unused
# `import Modelica.Blocks.Interfaces.*`.
# Quirk reproduced (F-95, F-97): the `.mo` builds its power vector as
# `TPhasePower = [P_ab, P_bc, Pca, Q_ab, Q_bc, Q_ca]/S_p*DynFact` with **`Pca`**, its own output, where the
# parameter `P_ca` was meant. That closes `Pca = Pca/S_p*DynFact*CoefC` on itself, a linear equation whose only
# solution is `Pca = 0`, so branch CA never carries active power and `P_ca` is a dead parameter. Transcribed
# literally (rule 5); `mtkcompile` solves the scalar loop symbolically.

@component function DeltaDynLoad_3Ph(; name, S_b = 100e6, fn = 50, ModelType = 0,
        P_ab = 1e6, Q_ab = 0, P_bc = 1e6, Q_bc = 0, P_ca = 1e6, Q_ca = 0,
        A_ab = 0, B_ab = 0, C_ab = 0, A_bc = 0, B_bc = 0, C_bc = 0, A_ca = 0, B_ca = 0, C_ca = 0)
    @named base = ThreePhaseComponent(; S_b)
    @unpack S_p = base
    P_ab, Q_ab, P_bc, Q_bc, P_ca, Q_ca = float.((P_ab, Q_ab, P_bc, Q_bc, P_ca, Q_ca))   # F-21
    A_ab, B_ab, C_ab, A_bc, B_bc, C_bc, A_ca, B_ca, C_ca =
        float.((A_ab, B_ab, C_ab, A_bc, B_bc, C_bc, A_ca, B_ca, C_ca))
    pars = @parameters begin
        P_ab = P_ab, [description = "Active power for line AB (W)"]
        Q_ab = Q_ab, [description = "Reactive power for line AB (var)"]
        P_bc = P_bc, [description = "Active power for line BC (W)"]
        Q_bc = Q_bc, [description = "Reactive power for line BC (var)"]
        P_ca = P_ca, [description = "Active power for line CA (W; dead, see header)"]
        Q_ca = Q_ca, [description = "Reactive power for line CA (var)"]
        A_ab = A_ab, [description = "Percentage of constant power load for line AB (%)"]
        B_ab = B_ab, [description = "Percentage of constant current load for line AB (%)"]
        C_ab = C_ab, [description = "Percentage of constant impedance load for line AB (%)"]
        A_bc = A_bc, [description = "Percentage of constant power load for line BC (%)"]
        B_bc = B_bc, [description = "Percentage of constant current load for line BC (%)"]
        C_bc = C_bc, [description = "Percentage of constant impedance load for line BC (%)"]
        A_ca = A_ca, [description = "Percentage of constant power load for line CA (%)"]
        B_ca = B_ca, [description = "Percentage of constant current load for line CA (%)"]
        C_ca = C_ca, [description = "Percentage of constant impedance load for line CA (%)"]
    end
    systems = @named begin
        A = PwPin()
        B = PwPin()
        C = PwPin()
    end
    vars = @variables begin
        DynFact(t), [description = "Load curve (pu)"]
        Vabr(t), [description = "Real part of the line voltage AB (pu)"]
        Vabi(t), [description = "Imaginary part of the line voltage AB (pu)"]
        Vbcr(t), [description = "Real part of the line voltage BC (pu)"]
        Vbci(t), [description = "Imaginary part of the line voltage BC (pu)"]
        Vcar(t), [description = "Real part of the line voltage CA (pu)"]
        Vcai(t), [description = "Imaginary part of the line voltage CA (pu)"]
        Vab(t), [description = "Line voltage magnitude AB (pu)"]
        Vbc(t), [description = "Line voltage magnitude BC (pu)"]
        Vca(t), [description = "Line voltage magnitude CA (pu)"]
        Coef_A(t), [description = "ZIP coefficient for line AB"]
        Coef_B(t), [description = "ZIP coefficient for line BC"]
        Coef_C(t), [description = "ZIP coefficient for line CA"]
        Pab(t), [description = "Active power of line AB (pu)"]
        Pbc(t), [description = "Active power of line BC (pu)"]
        Pca(t), [description = "Active power of line CA (pu; 0, see header)"]
        Qab(t), [description = "Reactive power of line AB (pu)"]
        Qbc(t), [description = "Reactive power of line BC (pu)"]
        Qca(t), [description = "Reactive power of line CA (pu)"]
        Iabr(t), [description = "Real part of the branch current AB (pu)"]
        Iabi(t), [description = "Imaginary part of the branch current AB (pu)"]
        Ibcr(t), [description = "Real part of the branch current BC (pu)"]
        Ibci(t), [description = "Imaginary part of the branch current BC (pu)"]
        Icar(t), [description = "Real part of the branch current CA (pu)"]
        Icai(t), [description = "Imaginary part of the branch current CA (pu)"]
    end
    # function Coefficients(in_coef, ModelType): [1, 1, 1] or in_coef (F-50)
    CoefA, CoefB, CoefC = ModelType == 0 ? (1, 1, 1) : (Coef_A, Coef_B, Coef_C)
    eqs = Equation[
        Vabr ~ (A.vr - B.vr) / sqrt(3),
        Vabi ~ (A.vi - B.vi) / sqrt(3),
        Vbcr ~ (B.vr - C.vr) / sqrt(3),
        Vbci ~ (B.vi - C.vi) / sqrt(3),
        Vcar ~ (C.vr - A.vr) / sqrt(3),
        Vcai ~ (C.vi - A.vi) / sqrt(3),
        Vab ~ sqrt(Vabr^2 + Vabi^2),
        Vbc ~ sqrt(Vbcr^2 + Vbci^2),
        Vca ~ sqrt(Vcar^2 + Vcai^2),
        Coef_A ~ A_ab / 100 + B_ab / 100 * Vab + C_ab / 100 * Vab^2,
        Coef_B ~ A_bc / 100 + B_bc / 100 * Vbc + C_bc / 100 * Vbc^2,
        Coef_C ~ A_ca / 100 + B_ca / 100 * Vca + C_ca / 100 * Vca^2,
        Pab ~ P_ab / S_p * DynFact * CoefA,
        Pbc ~ P_bc / S_p * DynFact * CoefB,
        Pca ~ Pca / S_p * DynFact * CoefC,   # `Pca`, not `P_ca`: the dead branch of the .mo (see header)
        Qab ~ Q_ab / S_p * DynFact * CoefA,
        Qbc ~ Q_bc / S_p * DynFact * CoefB,
        Qca ~ Q_ca / S_p * DynFact * CoefC,
        Iabr ~ (Pab * Vabr + Qab * Vabi) / Vab^2,
        Iabi ~ (Pab * Vabi - Qab * Vabr) / Vab^2,
        Ibcr ~ (Pbc * Vbcr + Qbc * Vbci) / Vbc^2,
        Ibci ~ (Pbc * Vbci - Qbc * Vbcr) / Vbc^2,
        Icar ~ (Pca * Vcar + Qca * Vcai) / Vca^2,
        Icai ~ (Pca * Vcai - Qca * Vcar) / Vca^2,
        A.ir ~ (Iabr - Icar) / sqrt(3),
        A.ii ~ (Iabi - Icai) / sqrt(3),
        B.ir ~ (Ibcr - Iabr) / sqrt(3),
        B.ii ~ (Ibci - Iabi) / sqrt(3),
        C.ir ~ (Icar - Ibcr) / sqrt(3),
        C.ii ~ (Icai - Ibci) / sqrt(3),
    ]
    extend(System(eqs, t, vars, pars; name, systems), base)
end
