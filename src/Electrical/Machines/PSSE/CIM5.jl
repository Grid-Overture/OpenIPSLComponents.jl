# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSSE/CIM5.mo (extends BaseClasses/baseMotor.mo)
# PSSE three-phase induction motor, single or double cage. `Mtype`, `R2`, `X2` and `Ctrl` decide in Julia which
# expression of `Lpp`, `Tp0`, `Tpp0` and the four `X*_c` is written (the .mo's `if` chains on parameters, F-22); `H`
# is declared in both classes with the same value, so it comes from the base. `SE` gets the numeric saturation
# coefficients and a symbolic argument. The 24 `EQ*` and the five `constant*` are literal algebraic variables that
# `mtkcompile` eliminates. The `initial equation if Sup == false ... else s = 1 - eps` is a Julia branch: without
# start-up the five `der(.) = 0` are `initialization_eqs`, with start-up only the slip is fixed and the four flux
# states are left to their `start` (0), which the Test supplies as OpenModelica does (F-28).
# A single-cage motor gives `Tpp0 = 1e-7 s`: one very stiff state, so it is integrated with Rodas5P.
# Omitted: graphical annotations, the commented-out P/Q alternatives of the .mo.

@component function CIM5(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b = 15e6, Sup = true, Ctrl = true, N = 1, H = 0.4, Mtype = 1, Ra = 0, Xa = 0.0759, Xm = 3.1241,
        R1 = 0.0085, X1 = 0.0759, R2 = 0, X2 = 0, E1 = 1, SE1 = 0.06, E2 = 1.2, SE2 = 0.6, T_nom = 1, D = 1)
    Ra, Xa, Xm, R1, X1, R2, X2, E1, SE1, E2, SE2, T_nom, D =
        float.((Ra, Xa, Xm, R1, X1, R2, X2, E1, SE1, E2, SE2, T_nom, D))   # F-21
    sat = (SE1, SE2, E1, E2)   # numeric saturation coefficients for SE inside the equations (F-22)
    single_cage = R2 == 0 && X2 == 0
    mtype = Mtype   # `@parameters` below rebinds Mtype to a symbol; the branch decisions are plain Julia (F-22)
    eps = Modelica.Constants.eps
    @named base = baseMotor(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b, Sup, Ctrl, N, H)
    @unpack we_fix, w_b, H, s, Ir, Ii, Vr, Vi, Te_motor, Te_sys, CoB = base
    pars = @parameters begin
        Mtype = Mtype, [description = "1- Motor Type A; 2- Motor Type B"]
        Ra = Ra, [description = "Stator resistance (pu)"]
        Xa = Xa, [description = "Stator reactance (pu)"]
        Xm = Xm, [description = "Magnetizing reactance (pu)"]
        R1 = R1, [description = "1st cage rotor resistance (pu)"]
        X1 = X1, [description = "1st cage rotor reactance (pu)"]
        R2 = R2, [description = "2nd cage rotor resistance (pu)"]
        X2 = X2, [description = "2nd cage rotor reactance (pu)"]
        E1 = E1, [description = "First Saturation Voltage Value (pu)"]
        SE1 = SE1, [description = "Saturation Factor at E1 (pu)"]
        E2 = E2, [description = "Second Saturation Voltage Value (pu)"]
        SE2 = SE2, [description = "Saturation Factor at E2 (pu)"]
        T_nom = T_nom, [description = "Load torque at 1 pu speed"]
        D = D, [description = "Load Damping Factor"]
    end
    vars = @variables begin
        TL(t), [description = "Load torque"]
        Epr(t), [description = "Real voltage behind transient reactance"]
        Epi(t), [description = "Imaginary voltage behind transient reactance"]
        Eppr(t), [description = "Real voltage behind sub-transient reactance"]
        Eppi(t), [description = "Imaginary voltage behind sub-transient reactance"]
        Epp(t), [description = "Voltage magnitude behind sub-transient reactance"]
        Ekr(t), [description = "Real voltage component related to 2nd cage for sub-transient reactance"]
        Eki(t), [description = "Imaginary voltage component related to 2nd cage for sub-transient reactance"]
        NUM(t), [description = "Numerator expression for determining EQC"]
        EQC(t), [description = "Intermediate step equation C"]
        EQ1(t)
        EQ2(t)
        EQ3(t)
        EQ4(t)
        EQ5(t)
        EQ6(t)
        EQ7(t)
        EQ8(t)
        EQ9(t)
        EQ10(t)
        EQ11(t)
        EQ12(t)
        EQ13(t)
        EQ14(t)
        EQ15(t)
        EQ16(t)
        EQ17(t)
        EQ18(t)
        EQ19(t)
        EQ20(t)
        EQ21(t)
        EQ22(t)
        EQ23(t)
        EQ24(t)
        Omegar(t), [description = "Rotor angular velocity"]
        Ls(t), [description = "Sum of stator and magnetization reactances"]
        Ll(t), [description = "Stator reactance"]
        Lp(t), [description = "Total reactance for stator and 1st cage rotor reactances"]
        Lpp(t), [description = "Total reactance for stator, 1st, and 2nd cage rotor reactances"]
        Xa_c(t), [description = "Variable stator reactance"]
        Xm_c(t), [description = "Variable magnetic impedance"]
        X1_c(t), [description = "Variable 1st cage rotor cage reactance"]
        X2_c(t), [description = "Variable 2nd cage rotor cage reactance"]
        constant1(t), [description = "Intermediate constant 1"]
        constant2(t), [description = "Intermediate constant 2"]
        constant3(t), [description = "Intermediate constant 3"]
        constant4(t), [description = "Intermediate constant 4"]
        constant5(t), [description = "Intermediate constant 5"]
        Tp0(t), [description = "Transient open-circuit time constant (s)"]
        Tpp0(t), [description = "Sub-transient open-circuit time constant (s)"]
    end
    ratio = Ctrl ? we_fix.y / w_b : 1   # the .mo writes `if Ctrl == false then X else (we_fix.y/w_b)*X` per reactance
    Lpp_eq = (mtype == 1 && single_cage) ? Lpp ~ Lp :
             mtype == 1 ? Lpp ~ Xa_c + X1_c * Xm_c * X2_c / (X1_c * X2_c + X1_c * Xm_c + X2_c * Xm_c) :
             (mtype == 2 && single_cage) ? Lpp ~ Lp :
             Lpp ~ Xa_c + (Xm_c * (X1_c + X2_c) / (X1_c + X2_c + Xm_c))
    Tp0_eq = mtype == 1 ? Tp0 ~ (X1_c + Xm_c) / (w_b * R1) :
             (mtype == 2 && single_cage) ? Tp0 ~ (X1_c + Xm_c) / (w_b * R1) :
             Tp0 ~ (X1_c + X2_c + Xm_c) / (w_b * R2)
    Tpp0_eq = (mtype == 1 && single_cage) ? Tpp0 ~ 1e-7 :
              mtype == 1 ? Tpp0 ~ (X2_c + (X1_c * Xm_c / (X1_c + Xm_c))) / (w_b * R2) :
              (mtype == 2 && single_cage) ? Tpp0 ~ 1e-7 :
              Tpp0 ~ (1 / ((1 / (X1_c + Xm_c) + 1 / X2_c))) / (w_b * R1)
    eqs = Equation[
        Xa_c ~ ratio * Xa,
        Xm_c ~ ratio * Xm,
        X1_c ~ ratio * X1,
        X2_c ~ ratio * X2,
        Ls ~ Xa_c + Xm_c,
        Ll ~ Xa_c,
        Lp ~ Xa_c + X1_c * Xm_c / (X1_c + Xm_c),
        Lpp_eq,
        Tp0_eq,
        Tpp0_eq,
        constant5 ~ Ls - Lp,
        constant3 ~ Lp - Ll,
        constant4 ~ (Lp - Lpp) / ((Lp - Ll)^2),
        constant2 ~ (Lp - Lpp) / (Lp - Ll),
        constant1 ~ (Lpp - Ll) / (Lp - Ll),
        Eppr ~ EQ1 + EQ2,
        EQ1 ~ Epr * constant1,
        EQ2 ~ Ekr * constant2,
        EQ3 ~ Tpp0 * der(Ekr),
        EQ3 ~ EQ4 + EQ5,
        EQ4 ~ (Tpp0 * w_b * s) * Eki,
        EQ5 ~ Epr - Ekr - EQ6,
        EQ6 ~ Ii * constant3,
        EQ7 ~ EQ5 * constant4,
        EQ8 ~ EQ7 + Ii,
        EQ9 ~ EQ8 * constant5,
        EQ10 ~ Eppi * EQC,
        EQ11 ~ Epi * (Tp0 * w_b * s),
        EQ12 ~ EQ10 + EQ11 - Epr - EQ9,
        EQ12 ~ Tp0 * der(Epr),
        EQC ~ NUM / (Epp + eps),
        NUM ~ SE(Epp, sat...),
        Epp ~ sqrt(Eppr^2 + Eppi^2),
        EQ13 ~ EQC * Eppr,
        EQ14 ~ Epr * (Tp0 * w_b * s),
        EQ22 ~ Ir - EQ21,
        EQ15 ~ EQ22 * constant5,
        EQ16 ~ EQ15 - EQ14 - EQ13 - Epi,
        EQ16 ~ Tp0 * der(Epi),
        EQ17 ~ Ir * constant3,
        EQ18 ~ EQ17 + Epi - Eki,
        EQ21 ~ EQ18 * constant4,
        EQ19 ~ Ekr * (Tpp0 * w_b * s),
        EQ20 ~ EQ18 - EQ19,
        EQ20 ~ Tpp0 * der(Eki),
        EQ24 ~ Epi * constant1,
        EQ23 ~ Eki * constant2,
        Eppi ~ EQ23 + EQ24,
        Vr ~ Eppr + Ra * Ir - Lpp * Ii,
        Vi ~ Eppi + Ra * Ii + Lpp * Ir,
        s ~ (1 - Omegar),
        der(s) ~ (TL - Te_motor) / (2 * H),
        Te_sys ~ Te_motor * CoB,
        Te_motor ~ Eppr * Ir + Eppi * Ii,
        TL ~ T_nom * (1 - s)^D,
    ]
    init_kw = Sup ? (; initial_conditions = Dict(s => 1 - eps)) :
              (; initialization_eqs = [der(s) ~ 0, der(Ekr) ~ 0, der(Eki) ~ 0, der(Epr) ~ 0, der(Epi) ~ 0])
    extend(System(eqs, t, vars, pars; name, init_kw...), base)
end
