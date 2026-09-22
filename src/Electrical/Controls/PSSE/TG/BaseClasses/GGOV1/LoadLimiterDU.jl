# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/LoadLimiterDU.mo (model)
# Twin of LoadLimiter.jl. The three differences the `.mo` has, all replicated: `s6` initializes with
# `Init.InitialState` instead of `InitialOutput` (the same equation `y = y_start` for an Integrator, whose state is
# its output), an extra `limiter = Limiter(Vmax, Vmin)` sits between `s6.y` and `LoadlimiterPI.u1`, and `diff` is
# wired the other way round (`tlim.y -> diff.u1`, `TEXM -> diff.u2`, `diff.y -> KPLOAD.u`, same graph).
# Omitted: graphical annotations.

@component function LoadLimiterDU(; name, Kturb = 1.5, Kpload = 2, Kiload = 0.67, Dm = 0, Wfnl = 0.2, Vmax = 1,
        Vmin = 0.15)
    Kturb, Kpload, Kiload, Dm, Wfnl, Vmax, Vmin = float.((Kturb, Kpload, Kiload, Dm, Wfnl, Vmax, Vmin))
    n = (; Kturb, Kpload, Kiload, Dm, Wfnl, Vmax, Vmin)
    pars = @parameters begin
        Kturb = Kturb, [description = "Turbine gain"]
        Kpload = Kpload, [description = "Load limiter proportional gain for PI controller"]
        Kiload = Kiload, [description = "Load limiter integral gain for PI controller"]
        Dm = Dm, [description = "Mechanical damping coefficient"]
        Wfnl = Wfnl, [description = "No load fuel flow"]
        Vmax = Vmax, [description = "Maximum valve position limit"]
        Vmin = Vmin, [description = "Minimum valve position limit"]
        Pmech0, [guess = 1.0]
        s60, [guess = 1.0]
        fsr0, [guess = 1.0]
    end
    Gain_ = Gain(; name = :Gain, k = n.Kiload)   # the .mo instance is named `Gain`
    systems = @named begin
        KPLOAD = Gain(; k = n.Kpload)
        s6 = Integrator(; k = 1, y_start = s60, initType = :InitialState)
        LoadlimiterPI = Add()
        diff = Add(; k2 = -1)
        gain = Gain(; k = 1 / n.Kturb)
        maxLimiter = Limiter(; uMax = 1, uMin = -Modelica.Constants.inf)
        tlim = Add()
        const_ = Constant(; k = n.Wfnl)
        limiter = Limiter(; uMax = n.Vmax, uMin = n.Vmin)
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
        KPLOAD.y ~ LoadlimiterPI.u2,    # connect(KPLOAD.y, LoadlimiterPI.u2)
        LoadlimiterPI.y ~ maxLimiter.u, # connect(LoadlimiterPI.y, maxLimiter.u)
        maxLimiter.y ~ FSRT,            # connect(maxLimiter.y, FSRT)
        gain.u ~ LDREF,                 # connect(gain.u, LDREF)
        const_.y ~ tlim.u1,             # connect(const.y, tlim.u1)
        s6.u ~ Gain_.y,                 # connect(s6.u, Gain.y)
        Gain_.u ~ diff.y,               # connect(Gain.u, diff.y)
        limiter.u ~ s6.y,               # connect(limiter.u, s6.y)
        limiter.y ~ LoadlimiterPI.u1,   # connect(limiter.y, LoadlimiterPI.u1)
        tlim.y ~ diff.u1,               # connect(tlim.y, diff.u1)
        TEXM ~ diff.u2,                 # connect(TEXM, diff.u2)
        diff.y ~ KPLOAD.u,              # connect(diff.y, KPLOAD.u)
    ]
    System(eqs, t, vars, pars; name, systems,
        initialization_eqs = [Pmech0 ~ PELEC, s60 ~ fsr0, fsr0 ~ (Pmech0 + Dm) / Kturb + Wfnl],
        initial_conditions = Dict(Pmech0 => missing, s60 => missing, fsr0 => missing))
end
