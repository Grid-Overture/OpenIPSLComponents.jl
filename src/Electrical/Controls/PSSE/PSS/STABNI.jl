# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/PSS/STABNI.mo (extends nothing: its ports are its own), blocks as
# subsystems:
#   limiter                       Modelica.Blocks.Nonlinear.Limiter (uMax = LIMIT, uMin = -LIMIT)
#   imSimpleLag                   OpenIPSL.NonElectrical.Continuous.SimpleLag (K = K, T = T_2, y_start = K*PELEC0)
#   imLeadLag                     OpenIPSL.NonElectrical.Continuous.LeadLag (K = 1, T1 = T_1, T2 = T_0, y_start = 0)
#   imDerivativeLag/imDerivativeLag1  Modelica.Blocks.Continuous.Derivative (T = T_0, k = T_0, y_start = 0,
#                                                                            InitialOutput), in cascade
#   imSimpleLag1                  OpenIPSL.NonElectrical.Continuous.SimpleLag (K = 1, T = T_0, y_start = 0)
#   gain                          Modelica.Blocks.Math.Gain (k = -1)
# Ports as plain variables: PELEC (input) and VOTHSG (output).
# `PELEC0 = PELEC` reads an *input*, so it is declared with a guess, listed as `missing` and given its equation in
# `initialization_eqs` (F-33).
# Omitted: graphical annotations.

@component function STABNI(; name, K = 1, T_1 = 1, T_2 = 1, T_0 = 1, LIMIT = 5)
    K, T_1, T_2, T_0, LIMIT = float.((K, T_1, T_2, T_0, LIMIT))
    n = (; K, T_1, T_2, T_0, LIMIT)
    pars = @parameters begin
        K = K, [description = "Input low-pass filter gain. It must be equal to or greater than 0"]
        T_1 = T_1, [description = "Stabilizer filter time constant. It must be greater than 0"]
        T_2 = T_2, [description = "Input low-pass filter time constant. It must be equal to or greater than 0"]
        T_0 = T_0, [description = "Stabilizer filter time constant. It must be greater than 0"]
        LIMIT = LIMIT, [description = "Limit value for stabilizer output"]
        PELEC0, [guess = 0.0]
    end
    systems = @named begin
        limiter = Limiter(; uMax = n.LIMIT, uMin = -n.LIMIT)
        imSimpleLag = SimpleLag(; K = n.K, T = n.T_2, y_start = K * PELEC0)
        imLeadLag = LeadLag(; K = 1, T1 = n.T_1, T2 = n.T_0, y_start = 0)
        imDerivativeLag = Derivative(; T = n.T_0, k = n.T_0, y_start = 0, initType = :InitialOutput)
        imDerivativeLag1 = Derivative(; T = n.T_0, k = n.T_0, y_start = 0, initType = :InitialOutput)
        imSimpleLag1 = SimpleLag(; K = 1, T = n.T_0, y_start = 0)
        gain = Gain(; k = -1)
    end
    vars = @variables begin
        PELEC(t), [guess = 0.0]
        VOTHSG(t), [guess = 0.0]
    end
    eqs = Equation[
        VOTHSG ~ gain.y,                            # connect(VOTHSG, gain.y)
        imSimpleLag.u ~ PELEC,                      # connect(PELEC, imSimpleLag.u)
        imDerivativeLag.u ~ imSimpleLag.y,          # connect(imSimpleLag.y, imDerivativeLag.u)
        imDerivativeLag1.u ~ imDerivativeLag.y,     # connect(imDerivativeLag.y, imDerivativeLag1.u)
        imLeadLag.u ~ imDerivativeLag1.y,           # connect(imDerivativeLag1.y, imLeadLag.u)
        imSimpleLag1.u ~ imLeadLag.y,               # connect(imLeadLag.y, imSimpleLag1.u)
        gain.u ~ limiter.y,                         # connect(limiter.y, gain.u)
        limiter.u ~ imSimpleLag1.y,                 # connect(limiter.u, imSimpleLag1.y)
    ]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = [PELEC0 ~ PELEC],
        initial_conditions = Dict(PELEC0 => missing))
end
