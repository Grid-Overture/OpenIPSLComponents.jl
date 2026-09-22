# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/LoadLimiter.mo (model)
# Blocks: KPLOAD = Gain(Kpload), s6 = Integrator(k = 1, y_start = s60, InitialOutput), LoadlimiterPI = Add,
# diff = Add(k2 = -1), gain = Gain(1/Kturb), maxLimiter = Limiter(1, -Modelica.Constants.inf), tlim = Add,
# Gain = Gain(Kiload) (instance `Gain_`: `Gain` is the block's own constructor in Julia), const = Constant(Wfnl)
# (instance `const_`). Ports as plain variables: LDREF, TEXM, PELEC (inputs), FSRT (output).
# `Pmech0`, `s60` and `fsr0` are `fixed = false` and the chain starts at the input PELEC: `missing` parameters with
# their equations in `initialization_eqs` (F-33), `s60` reaching `s6` symbolically (F-38).
# Omitted: graphical annotations.

@component function LoadLimiter(; name, Kturb = 1.5, Kpload = 2, Kiload = 0.67, Dm = 0, Wfnl = 0.2)
    Kturb, Kpload, Kiload, Dm, Wfnl = float.((Kturb, Kpload, Kiload, Dm, Wfnl))
    n = (; Kturb, Kpload, Kiload, Dm, Wfnl)
    pars = @parameters begin
        Kturb = Kturb, [description = "Turbine gain"]
        Kpload = Kpload, [description = "Load limiter proportional gain for PI controller"]
        Kiload = Kiload, [description = "Load limiter integral gain for PI controller"]
        Dm = Dm, [description = "Mechanical damping coefficient"]
        Wfnl = Wfnl, [description = "No load fuel flow"]
        Pmech0, [guess = 1.0]
        s60, [guess = 1.0]
        fsr0, [guess = 1.0]
    end
    Gain_ = Gain(; name = :Gain, k = n.Kiload)   # the .mo instance is named `Gain`
    systems = @named begin
        KPLOAD = Gain(; k = n.Kpload)
        s6 = Integrator(; k = 1, y_start = s60, initType = :InitialOutput)
        LoadlimiterPI = Add()
        diff = Add(; k2 = -1)
        gain = Gain(; k = 1 / n.Kturb)
        maxLimiter = Limiter(; uMax = 1, uMin = -Modelica.Constants.inf)
        tlim = Add()
        const_ = Constant(; k = n.Wfnl)
    end
    push!(systems, Gain_)
    vars = @variables begin
        FSRT(t), [description = "Controller Output"]
        LDREF(t), [description = "Load Limiter reference value (pu)"]
        TEXM(t), [description = "Measured Exhaust Temperature"]
        PELEC(t), [description = "Machine electrical power (pu)"]
    end
    eqs = Equation[
        gain.y ~ tlim.u2,               # connect(gain.y, tlim.u2)
        diff.y ~ KPLOAD.u,              # connect(diff.y, KPLOAD.u)
        KPLOAD.y ~ LoadlimiterPI.u2,    # connect(KPLOAD.y, LoadlimiterPI.u2)
        LoadlimiterPI.y ~ maxLimiter.u, # connect(LoadlimiterPI.y, maxLimiter.u)
        maxLimiter.y ~ FSRT,            # connect(maxLimiter.y, FSRT)
        gain.u ~ LDREF,                 # connect(gain.u, LDREF)
        const_.y ~ tlim.u1,             # connect(const.y, tlim.u1)
        s6.u ~ Gain_.y,                 # connect(s6.u, Gain.y)
        s6.y ~ LoadlimiterPI.u1,        # connect(s6.y, LoadlimiterPI.u1)
        Gain_.u ~ diff.y,               # connect(Gain.u, diff.y)
        diff.u1 ~ tlim.y,               # connect(diff.u1, tlim.y)
        diff.u2 ~ TEXM,                 # connect(diff.u2, TEXM)
    ]
    System(eqs, t, vars, pars; name, systems,
        initialization_eqs = [Pmech0 ~ PELEC, s60 ~ fsr0, fsr0 ~ (Pmech0 + Dm) / Kturb + Wfnl],
        initial_conditions = Dict(Pmech0 => missing, s60 => missing, fsr0 => missing))
end
