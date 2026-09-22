# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Loads/DeltaLoad_3Ph.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Three-phase delta load; same shape as DeltaLoad_2Ph, see its header. The local `function Voltages` and the
# matrices `Vline`, `Volt` are written inline (`Vab`, `Vbc`, `Vca` and their squares).
# Omitted: graphical annotations, the unused `import Modelica.Constants.pi`.

@component function DeltaLoad_3Ph(; name, S_b = 100e6, fn = 50, ModelType = 0,
        VA = 1, AngA = 0, VB = 1, AngB = -2pi / 3, VC = 1, AngC = 2pi / 3,
        P_ab = 1e6, Q_ab = 0, P_bc = 1e6, Q_bc = 0, P_ca = 1e6, Q_ca = 0,
        A_ab = 0, B_ab = 0, C_ab = 0, A_bc = 0, B_bc = 0, C_bc = 0, A_ca = 0, B_ca = 0, C_ca = 0)
    @named base = ThreePhaseComponent(; S_b)
    @unpack S_p = base
    VA, AngA, VB, AngB, VC, AngC = float.((VA, AngA, VB, AngB, VC, AngC))   # F-21
    P_ab, Q_ab, P_bc, Q_bc, P_ca, Q_ca = float.((P_ab, Q_ab, P_bc, Q_bc, P_ca, Q_ca))
    A_ab, B_ab, C_ab, A_bc, B_bc, C_bc, A_ca, B_ca, C_ca =
        float.((A_ab, B_ab, C_ab, A_bc, B_bc, C_bc, A_ca, B_ca, C_ca))
    n = (; VA, AngA, VB, AngB, VC, AngC)
    pars = @parameters begin
        VA = VA, [description = "Voltage magnitude for phase A (pu)"]
        AngA = AngA, [description = "Voltage angle for phase A (rad)"]
        VB = VB, [description = "Voltage magnitude for phase B (pu)"]
        AngB = AngB, [description = "Voltage angle for phase B (rad)"]
        VC = VC, [description = "Voltage magnitude for phase C (pu)"]
        AngC = AngC, [description = "Voltage angle for phase C (rad)"]
        P_ab = P_ab, [description = "Initial active power (W)"]
        Q_ab = Q_ab, [description = "Initial reactive power (var)"]
        P_bc = P_bc, [description = "Initial active power (W)"]
        Q_bc = Q_bc, [description = "Initial reactive power (var)"]
        P_ca = P_ca, [description = "Initial active power (W)"]
        Q_ca = Q_ca, [description = "Initial reactive power (var)"]
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
        Pca(t), [description = "Active power of line CA (pu)"]
        Qab(t), [description = "Reactive power of line AB (pu)"]
        Qbc(t), [description = "Reactive power of line BC (pu)"]
        Qca(t), [description = "Reactive power of line CA (pu)"]
    end
    # function Coefficients(in_coef, ModelType): [1, 1, 1] or in_coef (F-50)
    CoefA, CoefB, CoefC = ModelType == 0 ? (1, 1, 1) : (Coef_A, Coef_B, Coef_C)
    abr, abi = A.vr - B.vr, A.vi - B.vi
    bcr, bci = B.vr - C.vr, B.vi - C.vi
    car, cai = C.vr - A.vr, C.vi - A.vi
    ab2, bc2, ca2 = abr^2 + abi^2, bcr^2 + bci^2, car^2 + cai^2
    eqs = Equation[
        Vabr ~ abr / sqrt(3),
        Vabi ~ abi / sqrt(3),
        Vbcr ~ bcr / sqrt(3),
        Vbci ~ bci / sqrt(3),
        Vcar ~ car / sqrt(3),
        Vcai ~ cai / sqrt(3),
        Vab ~ sqrt(Vabr^2 + Vabi^2),
        Vbc ~ sqrt(Vbcr^2 + Vbci^2),
        Vca ~ sqrt(Vcar^2 + Vcai^2),
        Coef_A ~ A_ab / 100 + B_ab / 100 * Vab + C_ab / 100 * Vab^2,
        Coef_B ~ A_bc / 100 + B_bc / 100 * Vbc + C_bc / 100 * Vbc^2,
        Coef_C ~ A_ca / 100 + B_ca / 100 * Vca + C_ca / 100 * Vca^2,
        Pab ~ P_ab / S_p * CoefA,
        Pbc ~ P_bc / S_p * CoefB,
        Pca ~ P_ca / S_p * CoefC,
        Qab ~ Q_ab / S_p * CoefA,
        Qbc ~ Q_bc / S_p * CoefB,
        Qca ~ Q_ca / S_p * CoefC,
        A.ir ~ (Pab * abr + Qab * abi) / ab2 - (Pca * car + Qca * cai) / ca2,
        A.ii ~ (Pab * abi - Qab * abr) / ab2 - (Pca * cai - Qca * car) / ca2,
        B.ir ~ (Pbc * bcr + Qbc * bci) / bc2 - (Pab * abr + Qab * abi) / ab2,
        B.ii ~ (Pbc * bci - Qbc * bcr) / bc2 - (Pab * abi - Qab * abr) / ab2,
        C.ir ~ (Pca * car + Qca * cai) / ca2 - (Pbc * bcr + Qbc * bci) / bc2,
        C.ii ~ (Pca * cai - Qca * car) / ca2 - (Pbc * bci - Qbc * bcr) / bc2,
    ]
    # A(vr(start = var0), vi(start = vai0)), B(...), C(...)
    extend(System(eqs, t, vars, pars; name, systems,
        guesses = Dict(A.vr => n.VA * cos(n.AngA), A.vi => n.VA * sin(n.AngA),
            B.vr => n.VB * cos(n.AngB), B.vi => n.VB * sin(n.AngB),
            C.vr => n.VC * cos(n.AngC), C.vi => n.VC * sin(n.AngC))), base)
end
