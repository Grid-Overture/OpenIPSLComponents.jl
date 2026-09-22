# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/TG/TGTypeII.mo, blocks as subsystems:
#   const_             Modelica.Blocks.Sources.Constant (k = wref)                         `const` in the .mo
#   add1               Modelica.Blocks.Math.Add (k2 = -1)                                  wref - w
#   gain1              Modelica.Blocks.Math.Gain (k = 1/Ro)
#   transferFunction1  Modelica.Blocks.Continuous.TransferFunction (a = {Ts, 1}, b = {T3, 1}), MSL's default NoInit
#   add2               Modelica.Blocks.Math.Add                                            pm0 + transferFunction1.y
#   limiter1           Modelica.Blocks.Nonlinear.Limiter (uMax = pmax, uMin = pmin)        -> pm
# `outer SysData` is the keyword argument S_b (batch-0 decision; the .mo declares `S_b = 100e6` with the dialog flag).
# `Ro = R*S_b/Sn`, `pmax = pmax0*Sn/S_b`, `pmin = pmin0*Sn/S_b` and the coefficient vectors are Julia arithmetic
# before `@parameters` (F-22, point 1). The RealInput/RealOutput ports pm0, w, pm are plain variables.
# `transferFunction1` keeps MSL's `NoInit`, so its state has only the guess `x_start = 0` and the initialization of a
# user is one equation short: the Test supplies it (F-28), as OpenModelica fixes the same start.
# Omitted: graphical annotations.

@component function TGTypeII(; name, wref = 1, R = 0.2, pmax0 = 1, pmin0 = 0, Ts = 0.1, T3 = -0.1, S_b = 100e6,
        Sn = 20e6)
    wref, R, pmax0, pmin0, Ts, T3, S_b, Sn = float.((wref, R, pmax0, pmin0, Ts, T3, S_b, Sn))   # F-21
    Ro = R * S_b / Sn
    pmax = pmax0 * Sn / S_b
    pmin = pmin0 * Sn / S_b
    tf_a, tf_b = [Ts, 1.0], [T3, 1.0]
    pars = @parameters begin
        wref = wref, [description = "Reference speed (pu)"]
        R = R, [description = "Droop (pu)"]
        pmax0 = pmax0, [description = "Maximum turbine output (pu)"]
        pmin0 = pmin0, [description = "Minimum turbine output (pu)"]
        Ts = Ts, [description = "Governor Time constant (s)"]
        T3 = T3, [description = "Transient gain time constant (s)"]
        S_b = S_b, [description = "System base power (VA)"]
        Sn = Sn, [description = "Nominal power (VA)"]
        Ro = Ro, [description = "R*S_b/Sn"]
        pmax = pmax, [description = "pmax0*Sn/S_b"]
        pmin = pmin, [description = "pmin0*Sn/S_b"]
    end
    systems = @named begin
        add1 = Add(; k2 = -1)
        transferFunction1 = TransferFunction(; a = tf_a, b = tf_b)
        gain1 = Gain(; k = 1 / Ro)
        const_ = Constant(; k = wref)
        add2 = Add()
        limiter1 = Limiter(; uMax = pmax, uMin = pmin)
    end
    vars = @variables begin
        pm0(t), [description = "Initial mechanical power (pu)"]
        pm(t), [description = "Mechanical power (pu)"]
        w(t), [description = "Rotor speed (pu)"]
    end
    eqs = Equation[
        add2.u1 ~ pm0,                      # connect(add2.u1, pm0)
        add1.u1 ~ const_.y,                 # connect(add1.u1, const.y)
        add1.u2 ~ w,                        # connect(w, add1.u2)
        add2.u2 ~ transferFunction1.y,      # connect(add2.u2, transferFunction1.y)
        transferFunction1.u ~ gain1.y,      # connect(gain1.y, transferFunction1.u)
        gain1.u ~ add1.y,                   # connect(add1.y, gain1.u)
        limiter1.u ~ add2.y,                # connect(add2.y, limiter1.u)
        pm ~ limiter1.y,                    # connect(limiter1.y, pm)
    ]
    System(eqs, t, vars, pars; name, systems, guesses = Dict(w => 1.0, pm0 => 0.0, pm => 0.0))
end
