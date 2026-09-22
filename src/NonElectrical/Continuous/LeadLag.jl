# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Continuous/LeadLag.mo (block)
# Blocks: par1 = RealExpression(y = T1), par2 = RealExpression(y = T2), TF = Modelica.Blocks.Continuous.TransferFunction
# (b = {K*T1, K}, a = {T2_dummy, 1}, y_start, InitialOutput, x_start = {x_start}). Ports are plain variables (u, y).
# Omitted: graphical annotations.

# The `if` on the block's own time constant is a *parameter* expression: Modelica evaluates it at translation
# time and keeps one branch, so it is decided in Julia before `@parameters` (F-22, point 1). Written as an
# `ifelse` it survives into the compiled system, the output stops being an alias of the state, and a downstream
# block that differentiates its input (`SimpleLead` in `HYGOV`) drags ModelingToolkit's index reduction into a
# cascade of dummy derivatives that blows up (F-50). The `const`/`par1` sub-block stays: the OpenModelica CSVs
# carry its `y` column.
@component function LeadLag(; name, K, T1, T2, y_start, x_start = 0)
    K, T1, T2, y_start, x_start = float.((K, T1, T2, y_start, x_start))
    T2_dummy = abs(T1 - T2) < Modelica.Constants.eps ? 1000.0 : T2
    tf_b, tf_a, tf_x0 = [K * T1, K], [T2_dummy, 1.0], [x_start]   # numeric coefficients, before @parameters rebinds the names
    T1n, T2n = T1, T2
    pars = @parameters begin
        K = K, [description = "Gain"]
        T1 = T1, [description = "Lead time constant (s)"]
        T2 = T2, [description = "Lag time constant (s)"]
        y_start = y_start, [description = "Output start value"]
        x_start = x_start, [description = "Start value of state variable"]
        T2_dummy = T2_dummy, [description = "Lead time constant"]
    end
    systems = @named begin
        par1 = RealExpression(; expr = T1n)
        par2 = RealExpression(; expr = T2n)
        TF = TransferFunction(; b = tf_b, a = tf_a, y_start, initType = :InitialOutput, x_start = tf_x0)
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    eqs = Equation[
        y ~ (abs(T1n - T2n) < Modelica.Constants.eps ? K * u : TF.y),
        TF.u ~ u,   # connect(TF.u, u)
    ]
    System(eqs, t, vars, pars; name, systems)
end
