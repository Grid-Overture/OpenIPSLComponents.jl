# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/PSS/IEEEST.mo (extends nothing: its ports are its own)
# Ports as plain variables: V_S and V_CT (inputs), VOTHSG (output) and the protected output `Vs`.
# Blocks: Filter1_1/Filter1_2/Filter2_1/Filter2_2 = TransferFunction(InitialOutput, y_start = V_S0, with the
# coefficient vectors below), T_1_T_2/T_3_T_4 = LeadLag(1, T_1/T_3, T_2/T_4, x_start = y_start = V_S0),
# VSS = Limiter(L_SMAX, L_SMIN), imDerivativeLag = Continuous.Derivative(k = K_S*T_5, T = T_6, y_start = 0,
# InitialOutput, x_start = V_S0), swith_filter1..4 = Logical.Switch (the .mo's spelling),
# booleanConstant/booleanConstant1 = BooleanConstant(bypass_filter2/1), and1 = MathBoolean.And(nu = 2).
# `n1`, `n2`, `n3` and the `initial equation` that fills `a1`, `a2`, `b`, `bypass_filter1` and `bypass_filter2`
# depend only on the parameters A_1..A_6, so they are plain Julia arithmetic before `@parameters` (F-33) and the
# vectors reach the `TransferFunction`s as numbers (F-22). Only `V_S0 = V_S` reads an input and is a `missing`
# parameter. The `.mo` writes `not (x > 0 or x < 0)` for "x is exactly zero"; that is transcribed as `x == 0`.
# The five-branch `if` that gates the output is on the parameters `V_CU`/`V_CL`, so the branch is chosen in Julia;
# the comparisons against the *input* `V_CT` inside the chosen branch stay as `ifelse`.
# Omitted: graphical annotations.

