# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/AVR/AVRTypeI.mo, blocks as subsystems:
#   firstOrder2       Modelica.Blocks.Continuous.FirstOrder (k = 1, T = Tr, InitialOutput, y_start = v0)   v -> vm
#   feedback2         Modelica.Blocks.Math.Feedback                                     vref - firstOrder2.y
#   transferFunction  Modelica.Blocks.Continuous.TransferFunction (b = {K0*T2*T4, K0*(T2 + T4), K0},
#                                                                 a = {T1*T3, T1 + T3, 1}, InitialOutput, y_start = vr0)
#   limiter           Modelica.Blocks.Nonlinear.Limiter (uMax = vrmax, uMin = vrmin)
#   feedback          Modelica.Blocks.Math.Feedback                              limiter.y - ceilingBlock.y
#   firstOrder        Modelica.Blocks.Continuous.FirstOrder (k = 1, T = Te, InitialOutput, y_start = vf00)   -> vf
#   ceilingBlock      OpenIPSL.NonElectrical.Nonlinear.CeilingBlock, **instantiated with no modifiers** over vf
# The RealInput/RealOutput ports v, vref, vf0, vf, vref0 are plain variables.
# Two literal quirks of the .mo: (1) `ceilingBlock` carries no modifiers, so it takes CeilingBlock.mo's own defaults
# Ae = 0, Be = 1 and its output is identically zero - the model's own Ae, Be reach only `vr0`; (2) `vref0` is assigned
# by a plain `algorithm` section, i.e. continuously, which is an equation.
# `vf00` is a `parameter (fixed = false)` set by `initial algorithm vf00 := vf0`, an input, so it is declared with a
# guess, listed as `missing` in initial_conditions and given its equation in initialization_eqs (F-33); `vr0` depends
# on it and is `missing` with its own equation for the same reason (the Pe0 -> Pmech0 -> Pref chain of GGOV1). Both
# reach `firstOrder(y_start = vf00)` and `transferFunction(y_start = vr0)` as a child's parameter *binding*, which
# ModelingToolkit turns into an initialization unknown with that binding as its equation (F-38).
# The coefficient vectors b, a are built in Julia before `@parameters` (F-22, point 1).
# Omitted: graphical annotations.

@component function AVRTypeI(; name, vrmax = 7.57, vrmin = 0, K0 = 7.04, T1 = 6.67, T2 = 1, T3 = 1, T4 = 1, Te = 0.4,
        Tr = 0.05, Ae = 0.0006, Be = 0.9, v0 = 1)
    vrmax, vrmin, K0, T1, T2, T3, T4, Te, Tr, Ae, Be, v0 =
        float.((vrmax, vrmin, K0, T1, T2, T3, T4, Te, Tr, Ae, Be, v0))   # F-21
    b = [K0 * T2 * T4, K0 * (T2 + T4), K0]
    a = [T1 * T3, T1 + T3, 1.0]
    vf00_guess = 1.0
    vr0_guess = vf00_guess - Ae * exp(Be * abs(vf00_guess))
    pars = @parameters begin
        vrmax = vrmax, [description = "Maximum regulator voltage (pu)"]
        vrmin = vrmin, [description = "Minimum regulator voltage (pu)"]
        K0 = K0, [description = "Regulator gain (pu/pu)"]
        T1 = T1, [description = "First pole (s)"]
        T2 = T2, [description = "First zero (s)"]
        T3 = T3, [description = "Second pole (s)"]
        T4 = T4, [description = "Second pole (s)"]
        Te = Te, [description = "Field circuit time constant (s)"]
        Tr = Tr, [description = "Measurement time constant (s)"]
        Ae = Ae, [description = "1st ceiling coefficient"]
        Be = Be, [description = "2nd ceiling coefficient"]
        v0 = v0, [description = "Initialization (pu)"]
        vf00, [guess = vf00_guess]   # fixed = false: `initial algorithm vf00 := vf0`, an input (F-33)
        vr0, [guess = vr0_guess]     # vr0 = vf00 - Ae*exp(Be*abs(vf00)): a chain of `missing` (F-38)
    end
    systems = @named begin
        feedback = Feedback()
        firstOrder = FirstOrder(; k = 1, T = Te, initType = :InitialOutput, y_start = vf00)
        ceilingBlock = CeilingBlock()   # no modifiers in the .mo: Ae = 0, Be = 1 (sic)
        firstOrder2 = FirstOrder(; k = 1, T = Tr, initType = :InitialOutput, y_start = v0)
        feedback2 = Feedback()
        transferFunction = TransferFunction(; b, a, initType = :InitialOutput, y_start = vr0)
        limiter = Limiter(; uMax = vrmax, uMin = vrmin)
    end
    vars = @variables begin
        v(t), [description = "Generator terminal voltage (pu)"]
        vf(t), [description = "Field voltage (pu)"]
        vref(t), [description = "Reference generator terminal voltage (pu)"]
        vref0(t), [description = "Voltage reference at t=0 (pu)"]
        vf0(t), [description = "Initial field voltage (pu)"]
    end
    eqs = Equation[
        vref0 ~ v0 + (vr0 / K0),          # algorithm vref0 := v0 + (vr0/K0)
        vf ~ firstOrder.y,                # connect(firstOrder.y, vf)
        ceilingBlock.u ~ vf,              # connect(ceilingBlock.u, vf)
        feedback.u2 ~ ceilingBlock.y,     # connect(ceilingBlock.y, feedback.u2)
        firstOrder2.u ~ v,                # connect(v, firstOrder2.u)
        feedback2.u2 ~ firstOrder2.y,     # connect(feedback2.u2, firstOrder2.y)
        feedback2.u1 ~ vref,              # connect(feedback2.u1, vref)
        firstOrder.u ~ feedback.y,        # connect(feedback.y, firstOrder.u)
        transferFunction.u ~ feedback2.y, # connect(feedback2.y, transferFunction.u)
        limiter.u ~ transferFunction.y,   # connect(transferFunction.y, limiter.u)
        feedback.u1 ~ limiter.y,          # connect(limiter.y, feedback.u1)
    ]
    System(eqs, t, vars, pars; name, systems,
        initial_conditions = Dict(vf00 => missing, vr0 => missing),
        guesses = Dict(v => v0, vf0 => vf00_guess, vf => vf00_guess, vref => v0 + vr0_guess / K0,
            vref0 => v0 + vr0_guess / K0),
        initialization_eqs = [vf00 ~ vf0, vr0 ~ vf00 - Ae * exp(Be * abs(vf00))])
end
