# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/PSS/STBSVC.mo
# extends: BaseClasses.BasePSS (V_S1, V_S2, VOTHSG). Blocks as subsystems:
#   imSimpleLag     OpenIPSL.NonElectrical.Continuous.SimpleLag (K = K_S1, T = T_S7, y_start = V_S10)
#   imSimpleLag1    OpenIPSL.NonElectrical.Continuous.SimpleLag (K = K_S2, T = T_S10, y_start = V_S10)  <- sic
#   imLeadLag       OpenIPSL.NonElectrical.Continuous.LeadLag (K = 1, T1 = T_S8, T2 = T_S9, y_start = V_S10)
#   imLeadLag1      OpenIPSL.NonElectrical.Continuous.LeadLag (K = 1, T1 = T_S11, T2 = T_S12, y_start = V_S20)
#   add             Modelica.Blocks.Math.Add
#   imDerivativeLag Modelica.Blocks.Continuous.Derivative (k = T_S13, T = T_S14, y_start = 0, InitialOutput)
#   gain            Modelica.Blocks.Math.Gain (k = K_S3)
#   limiter         Modelica.Blocks.Nonlinear.Limiter (uMax = V_SCS, uMin = -V_SCS)
# `V_S10 = V_S1` and `V_S20 = V_S2` are `parameter (fixed = false)` whose `initial equation` reads an *input*, so
# each is declared with a guess, listed as `missing` and given its equation in `initialization_eqs` (F-33).
# The `sic` above is reproduced, not fixed: the lag of the **second** input is started from the initial value of
# the **first**, so the chain is inconsistent at t = 0 whenever the two inputs do not start at the same value
# (F-90).
# Omitted: graphical annotations.

@component function STBSVC(; name, K_S1 = 1, T_S7 = 1, T_S8 = 1, T_S9 = 1, T_S13 = 1, T_S14 = 1, K_S3 = 1,
        V_SCS = 2, K_S2 = 1, T_S10 = 1, T_S11 = 1, T_S12 = 1)
    K_S1, T_S7, T_S8, T_S9, T_S13, T_S14, K_S3, V_SCS, K_S2, T_S10, T_S11, T_S12 =
        float.((K_S1, T_S7, T_S8, T_S9, T_S13, T_S14, K_S3, V_SCS, K_S2, T_S10, T_S11, T_S12))
    n = (; K_S1, T_S7, T_S8, T_S9, T_S13, T_S14, K_S3, V_SCS, K_S2, T_S10, T_S11, T_S12)
    base = BasePSS(; name = :base)
    pars = @parameters begin
        K_S1 = K_S1, [description = "First input low-pass filter gain. It must be greater than 0"]
        T_S7 = T_S7, [description = "First input low-pass filter time constant"]
        T_S8 = T_S8, [description = "First input regulator numerator (lead) time constant"]
        T_S9 = T_S9, [description = "First input regulator denominaor (lag) time constant. It must be greater than 0"]
        T_S13 = T_S13, [description = "Stabilizer washout numerator time constant. It must be greater than 0"]
        T_S14 = T_S14, [description = "Stabilizer washout denominator time constant. It must be greater than 0"]
        K_S3 = K_S3, [description = "Stabilizer washout proportional gain"]
        V_SCS = V_SCS, [description = "Stabilizer output limit value"]
        K_S2 = K_S2, [description = "Second input low-pass filter gain"]
        T_S10 = T_S10, [description = "Second input low-pass filter time constant"]
        T_S11 = T_S11, [description = "Second input regulator numerator (lead) time constant"]
        T_S12 = T_S12, [description = "Second input regulator denominaor (lag) time constant. It must be greater than 0 if K_S2 is different from 0"]
        V_S10, [guess = 0.0]
        V_S20, [guess = 0.0]
    end
    systems = @named begin
        imSimpleLag = SimpleLag(; K = n.K_S1, y_start = V_S10, T = n.T_S7)
        imSimpleLag1 = SimpleLag(; y_start = V_S10, K = n.K_S2, T = n.T_S10)
        imLeadLag = LeadLag(; K = 1, T1 = n.T_S8, T2 = n.T_S9, y_start = V_S10)
        imLeadLag1 = LeadLag(; K = 1, T1 = n.T_S11, T2 = n.T_S12, y_start = V_S20)
        add = Add()
        imDerivativeLag = Derivative(; k = n.T_S13, T = n.T_S14, y_start = 0, initType = :InitialOutput)
        gain = Gain(; k = n.K_S3)
        limiter = Limiter(; uMax = n.V_SCS, uMin = -n.V_SCS)
    end
    @unpack V_S1, V_S2, VOTHSG = base
    eqs = Equation[
        limiter.u ~ gain.y,                     # connect(gain.y, limiter.u)
        VOTHSG ~ limiter.y,                     # connect(limiter.y, VOTHSG)
        imSimpleLag.u ~ V_S1,                   # connect(V_S1, imSimpleLag.u)
        imLeadLag.u ~ imSimpleLag.y,            # connect(imSimpleLag.y, imLeadLag.u)
        add.u1 ~ imLeadLag.y,                   # connect(imLeadLag.y, add.u1)
        imSimpleLag1.u ~ V_S2,                  # connect(V_S2, imSimpleLag1.u)
        imLeadLag1.u ~ imSimpleLag1.y,          # connect(imSimpleLag1.y, imLeadLag1.u)
        add.u2 ~ imLeadLag1.y,                  # connect(imLeadLag1.y, add.u2)
        gain.u ~ imDerivativeLag.y,             # connect(imDerivativeLag.y, gain.u)
        imDerivativeLag.u ~ add.y,              # connect(add.y, imDerivativeLag.u)
    ]
    extend(System(eqs, t, [], pars; name, systems, initialization_eqs = [V_S10 ~ V_S1, V_S20 ~ V_S2],
        initial_conditions = Dict(V_S10 => missing, V_S20 => missing),
        guesses = Dict(V_S1 => 0.0, V_S2 => 0.0, VOTHSG => 0.0)), base)
end