@component function IEEEST(; name, A_1 = 0, A_2 = 0, A_3 = 0, A_4 = 0, A_5 = 0, A_6 = 0, T_1 = 0, T_2 = 0, T_3 = 0,
        T_4 = 0, T_5 = 1.65, T_6 = 1.65, K_S = 6.2, L_SMAX = 0.26, L_SMIN = -0.1, V_CU = 999, V_CL = -999)
    A_1, A_2, A_3, A_4, A_5, A_6, T_1, T_2, T_3, T_4, T_5, T_6, K_S, L_SMAX, L_SMIN, V_CU, V_CL =
        float.((A_1, A_2, A_3, A_4, A_5, A_6, T_1, T_2, T_3, T_4, T_5, T_6, K_S, L_SMAX, L_SMIN, V_CU, V_CL))
    n1 = A_1 == 0 && A_2 == 0 ? 4 : A_2 == 0 ? 2 : 3
    n2 = A_3 == 0 && A_4 == 0 ? 4 : A_4 == 0 ? 2 : 3
    n3 = A_6 == 0 && A_5 == 0 ? 1 : A_6 == 0 ? 2 : 3
    b = n3 == 1 ? [1.0] : n3 == 2 ? [A_5, 1.0] : [A_6, A_5, 1.0]
    a1 = n1 == 4 ? [1.0, 1.0, 1.0, 1.0] : n1 == 3 ? [A_2, A_1, 1.0] : [A_1, 1.0]
    bypass_filter1 = n1 == 4
    a2 = n2 == 4 ? [1.0, 1.0, 1.0, 1.0] : n2 == 3 ? [A_4, A_3, 1.0] : [A_3, 1.0]
    bypass_filter2 = n2 == 4
    nb = (; T_1, T_2, T_3, T_4, T_5, T_6, K_S, L_SMAX, L_SMIN)
    V_CUn, V_CLn = V_CU, V_CL   # numeric copies: `@parameters` below rebinds both names (F-22)
    pars = @parameters begin
        A_1 = A_1, [description = "Power system stabilizer high frequency filter coefficient"]
        A_2 = A_2, [description = "Power system stabilizer high frequency filter coefficient"]
        A_3 = A_3, [description = "Power system stabilizer high frequency filter coefficient"]
        A_4 = A_4, [description = "Power system stabilizer high frequency filter coefficient"]
        A_5 = A_5, [description = "Power system stabilizer high frequency filter coefficient"]
        A_6 = A_6, [description = "Power system stabilizer high frequency filter coefficient"]
        T_1 = T_1, [description = "PSS first numerator (lead) time constant"]
        T_2 = T_2, [description = "PSS first denominator (lag) time constant"]
        T_3 = T_3, [description = "PSS second numerator (lead) time constant"]
        T_4 = T_4, [description = "PSS second denominator (lag) time constant"]
        T_5 = T_5, [description = "Stabilizer washout numerator time constant"]
        T_6 = T_6, [description = "Stabilizer washout denominator time constant"]
        K_S = K_S, [description = "Stabilizer Gain"]
        L_SMAX = L_SMAX, [description = "Maximum output for stabilizer washout filter"]
        L_SMIN = L_SMIN, [description = "Minimum output for stabilizer washout filter"]
        V_CU = V_CU, [description = "Maximum power system stabilizer output"]
        V_CL = V_CL, [description = "Minimum power system stabilizer output"]
        V_S0, [guess = 0.0]
    end
    systems = @named begin
        Filter1_1 = TransferFunction(; initType = :InitialOutput, y_start = V_S0, a = a1, b = b)
        T_1_T_2 = LeadLag(; K = 1, T1 = nb.T_1, T2 = nb.T_2, x_start = V_S0, y_start = V_S0)
        T_3_T_4 = LeadLag(; K = 1, T1 = nb.T_3, T2 = nb.T_4, x_start = V_S0, y_start = V_S0)
        VSS = Limiter(; uMax = nb.L_SMAX, uMin = nb.L_SMIN)
        imDerivativeLag = Derivative(; T = nb.T_6, y_start = 0, initType = :InitialOutput, x_start = V_S0,
            k = nb.K_S * nb.T_5)
        Filter2_1 = TransferFunction(; initType = :InitialOutput, y_start = V_S0, b = [1.0], a = a2)
        swith_filter2 = Switch()
        booleanConstant = BooleanConstant(; k = bypass_filter2)
        Filter1_2 = TransferFunction(; initType = :InitialOutput, y_start = V_S0, a = a1, b = [1.0])
        Filter2_2 = TransferFunction(; initType = :InitialOutput, y_start = V_S0, a = a2, b = b)
        swith_filter1 = Switch()
        booleanConstant1 = BooleanConstant(; k = bypass_filter1)
        swith_filter3 = Switch()
        and1 = And(; nu = 2)
        swith_filter4 = Switch()
    end
    vars = @variables begin
        VOTHSG(t), [guess = 0.0, description = "PSS output signal"]
        V_S(t), [guess = 0.0, description = "PSS input signal"]
        V_CT(t), [description = "Compensated machine terminal voltage [pu]"]
        Vs(t), [description = "Connector of Real output signal"]
    end
    # `if not (V_CU == 0) ...`: the five branches are decided on the parameters, the comparisons on V_CT are not
    vothsg = V_CUn == 0 && V_CLn != 0 ? ifelse(V_CT > V_CL, Vs, 0) :
             V_CLn == 0 && V_CUn != 0 ? ifelse(V_CT < V_CU, Vs, 0) :
             V_CUn == 0 && V_CLn == 0 ? Vs :
             ifelse((V_CT > V_CL) & (V_CT < V_CU), Vs, 0)
    eqs = Equation[
        VOTHSG ~ vothsg,
        V_S ~ Filter1_1.u,                   # connect(V_S, Filter1_1.u)
        T_1_T_2.y ~ T_3_T_4.u,               # connect(T_1_T_2.y, T_3_T_4.u)
        imDerivativeLag.y ~ VSS.u,           # connect(imDerivativeLag.y, VSS.u)
        T_3_T_4.y ~ imDerivativeLag.u,       # connect(T_3_T_4.y, imDerivativeLag.u)
        Filter1_1.y ~ Filter2_1.u,           # connect(Filter1_1.y, Filter2_1.u)
        swith_filter2.u3 ~ Filter2_1.y,      # connect(swith_filter2.u3, Filter2_1.y)
        swith_filter2.u1 ~ Filter2_1.u,      # connect(swith_filter2.u1, Filter2_1.u)
        booleanConstant.y ~ swith_filter2.u2,# connect(booleanConstant.y, swith_filter2.u2)
        Filter1_2.u ~ Filter1_1.u,           # connect(Filter1_2.u, Filter1_1.u)
        swith_filter1.y ~ Filter2_2.u,       # connect(swith_filter1.y, Filter2_2.u)
        swith_filter1.u1 ~ Filter1_1.u,      # connect(swith_filter1.u1, Filter1_1.u)
        swith_filter1.u3 ~ Filter1_2.y,      # connect(swith_filter1.u3, Filter1_2.y)
        booleanConstant1.y ~ swith_filter1.u2,# connect(booleanConstant1.y, swith_filter1.u2)
        and1.y ~ swith_filter3.u2,           # connect(and1.y, swith_filter3.u2)
        and1.u[1] ~ swith_filter2.u2,        # connect(and1.u[1], swith_filter2.u2)
        and1.u[2] ~ swith_filter1.u2,        # connect(and1.u[2], swith_filter1.u2)
        swith_filter3.u1 ~ Filter1_1.u,      # connect(swith_filter3.u1, Filter1_1.u)
        swith_filter4.y ~ swith_filter3.u3,  # connect(swith_filter4.y, swith_filter3.u3)
        swith_filter4.u2 ~ swith_filter1.u2, # connect(swith_filter4.u2, swith_filter1.u2)
        Filter2_2.y ~ swith_filter4.u1,      # connect(Filter2_2.y, swith_filter4.u1)
        swith_filter2.y ~ swith_filter4.u3,  # connect(swith_filter2.y, swith_filter4.u3)
        swith_filter3.y ~ T_1_T_2.u,         # connect(swith_filter3.y, T_1_T_2.u)
        VSS.y ~ Vs,                          # connect(VSS.y, Vs)
    ]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = [V_S0 ~ V_S],
        initial_conditions = Dict(V_S0 => missing))
end
