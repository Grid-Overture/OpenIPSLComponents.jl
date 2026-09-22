# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/PSS/STAB3.mo (extends nothing: its ports are its own), blocks as
# subsystems:
#   limiter          Modelica.Blocks.Nonlinear.Limiter (uMax = V_LIM, uMin = -V_LIM)
#   const_           Modelica.Blocks.Sources.Constant (k = P_REF; the .mo instance is `const`, a Julia keyword)
#   imSimpleLag      OpenIPSL.NonElectrical.Continuous.SimpleLag (K = 1, T = T_t, y_start = PELEC0)
#   feedback         Modelica.Blocks.Math.Feedback
#   imSimpleLag1     OpenIPSL.NonElectrical.Continuous.SimpleLag (K = 1, T = T_X1, y_start = 0)
#   imDerivativeLag  Modelica.Blocks.Continuous.Derivative (y_start = 0, k = -K_X, T = T_X2, InitialOutput)
# Ports as plain variables: PELEC (input) and VOTHSG (output).
# `PELEC0 = PELEC` reads an *input* and `P_REF = PELEC0` chains to it, so both are declared with a guess, listed
# as `missing` and given their equations in `initialization_eqs` (F-33). The `Constant` gets the symbol `P_REF`
# as its `k`, which is the one case where a child may take a parent symbol: it is a parameter default, not an
# equation (rule 6.1).
# Note the .mo declares `T_X1`, `T_X2` and `K_X` as `Types.Time` including `K_X`, which is a gain (sic).
# Omitted: graphical annotations.

@component function STAB3(; name, T_t = 1, T_X1 = 1, T_X2 = 1, K_X = 1, V_LIM = 5)
    T_t, T_X1, T_X2, K_X, V_LIM = float.((T_t, T_X1, T_X2, K_X, V_LIM))
    n = (; T_t, T_X1, T_X2, K_X, V_LIM)
    pars = @parameters begin
        T_t = T_t, [description = "Input transducer time constant"]
        T_X1 = T_X1, [description = "Low-pass filter time constant. Value must be greater than 0"]
        T_X2 = T_X2, [description = "Stabilizer washout denominator time constant. Value must be greater than 0"]
        K_X = K_X, [description = "Stabilizer washout numerator time constant"]
        V_LIM = V_LIM, [description = "Limit value for stabilizer output"]
        P_REF, [guess = 0.0]
        PELEC0, [guess = 0.0]
    end
    systems = @named begin
        limiter = Limiter(; uMax = n.V_LIM, uMin = -n.V_LIM)
        const_ = Constant(; k = P_REF)
        imSimpleLag = SimpleLag(; K = 1, T = n.T_t, y_start = PELEC0)
        feedback = Feedback()
        imSimpleLag1 = SimpleLag(; K = 1, T = n.T_X1, y_start = 0)
        imDerivativeLag = Derivative(; y_start = 0, k = -n.K_X, T = n.T_X2, initType = :InitialOutput)
    end
    vars = @variables begin
        PELEC(t), [guess = 0.0, description = "Machine electrical power [pu]"]
        VOTHSG(t), [guess = 0.0, description = "PSS output signal"]
    end
    eqs = Equation[
        imDerivativeLag.u ~ imSimpleLag1.y,   # connect(imSimpleLag1.y, imDerivativeLag.u)
        feedback.u1 ~ imSimpleLag.y,          # connect(imSimpleLag.y, feedback.u1)
        imSimpleLag.u ~ PELEC,                # connect(imSimpleLag.u, PELEC)
        imSimpleLag1.u ~ feedback.y,          # connect(feedback.y, imSimpleLag1.u)
        limiter.u ~ imDerivativeLag.y,        # connect(imDerivativeLag.y, limiter.u)
        VOTHSG ~ limiter.y,                   # connect(limiter.y, VOTHSG)
        feedback.u2 ~ const_.y,               # connect(const.y, feedback.u2)
    ]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = [PELEC0 ~ PELEC, P_REF ~ PELEC0],
        initial_conditions = Dict(PELEC0 => missing, P_REF => missing))
end
