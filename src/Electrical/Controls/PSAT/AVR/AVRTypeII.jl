# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/AVR/AVRTypeII.mo, blocks as subsystems:
#   firstOrder2       Modelica.Blocks.Continuous.FirstOrder (k = 1, T = Tr, SteadyState, y_start = v0)
#   Verr, feedback1   Modelica.Blocks.Math.Feedback                                      vref - firstOrder2.y, then - derivativeBlock.y
#   simpleLagLim      OpenIPSL.NonElectrical.Continuous.SimpleLagLim (K = Ka, T = Ta, y_start = vr10, vrmax, vrmin)
#   feedback          Modelica.Blocks.Math.Feedback                             simpleLagLim.y - ceilingBlock.y
#   ceilingBlock      OpenIPSL.NonElectrical.Nonlinear.CeilingBlock (Ae, Be), over vf
#   ExcitationSystem  Modelica.Blocks.Continuous.TransferFunction (b = {1}, a = {Te, Ke}, InitialOutput, y_start = vf00)  -> vf
#   derivativeBlock   Modelica.Blocks.Continuous.Derivative (k = Kf, T = Tf, SteadyState, y_start = 0, x_start = vf00)
# The RealInput/RealOutput ports v, vref, vf0, vf, vref0 are plain variables. `vref0` is assigned by a plain
# `algorithm` section, i.e. continuously, which is an equation.
# `vf00` is a `parameter (fixed = false)` set by `initial algorithm vf00 := vf0`, an input, so it is declared with a
# guess, listed as `missing` in initial_conditions and given its equation in initialization_eqs (F-33); `vr10`
# depends on it and is `missing` with its own equation for the same reason (F-38, as `vr0` in AVRTypeI.jl). Both
# reach `ExcitationSystem(y_start = vf00)`, `derivativeBlock(x_start = vf00)` and `simpleLagLim(y_start = vr10)` as a
# child's parameter *binding*, which ModelingToolkit turns into an initialization unknown with that binding as its
# equation.
# The limiter event of `simpleLagLim` (the `when ... reinit(state, ...)`) is the block's: the continuous event of
# F-14, the guard of its conjunction (F-55) and the discrete callback that reproduces OpenModelica's reset inside an
# event of another component (F-41). Until this batch the model was flattened and carried only the first of the
# three (F-59).
# Omitted: the protected parameters vfstate (the `x_start` of a block initialized with InitialOutput, so it is only
# a guess; it equals Ke*vf00, which is 0 for the default Ke = 0) and vr20 (unused), graphical annotations.

@component function AVRTypeII(; name, vrmin = -5, vrmax = 5, Ka = 100, Ta = 0.5, Kf = 0.15, Tf = 0.1, Ke = 0, Te = 0.2,
        Tr = 0.001, Ae = 0.0006, Be = 0.9, v0 = 1)
    vrmin, vrmax, Ka, Ta, Kf, Tf, Ke, Te, Tr, Ae, Be, v0 =
        float.((vrmin, vrmax, Ka, Ta, Kf, Tf, Ke, Te, Tr, Ae, Be, v0))   # F-21
    n = (; vrmin, vrmax, Ka, Ta, Kf, Tf, Ke, Te, Tr, Ae, Be, v0)
    vf00_guess = 1.0
    vr10_guess = Ke * vf00_guess + Ae * exp(Be * abs(vf00_guess)) * vf00_guess
    pars = @parameters begin
        vrmin = vrmin, [description = "Minimum regulator voltage (pu)"]
        vrmax = vrmax, [description = "Maximum regulator voltage (pu)"]
        Ka = Ka, [description = "Amplifier gain (pu/pu)"]
        Ta = Ta, [description = "Amplifier time constant (s)"]
        Kf = Kf, [description = "Stabilizer gain (pu/pu)"]
        Tf = Tf, [description = "Stabilizer time constant (s)"]
        Ke = Ke, [description = "Field circuit integral deviation (pu/pu)"]
        Te = Te, [description = "Field circuit time constant (s)"]
        Tr = Tr, [description = "Measurement time constant (s)"]
        Ae = Ae, [description = "1st ceiling coefficient"]
        Be = Be, [description = "2nd ceiling coefficient"]
        v0 = v0, [description = "Initial measured voltage (pu)"]
        vf00, [guess = vf00_guess]   # fixed = false: `initial algorithm vf00 := vf0`, an input (F-33)
        vr10, [guess = vr10_guess]   # vr10 = Ke*vf00 + Ae*exp(Be*abs(vf00))*vf00: a chain of `missing` (F-38)
    end
    systems = @named begin
        feedback = Feedback()
        ExcitationSystem = TransferFunction(; b = [1.0], a = [n.Te, n.Ke], initType = :InitialOutput, y_start = vf00)
        ceilingBlock = CeilingBlock(; Ae = n.Ae, Be = n.Be)
        derivativeBlock = Derivative(; k = n.Kf, T = n.Tf, initType = :SteadyState, y_start = 0, x_start = vf00)
        feedback1 = Feedback()
        firstOrder2 = FirstOrder(; k = 1, T = n.Tr, initType = :SteadyState, y_start = v0)
        Verr = Feedback()
        simpleLagLim = SimpleLagLim(; K = n.Ka, T = n.Ta, y_start = vr10, outMax = n.vrmax, outMin = n.vrmin)
    end
    vars = @variables begin
        v(t), [description = "Generator terminal voltage (pu)"]
        vf(t), [description = "Field voltage (pu)"]
        vref(t), [description = "Reference generator terminal voltage (pu)"]
        vref0(t), [description = "Voltage reference at t=0 (pu)"]
        vf0(t), [description = "Initial field voltage (pu)"]
    end
    eqs = Equation[
        vref0 ~ v0 + vr10 / Ka,              # algorithm vref0 := v0 + vr10/Ka
        vf ~ ExcitationSystem.y,             # connect(ExcitationSystem.y, vf)
        feedback.u2 ~ ceilingBlock.y,        # connect(ceilingBlock.y, feedback.u2)
        firstOrder2.u ~ v,                   # connect(v, firstOrder2.u)
        Verr.u2 ~ firstOrder2.y,             # connect(Verr.u2, firstOrder2.y)
        feedback1.u1 ~ Verr.y,               # connect(Verr.y, feedback1.u1)
        Verr.u1 ~ vref,                      # connect(Verr.u1, vref)
        ExcitationSystem.u ~ feedback.y,     # connect(feedback.y, ExcitationSystem.u)
        ceilingBlock.u ~ vf,                 # connect(ceilingBlock.u, vf)
        derivativeBlock.u ~ vf,              # connect(derivativeBlock.u, vf)
        feedback1.u2 ~ derivativeBlock.y,    # connect(feedback1.u2, derivativeBlock.y)
        simpleLagLim.u ~ feedback1.y,        # connect(feedback1.y, simpleLagLim.u)
        feedback.u1 ~ simpleLagLim.y,        # connect(simpleLagLim.y, feedback.u1)
    ]
    System(eqs, t, vars, pars; name, systems,
        initial_conditions = Dict(vf00 => missing, vr10 => missing),
        guesses = Dict(v => v0, vf0 => vf00_guess, vf => vf00_guess, vref => v0 + vr10_guess / Ka,
            vref0 => v0 + vr10_guess / Ka),
        initialization_eqs = [vf00 ~ vf0, vr10 ~ Ke * vf00 + Ae * exp(Be * abs(vf00)) * vf00])
end
