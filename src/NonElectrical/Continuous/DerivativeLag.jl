# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/DerivativeLag.mo (block)
# Blocks: par1 = RealExpression(y = T), TF = TransferFunction(InitialOutput, x_start = {x_start}, b = {K_dummy, 0},
# y_start, a = {T_dummy, 1}). Ports are plain variables (u, y). Omitted: graphical annotations.

# The `if` on the block's own time constant is a *parameter* expression: Modelica evaluates it at translation
# time and keeps one branch, so it is decided in Julia before `@parameters` (F-22, point 1). Written as an
# `ifelse` it survives into the compiled system, the output stops being an alias of the state, and a downstream
# block that differentiates its input (`SimpleLead` in `HYGOV`) drags ModelingToolkit's index reduction into a
# cascade of dummy derivatives that blows up (F-50). The `const`/`par1` sub-block stays: the OpenModelica CSVs
# carry its `y` column.
@component function DerivativeLag(; name, K, T, y_start, x_start = 0)
    K, T, y_start, x_start = float.((K, T, y_start, x_start))
    T_dummy = abs(T) < Modelica.Constants.eps ? 1000.0 : T
    K_dummy = abs(K) < Modelica.Constants.eps ? 1.0 : K
    tf_b, tf_a, tf_x0 = [K_dummy, 0.0], [T_dummy, 1.0], [x_start]   # numeric coefficients, before @parameters rebinds the names
    Tn = T
    pars = @parameters begin
        K = K, [description = "Gain"]
        T = T, [description = "Time constant (s)"]
        y_start = y_start, [description = "Output start value"]
        x_start = x_start, [description = "Start value of state variable"]
        T_dummy = T_dummy
        K_dummy = K_dummy
    end
    systems = @named begin
        par1 = RealExpression(; expr = Tn)
        TF = TransferFunction(; initType = :InitialOutput, x_start = tf_x0, b = tf_b, y_start, a = tf_a)
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    eqs = Equation[
        y ~ (abs(Tn) < Modelica.Constants.eps ? u : TF.y),
        TF.u ~ u,   # connect(TF.u, u)
    ]
    System(eqs, t, vars, pars; name, systems)
end
