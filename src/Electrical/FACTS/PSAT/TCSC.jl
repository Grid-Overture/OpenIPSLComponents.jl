# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/FACTS/PSAT/TCSC.mo (extends Electrical/Essentials/pfComponent.mo), blocks as
# subsystems:
#   Pkm           Modelica.Blocks.Sources.RealExpression (y = pkm)   written in the parent (F-22, point 2)
#   Pref          Modelica.Blocks.Sources.RealExpression (y = pref)  a number, so it goes in the block
#   powerDiff     Modelica.Blocks.Math.Feedback                      Pkm.y - Pref.y
#   PIcontroller  Modelica.Blocks.Continuous.TransferFunction (b = {Kp, Ki}, a = {1, 0}, InitialOutput,
#                                                              y_start = -x10)
#   stabilizer    Modelica.Blocks.Math.Gain (k = Kr) over Vs_pod
#   feedback      Modelica.Blocks.Math.Feedback                      stabilizer.y - PIcontroller.y
#   X1            OpenIPSL.NonElectrical.Continuous.SimpleLagLim (K = 1, T = Tr, y_start = x10,
#                                                                 outMax = x1_max, outMin = x1_min)   -> x1
# `a = {1, 0}` has `a[end] = 0`, which TransferFunction.jl already handles (a_end falls back to 1, so
# `y = Ki*x + Kp*u`).
# `OpenIPSL.Types.Ctrl` is a keyword argument `ctrl::Symbol` (`:alpha` or `:xTCSC`). `alphaCtrl`, `xL`, `xC`, `X`,
# `y`, `kx`, `x1_min`, `x1_max`, `x10` and **the branch of `b`** are decided in Julia: the `if` is on a parameter
# expression, which Modelica evaluates at translation time (F-50), so only the selected branch is written.
# The four branch equations already have the pin currents explicit and are copied with their signs (sic: the .mo
# mixes `n.ii` with `n.vr`/`n.vi` and `n.ir` with `n.vi`/`n.vr`).
# `Modelica.Constants.pi` is Julia's `pi`. The RealInput Vs_pod is a plain variable.
# Omitted: graphical annotations, displayPF, the commented-out `Cp`/`XL2` power-flow parameters.

