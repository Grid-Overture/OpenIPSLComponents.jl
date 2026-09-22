# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/PSS/PSSTypeIII.mo, blocks as subsystems:
#   simpleLagLim       OpenIPSL.NonElectrical.Continuous.SimpleLagLim (K = 1, T = Tc, y_start = 0,
#                                                                      outMax = vsmax, outMin = vsmin)
#   derivativeLag      OpenIPSL.NonElectrical.Continuous.DerivativeLag (K = Kw*Tw, T = Tw, y_start = 0)
#   transferFunction   Modelica.Blocks.Continuous.TransferFunction (b = {T1, T3, 1}, a = {T2, T4, 1})
# The RealInput/RealOutput ports vs1 and Vref are plain variables. None of the nine parameters has a default in
# the .mo, so all nine are required keyword arguments. `K = Kw*Tw` is Julia arithmetic before `@parameters`
# (F-22, point 1), as are the two coefficient vectors.
# Note that `Vref` is the stabilizer output **alone**: unlike PSSTypeI this model has no `vref0` input and no
# internal `add`, so whoever uses it has to add the exciter's own reference outside (sic).
# Omitted: graphical annotations.

@component function PSSTypeIII(; name, Kw, Tw, T1, T2, T3, T4, Tc, vsmax, vsmin)
    Kw, Tw, T1, T2, T3, T4, Tc, vsmax, vsmin = float.((Kw, Tw, T1, T2, T3, T4, Tc, vsmax, vsmin))
    KwTw = Kw * Tw
    b = [T1, T3, 1.0]
    a = [T2, T4, 1.0]
    n = (; Tw, Tc, vsmax, vsmin)
    pars = @parameters begin
        Kw = Kw, [description = "Stabilizer gain"]
        Tw = Tw, [description = "Wash-out time constant (s)"]
        T1 = T1, [description = "First stabilizer time constant (s)"]
        T2 = T2, [description = "Second stabilizer time constant (s)"]
        T3 = T3, [description = "Third stabilizer time constant (s)"]
        T4 = T4, [description = "Fourth stabilizer time constant (s)"]
        Tc = Tc, [description = "SimpleLagLim time constant (s)"]
        vsmax = vsmax, [description = "Max stabilizer output signal (pu)"]
        vsmin = vsmin, [description = "Min stabilizer output signal (pu)"]
    end
    systems = @named begin
        simpleLagLim = SimpleLagLim(; K = 1, T = n.Tc, y_start = 0, outMax = n.vsmax, outMin = n.vsmin)
        derivativeLag = DerivativeLag(; K = KwTw, T = n.Tw, y_start = 0)
        transferFunction = TransferFunction(; b = b, a = a)
    end
    vars = @variables begin
        vs1(t), [description = "Rotor speed"]
        Vref(t), [description = "Indexes of the algebraic variable"]
    end
    eqs = Equation[
        Vref ~ simpleLagLim.y,                 # connect(simpleLagLim.y, Vref)
        derivativeLag.u ~ vs1,                 # connect(vs1, derivativeLag.u)
        transferFunction.u ~ derivativeLag.y,  # connect(derivativeLag.y, transferFunction.u)
        simpleLagLim.u ~ transferFunction.y,   # connect(simpleLagLim.u, transferFunction.y)
    ]
    System(eqs, t, vars, pars; name, systems, guesses = Dict(vs1 => 1.0, Vref => 0.0))
end
