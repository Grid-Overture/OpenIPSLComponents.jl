# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSSE/Load_variation.mo (extends BaseClasses/baseLoad.mo, the PSSE one: PSSE_baseLoad.jl)
# PSS/E load with a variation d_P (pu) during [t1, t1 + d_t): the window is the discrete variable `on` switched by two
# discrete events with imperative affects and a DAE re-initialization (PQvar, F-15); with d_t <= 0 the window is empty
# (the .mo condition is never true) and no event is registered (SMIB's `constantLoad`, d_t = 0). PF and d_Q are the
# protected parameters, computed before `@parameters` (`if q0 <= eps` decided in Julia). The power-balance equations
# are literal (Load.jl). Omitted: graphical annotations.

@component function Load_variation(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        S_p = complex(P_0, Q_0), S_i = complex(0.0, 0.0), S_y = complex(0.0, 0.0), a = complex(1.0, 0.0),
        b = complex(0.0, 1.0), PQBRAK = 0.7, characteristic = 1, d_P, t1, d_t)
    d_P, t1, d_t = float.((d_P, t1, d_t))
    @named base = PSSE_baseLoad(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, S_p, S_i, S_y, a, b, PQBRAK, characteristic)
    @unpack v, kP, kI, p, S_P_re, S_P_im, S_I_re, S_I_im, S_Y_re, S_Y_im = base
    p0n, q0n = ModelingToolkit.getdefault(base.p0), ModelingToolkit.getdefault(base.q0)
    PF = q0n <= Modelica.Constants.eps ? 1.0 : p0n / q0n
    d_Q = (p0n + d_P) / PF - q0n
    window = d_t > 0   # decided before @parameters rebinds d_t (F-22)
    pars = @parameters begin
        d_P = d_P, [description = "Active load variation (pu)"]
        t1 = t1, [description = "Time of load variation (s)"]
        d_t = d_t, [description = "Time duration of load variation (s)"]
        PF = PF, [description = "Ratio between active and reactive power (not power factor)"]
        d_Q = d_Q, [description = "Reactive load variation (pu)"]
    end
    disc = @discretes begin
        on(t) = 0
    end
    eqs = Equation[
        kI * S_I_re * v + S_Y_re * v^2 + kP * (S_P_re + on * d_P) ~ p.vr * p.ir + p.vi * p.ii,
        kI * S_I_im * v + S_Y_im * v^2 + kP * (S_P_im + on * d_Q) ~ (-p.vr * p.ii) + p.vi * p.ir,
    ]
    switch(tev, value) = SymbolicDiscreteCallback(t == tev,
        ImperativeAffect((m, o, ctx, integ) -> (; on = value); modified = (; on));
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    kw = window ? (; discrete_events = [switch(t1, 1), switch(t1 + d_t, 0)]) : (;)
    sys = extend(System(eqs, t, [], [pars; disc]; name, kw...), base)
    if window
        @set! sys.tstops = [[t1, t1 + d_t]]   # extend does not merge tstops (F-21)
    end
    sys
end