@component function TCSC(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        pref = 0.080101913348342, Sn = S_b, Vn = V_b, ctrl::Symbol = :alpha, alpha_min = 0.7, alpha_max = 0.85,
        xTCSC_min = -0.05, xTCSC_max = 0.05, Tr = 0.5, Kp = 5, Ki = 1, Kr = 10, x_L = 0.2, x_C = 0.1, XL = 0.1,
        G = 0, B = 0, alpha0 = 0.8, xTCSC0 = 0)
    S_b, V_b, fn, pref, Sn, Vn, alpha_min, alpha_max, xTCSC_min, xTCSC_max, Tr, Kp, Ki, Kr, x_L, x_C, XL, G, B,
    alpha0, xTCSC0 =
        float.((S_b, V_b, fn, pref, Sn, Vn, alpha_min, alpha_max, xTCSC_min, xTCSC_max, Tr, Kp, Ki, Kr, x_L, x_C,
            XL, G, B, alpha0, xTCSC0))   # F-21
    alphaCtrl = ctrl === :alpha
    xL = x_L * (Vn^2 / Sn) * (S_b / V_b^2)
    xC = x_C * (Vn^2 / Sn) * (S_b / V_b^2)
    X = XL * (Vn^2 / Sn) * (S_b / V_b^2)
    yn = 1 / X
    kx = sqrt(xC / xL)
    x1_min = alphaCtrl ? alpha_min : xTCSC_min
    x1_max = alphaCtrl ? alpha_max : xTCSC_max
    x10 = alphaCtrl ? alpha0 : xTCSC0
    tf_b, tf_a = [Kp, Ki], [1.0, 0.0]
    Trn = Tr   # SimpleLagLim decides its degenerate branch in Julia from the numeric T (F-22, point 1)
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    pars = @parameters begin
        pref = pref, [description = "Reference power (pu)"]
        Sn = Sn, [description = "Power rating (VA)"]
        Vn = Vn, [description = "Voltage rating (V)"]
        alpha_min = alpha_min, [description = "Minimum firing angle (rad)"]
        alpha_max = alpha_max, [description = "Maximum firing angle (rad)"]
        xTCSC_min = xTCSC_min, [description = "Minimum reactance (pu)"]
        xTCSC_max = xTCSC_max, [description = "Maximum reactance (pu)"]
        Tr = Tr, [description = "Regulator time constant (s)"]
        Kp = Kp, [description = "Proportional gain of PI controller (pu/pu)"]
        Ki = Ki, [description = "Integral gain of PI controller (pu/pu)"]
        Kr = Kr, [description = "Gain of stabilizing signal (pu/pu)"]
        x_L = x_L, [description = "Reactance (inductive, pu)"]
        x_C = x_C, [description = "Reactance (capacitive, pu)"]
        XL = XL, [description = "Line reactance (pu)"]
        G = G, [description = "Shunt half conductance (pu)"]
        B = B, [description = "Shunt half susceptance (pu)"]
        alpha0 = alpha0, [description = "Initial firing angle (rad)"]
        xTCSC0 = xTCSC0, [description = "Initial reactance (pu)"]
        xL = xL, [description = "Reactance (inductive, pu)"]
        xC = xC, [description = "Reactance (capacitive, pu)"]
        X = X, [description = "Line Reactance (pu)"]
        yn = yn, [description = "Line admittance (pu); `y` in the .mo"]
        kx = kx, [description = "sqrt(xC/xL)"]
        x1_min = x1_min
        x1_max = x1_max
        x10 = x10
    end
    systems = @named begin
        p = PwPin()
        n = PwPin()
        powerDiff = Feedback()
        PIcontroller = TransferFunction(; b = tf_b, a = tf_a, initType = :InitialOutput, y_start = -x10)
        feedback = Feedback()
        stabilizer = Gain(; k = Kr)
        X1 = SimpleLagLim(; K = 1, T = Trn, y_start = x10, outMax = x1_max, outMin = x1_min)
        Pref = RealExpression(; expr = pref)
        Pkm = RealExpression(; expr = nothing)   # y = pkm: written in the parent
    end
    vars = @variables begin
        vk(t), [description = "Bus voltage of bus k (pu)"]
        vm(t), [description = "Bus voltage of bus m (pu)"]
        pkm(t), [description = "Active power flow from bus k to m (pu)"]
        b(t), [description = "TCSC series susceptance (pu)"]
        x1(t), [description = "State representing alpha or xTCSC"]
        Vs_pod(t)
    end
    # b = if alphaCtrl then <trigonometric in x1> else -x1/X/(X*(1 - x1/X)); a parameter condition, decided here
    b_eq = alphaCtrl ?
           b ~ pi * (kx^4 - 2 * kx^2 + 1) * cos(kx * (pi - x1)) /
               (xC * (pi * kx^4 * cos(kx * (pi - x1))
                      - pi * cos(kx * (pi - x1))
                      - 2 * kx^4 * x1 * cos(kx * (pi - x1))
                      + 2 * x1 * kx^2 * cos(kx * (pi - x1))
                      - kx^4 * sin(2 * x1) * cos(kx * (pi - x1))
                      + kx^2 * sin(2 * x1) * cos(kx * (pi - x1))
                      - 4 * kx^3 * cos(x1)^2 * sin(kx * (pi - x1))
                      - 4 * kx^2 * cos(x1) * sin(x1) * cos(kx * (pi - x1)))) :
           b ~ -x1 / X / (X * (1 - x1 / X))
    eqs = Equation[
        vk ~ sqrt(p.vr^2 + p.vi^2),
        vm ~ sqrt(n.vr^2 + n.vi^2),
        pkm ~ p.vr * p.ir + p.vi * p.ii,
        x1 ~ X1.y,
        b_eq,
        n.ii - B * n.vr - G * n.vi ~ (yn + b) * (p.vr - n.vr),
        n.ir - G * n.vr + B * n.vi ~ (yn + b) * (n.vi - p.vi),
        p.ii - B * p.vr - G * p.vi ~ (yn + b) * (n.vr - p.vr),
        p.ir - G * p.vr + B * p.vi ~ (yn + b) * (p.vi - n.vi),
        feedback.u2 ~ PIcontroller.y,   # connect(PIcontroller.y, feedback.u2)
        PIcontroller.u ~ powerDiff.y,   # connect(powerDiff.y, PIcontroller.u)
        powerDiff.u1 ~ Pkm.y,           # connect(Pkm.y, powerDiff.u1)
        powerDiff.u2 ~ Pref.y,          # connect(Pref.y, powerDiff.u2)
        X1.u ~ feedback.y,              # connect(feedback.y, X1.u)
        feedback.u1 ~ stabilizer.y,     # connect(stabilizer.y, feedback.u1)
        stabilizer.u ~ Vs_pod,          # connect(Vs_pod, stabilizer.u)
        Pkm.y ~ pkm,                    # RealExpression Pkm(y = pkm)
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            guesses = Dict(vk => 1.0, vm => 1.0, pkm => pref, x1 => x10, Vs_pod => 0.0)), base)
end
