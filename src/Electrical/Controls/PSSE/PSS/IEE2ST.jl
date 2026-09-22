# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/PSS/IEE2ST.mo (extends nothing: its ports are its own), blocks as
# subsystems:
#   imSimpleLag/imSimpleLag1  OpenIPSL.NonElectrical.Continuous.SimpleLag (K = K_1/K_2, T = T_1/T_2,
#                                                                          y_start = K_1*ICS10 / ICS20)
#   imDerivativeLag           Modelica.Blocks.Continuous.Derivative (k = T_3, T = T_4, y_start = 0, InitialOutput)
#   imLeadLag/1/2             OpenIPSL.NonElectrical.Continuous.LeadLag (K = 1, T_5/T_6, T_7/T_8, T_9/T_10,
#                                                                        y_start = 0)
#   add                       Modelica.Blocks.Math.Add
#   limiter                   Modelica.Blocks.Nonlinear.Limiter (uMax = L_SMAX, uMin = L_SMIN)
# Ports as plain variables: V_S1, V_S2 and VCT (inputs), VOTHSG (output) and the protected output VSS.
# `ICS10 = V_S1` and `ICS20 = V_S2` are `parameter (fixed = false)` whose `initial equation` reads an *input*, so
# each is declared with a guess, listed as `missing` and given its equation in `initialization_eqs` (F-33).
# The five-branch `if` that gates the output is on the parameters V_CU/V_CL, so the branch is chosen in Julia, as
# in IEEEST.jl; the comparisons against the *input* VCT inside the chosen branch stay as `ifelse`. The .mo writes
# `not (x < 0 or x > 0)` for "x is exactly zero"; that is transcribed as `x == 0`.
# Omitted: graphical annotations.

@component function IEE2ST(; name, K_1 = 1, K_2 = 1, T_1 = 0.005, T_2 = 0.005, T_3 = 10, T_4 = 10, T_5 = 0.16,
        T_6 = 0.02, T_7 = 0.16, T_8 = 0.02, T_9 = 0.16, T_10 = 0.02, L_SMAX = 0.1, L_SMIN = -0.1, V_CU = 0, V_CL = 0)
    K_1, K_2, T_1, T_2, T_3, T_4, T_5, T_6, T_7, T_8, T_9, T_10, L_SMAX, L_SMIN, V_CU, V_CL =
        float.((K_1, K_2, T_1, T_2, T_3, T_4, T_5, T_6, T_7, T_8, T_9, T_10, L_SMAX, L_SMIN, V_CU, V_CL))
    n = (; K_1, K_2, T_1, T_2, T_3, T_4, T_5, T_6, T_7, T_8, T_9, T_10, L_SMAX, L_SMIN)
    V_CUn, V_CLn = V_CU, V_CL   # numeric copies: `@parameters` below rebinds both names (F-22)
    pars = @parameters begin
        K_1 = K_1, [description = "First input filter gain"]
        K_2 = K_2, [description = "Second input filter gain"]
        T_1 = T_1, [description = "First input filter time constant"]
        T_2 = T_2, [description = "Second input filter time constant"]
        T_3 = T_3, [description = "Power system stabilizer washout numerator time constant"]
        T_4 = T_4, [description = "Power system stabilizer washout denominator time constant"]
        T_5 = T_5, [description = "First power system stabilizer numerator (lead) time constant"]
        T_6 = T_6, [description = "First power system stabilizer denominator (lag) time constant"]
        T_7 = T_7, [description = "Second power system stabilizer numerator (lead) time constant"]
        T_8 = T_8, [description = "Second power system stabilizer denominator (lag) time constant"]
        T_9 = T_9, [description = "Third power system stabilizer numerator (lead) time constant"]
        T_10 = T_10, [description = "Third power system stabilizer denominator (lag) time constant"]
        L_SMAX = L_SMAX, [description = "Maximum output for sequence of washout filters"]
        L_SMIN = L_SMIN, [description = "Minimum output for sequence of washout filters"]
        V_CU = V_CU, [description = "Maximum power system stabilizer output"]
        V_CL = V_CL, [description = "Minimum power system stabilizer output"]
        ICS10, [guess = 0.0]
        ICS20, [guess = 0.0]
    end
    systems = @named begin
        add = Add()
        limiter = Limiter(; uMax = n.L_SMAX, uMin = n.L_SMIN)
        imDerivativeLag = Derivative(; k = n.T_3, T = n.T_4, y_start = 0, initType = :InitialOutput)
        imSimpleLag = SimpleLag(; K = n.K_1, T = n.T_1, y_start = K_1 * ICS10)
        imSimpleLag1 = SimpleLag(; K = n.K_2, T = n.T_2, y_start = ICS20)
        imLeadLag = LeadLag(; K = 1, T1 = n.T_5, T2 = n.T_6, y_start = 0)
        imLeadLag1 = LeadLag(; K = 1, T1 = n.T_7, T2 = n.T_8, y_start = 0)
        imLeadLag2 = LeadLag(; K = 1, T1 = n.T_9, T2 = n.T_10, y_start = 0)
    end
    vars = @variables begin
        V_S1(t), [guess = 0.0, description = "PSS input signal 1"]
        V_S2(t), [guess = 0.0, description = "PSS input signal 2"]
        VCT(t), [description = "Compensated machine terminal voltage [pu]"]
        VOTHSG(t), [guess = 0.0, description = "PSS output signal"]
        VSS(t)
    end
    # `if not (V_CU == 0) ...`: the five branches are decided on the parameters, the comparisons on VCT are not
    vothsg = V_CUn == 0 && V_CLn != 0 ? ifelse(VCT > V_CL, VSS, 0) :
             V_CLn == 0 && V_CUn != 0 ? ifelse(VCT < V_CU, VSS, 0) :
             V_CUn == 0 && V_CLn == 0 ? VSS :
             ifelse((VCT > V_CL) & (VCT < V_CU), VSS, 0)
    eqs = Equation[
        VOTHSG ~ vothsg,
        VSS ~ limiter.y,                        # connect(limiter.y, VSS)
        imSimpleLag1.u ~ V_S2,                  # connect(V_S2, imSimpleLag1.u)
        add.u2 ~ imSimpleLag1.y,                # connect(imSimpleLag1.y, add.u2)
        imSimpleLag.u ~ V_S1,                   # connect(V_S1, imSimpleLag.u)
        add.u1 ~ imSimpleLag.y,                 # connect(imSimpleLag.y, add.u1)
        limiter.u ~ imLeadLag2.y,               # connect(imLeadLag2.y, limiter.u)
        imLeadLag2.u ~ imLeadLag1.y,            # connect(imLeadLag1.y, imLeadLag2.u)
        imLeadLag1.u ~ imLeadLag.y,             # connect(imLeadLag.y, imLeadLag1.u)
        imLeadLag.u ~ imDerivativeLag.y,        # connect(imLeadLag.u, imDerivativeLag.y)
        imDerivativeLag.u ~ add.y,              # connect(add.y, imDerivativeLag.u)
    ]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = [ICS10 ~ V_S1, ICS20 ~ V_S2],
        initial_conditions = Dict(ICS10 => missing, ICS20 => missing))
end
