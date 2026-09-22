# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/PSS/PSSTypeII.mo, blocks as subsystems:
#   derivativeLag   OpenIPSL.NonElectrical.Continuous.DerivativeLag (K = Kw*Tw, T = Tw, y_start = 0, x_start = 0)
#   imLeadLag       OpenIPSL.NonElectrical.Continuous.LeadLag (K = 1, T1, T2, y_start = 0)
#   imLeadLag1      OpenIPSL.NonElectrical.Continuous.LeadLag (K = 1, T1 = T3, T2 = T4, y_start = 0)
#   limiter         Modelica.Blocks.Nonlinear.Limiter (uMax = vsmax, uMin = vsmin)
# The RealInput/RealOutput ports vSI, vs are plain variables. None of the eight parameters has a default in the .mo,
# so all eight are required keyword arguments. `K = Kw*Tw` is Julia arithmetic before `@parameters` (F-22, point 1).
# Omitted: graphical annotations.

@component function PSSTypeII(; name, vsmax, vsmin, Kw, Tw, T1, T2, T3, T4)
    vsmax, vsmin, Kw, Tw, T1, T2, T3, T4 = float.((vsmax, vsmin, Kw, Tw, T1, T2, T3, T4))   # F-21
    # LeadLag and DerivativeLag decide their degenerate branch in Julia from their numeric time constants (F-50), so
    # they receive numbers, not the symbols `@parameters` rebinds below (F-22, point 1)
    KwTw = Kw * Tw
    T1n, T2n, T3n, T4n, Twn = T1, T2, T3, T4, Tw
    pars = @parameters begin
        vsmax = vsmax, [description = "Max stabilizer output signal (pu)"]
        vsmin = vsmin, [description = "Min stabilizer output signal (pu)"]
        Kw = Kw, [description = "Stabilizer gain (pu/pu)"]
        Tw = Tw, [description = "Wash-out time constant (s)"]
        T1 = T1, [description = "First stabilizer time constant (s)"]
        T2 = T2, [description = "Second stabilizer time constant (s)"]
        T3 = T3, [description = "Third stabilizer time constant (s)"]
        T4 = T4, [description = "Fourth stabilizer time constant (s)"]
    end
    systems = @named begin
        imLeadLag = LeadLag(; K = 1, T1 = T1n, T2 = T2n, y_start = 0)
        imLeadLag1 = LeadLag(; K = 1, T1 = T3n, T2 = T4n, y_start = 0)
        limiter = Limiter(; uMax = vsmax, uMin = vsmin)
        derivativeLag = DerivativeLag(; K = KwTw, T = Twn, y_start = 0, x_start = 0)
    end
    vars = @variables begin
        vSI(t), [description = "PSS input signal"]
        vs(t), [description = "PSS output signal (pu)"]
    end
    eqs = Equation[
        vs ~ limiter.y,                    # connect(vs, limiter.y)
        limiter.u ~ imLeadLag1.y,          # connect(imLeadLag1.y, limiter.u)
        imLeadLag1.u ~ imLeadLag.y,        # connect(imLeadLag.y, imLeadLag1.u)
        derivativeLag.u ~ vSI,             # connect(vSI, derivativeLag.u)
        imLeadLag.u ~ derivativeLag.y,     # connect(derivativeLag.y, imLeadLag.u)
    ]
    System(eqs, t, vars, pars; name, systems, guesses = Dict(vSI => 1.0, vs => 0.0))
end
