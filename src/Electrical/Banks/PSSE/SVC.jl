# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Banks/PSSE/SVC.mo ("On bus 10106 & 10114"), blocks as subsystems:
#   imSetPoint/imSetPoint1/imSetPoint2   Modelica.Blocks.Sources.Constant (k = Vref / Bref / OtherSignals)
#   imLeadLag                            OpenIPSL.NonElectrical.Continuous.LeadLag (K, T1, T3, init_SVC_Leadlag)
#   imLeadLag1                           OpenIPSL.NonElectrical.Continuous.LeadLag (1, T2, T4, init_SVC_Leadlag)
#   imLimited                            Modelica.Blocks.Nonlinear.Limiter (Vmin, Vmax)
#   imLimitedSimpleLag                   OpenIPSL.NonElectrical.Continuous.SimpleLagLim (K = 1, T = T5,
#                                            outMin = var_C, outMax = var_R, y_start = init_SVC_Lag)   <- sic
#   shunt                                OpenIPSL.Electrical.Banks.PwShunt
#   imRelay                              OpenIPSL.NonElectrical.Logical.Relay3 (Vov is its own default)
#   Q_capacitors/Q_Reactors              Modelica.Blocks.Sources.Constant (k = var_C / var_R)
#   imGain                               Modelica.Blocks.Math.Gain (k = 1/Sbase)
#   absoluteVoltage                      OpenIPSL.Electrical.Sensors.PwVoltage
#   add                                  Modelica.Blocks.Math.Add (k1 = 1, k2 = -1)
#   add3_1                               Modelica.Blocks.Math.Add3 (k1 = -1, k3 = -1)
# The only port is the PwPin `VIB`.
# Two things reproduced and not fixed (rule 5, F-90): `imLimitedSimpleLag` gets `outMin = var_C` and
# `outMax = var_R`, i.e. the capacitive limit as the lower bound and the inductive one as the upper, so any
# parameterization with var_C > var_R gives that block outMax < outMin; and `imGain(k = 1/Sbase)` divides a relay
# output whose middle branch is the regulator signal, bounded by [Vmin, Vmax] in per unit, while its two outer
# branches carry var_C and var_R in var.
# `imRelay` does not take the model's `Vov`: the .mo instantiates `Relay3` with no modifier, so the relay keeps its
# own default 0.5 and the model's `Vov` parameter reaches nothing (sic).
# Omitted: graphical annotations.

@component function SVC(; name, Vref, Bref, K = 150, T1, T2, T3, T4, T5 = 0.03, Vmax, Vmin, Vov = 0.5, Sbase,
        init_SVC_Leadlag, init_SVC_Lag, OtherSignals, var_C = 100e6, var_R = -50e6)
    Vref, Bref, K, T1, T2, T3, T4, T5, Vmax, Vmin, Vov, Sbase, init_SVC_Leadlag, init_SVC_Lag, OtherSignals,
        var_C, var_R = float.((Vref, Bref, K, T1, T2, T3, T4, T5, Vmax, Vmin, Vov, Sbase, init_SVC_Leadlag,
            init_SVC_Lag, OtherSignals, var_C, var_R))
    n = (; Vref, Bref, K, T1, T2, T3, T4, T5, Vmax, Vmin, Sbase, init_SVC_Leadlag, init_SVC_Lag, OtherSignals,
        var_C, var_R)
    pars = @parameters begin
        Vref = Vref, [description = "Reference voltage (pu)"]
        Bref = Bref, [description = "Reference susceptance (pu)"]
        K = K, [description = "Steady-state gain"]
        T1 = T1, [description = "Time constant (s)"]
        T2 = T2, [description = "Time constant (s)"]
        T3 = T3, [description = "Time constant (s)"]
        T4 = T4, [description = "Time constant (s)"]
        T5 = T5, [description = "Time constant of thyristor bridge (s)"]
        Vmax = Vmax
        Vmin = Vmin
        Vov = Vov, [description = "Override voltage (pu; declared and unused, sic)"]
        Sbase = Sbase, [description = "Base power of the bus (VA)"]
        init_SVC_Leadlag = init_SVC_Leadlag, [description = "Initial value"]
        init_SVC_Lag = init_SVC_Lag, [description = "Initial value"]
        OtherSignals = OtherSignals
        var_C = var_C, [description = "Total compensation capacity of shunt capacitor"]
        var_R = var_R, [description = "Total compensation capacity of shunt reactor"]
    end
    systems = @named begin
        imSetPoint = Constant(; k = n.Vref)
        imSetPoint1 = Constant(; k = n.Bref)
        imLeadLag = LeadLag(; K = n.K, T1 = n.T1, T2 = n.T3, y_start = n.init_SVC_Leadlag)
        imLeadLag1 = LeadLag(; K = 1, T1 = n.T2, T2 = n.T4, y_start = n.init_SVC_Leadlag)
        imLimited = Limiter(; uMin = n.Vmin, uMax = n.Vmax)
        imLimitedSimpleLag = SimpleLagLim(; K = 1, T = n.T5, outMin = n.var_C, y_start = n.init_SVC_Lag,
            outMax = n.var_R)
        shunt = PwShunt()
        imRelay = Relay3()
        Q_capacitors = Constant(; k = n.var_C)
        Q_Reactors = Constant(; k = n.var_R)
        imGain = Gain(; k = 1 / n.Sbase)
        imSetPoint2 = Constant(; k = n.OtherSignals)
        absoluteVoltage = PwVoltage()
        add = Add(; k1 = 1, k2 = -1)
        add3_1 = Add3(; k1 = -1, k3 = -1)
        VIB = PwPin()
    end
    eqs = Equation[
        connect(VIB, absoluteVoltage.p),        # connect(VIB, absoluteVoltage.p)
        connect(shunt.p, VIB),                  # connect(shunt.p, VIB)
        imGain.u ~ imRelay.y,                   # connect(imRelay.y, imGain.u)
        shunt.Q ~ imGain.y,                     # connect(shunt.Q, imGain.y)
        imRelay.u2 ~ imLimitedSimpleLag.y,      # connect(imLimitedSimpleLag.y, imRelay.u2)
        imLimitedSimpleLag.u ~ imLimited.y,     # connect(imLimited.y, imLimitedSimpleLag.u)
        imLimited.u ~ imLeadLag1.y,             # connect(imLeadLag1.y, imLimited.u)
        imLeadLag1.u ~ imLeadLag.y,             # connect(imLeadLag.y, imLeadLag1.u)
        imRelay.u4 ~ Q_Reactors.y,              # connect(Q_Reactors.y, imRelay.u4)
        imRelay.u3 ~ Q_capacitors.y,            # connect(Q_capacitors.y, imRelay.u3)
        add.u2 ~ absoluteVoltage.v,             # connect(add.u2, absoluteVoltage.v)
        add.u1 ~ imSetPoint.y,                  # connect(imSetPoint.y, add.u1)
        imLeadLag.u ~ add3_1.y,                 # connect(add3_1.y, imLeadLag.u)
        add3_1.u3 ~ imSetPoint2.y,              # connect(imSetPoint2.y, add3_1.u3)
        add3_1.u1 ~ imSetPoint1.y,              # connect(imSetPoint1.y, add3_1.u1)
        add3_1.u2 ~ add.y,                      # connect(add.y, add3_1.u2)
        imRelay.u1 ~ add3_1.u2,                 # connect(imRelay.u1, add3_1.u2)
    ]
    System(eqs, t, [], pars; name, systems)
end
