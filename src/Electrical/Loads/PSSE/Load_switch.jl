# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSSE/Load_switch.mo (extends BaseClasses/baseLoad.mo, the PSSE one)
# A PSS/E load that is connected only inside [t1, t2) and draws exactly zero current outside it. Omitted:
# graphical annotations.

# What switches is the *structure* of the algebraic system, not a coefficient: in the window the two literal
# power-balance equations of Load.jl hold, and outside it they are replaced by `p.ir = p.ii = 0`. That is written
# as one blend per equation whose mode coefficient `on` is a discrete variable set by two discrete events with
# imperative affects and a DAE re-initialization (rule 6.3, F-15, F-24, F-25): with `on = 1` each equation is the
# .mo's, with `on = 0` it is the pin current pinned to zero. The `tstops` are re-attached after `extend` (F-21).
@component function Load_switch(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0, S_p = complex(P_0, Q_0), S_i = complex(0.0, 0.0), S_y = complex(0.0, 0.0),
        a = complex(1.0, 0.0), b = complex(0.0, 1.0), PQBRAK = 0.7, characteristic = 1, t1, t2)
    t1, t2 = float.((t1, t2))
    @named base = PSSE_baseLoad(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, S_p, S_i, S_y, a, b, PQBRAK, characteristic)
    @unpack v, kP, kI, p, S_P_re, S_P_im, S_I_re, S_I_im, S_Y_re, S_Y_im = base
    on0 = t1 <= 0 < t2 ? 1.0 : 0.0   # the .mo's own condition evaluated at t = 0, before @parameters (F-22)
    pars = @parameters begin
        t1 = t1, [description = "Time of switching on (s)"]
        t2 = t2, [description = "Time of switching off (s)"]
    end
    disc = @discretes begin
        on(t) = on0
    end
    eqs = Equation[
        on * (kI * S_I_re * v + S_Y_re * v^2 + kP * S_P_re - (p.vr * p.ir + p.vi * p.ii)) + (1 - on) * p.ir ~ 0,
        on * (kI * S_I_im * v + S_Y_im * v^2 + kP * S_P_im - ((-p.vr * p.ii) + p.vi * p.ir)) + (1 - on) * p.ii ~ 0,
    ]
    switch(tev, value) = SymbolicDiscreteCallback(t == tev,
        ImperativeAffect((m, o, ctx, integ) -> (; on = value); modified = (; on));
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    sys = extend(System(eqs, t, [], [pars; disc]; name, discrete_events = [switch(t1, 1.0), switch(t2, 0.0)]), base)
    @set! sys.tstops = [[t1, t2]]
    sys
end
