# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSAT/PQvar.mo (extends BaseClasses/baseLoad.mo)
# Blocks: none. Omitted: graphical annotations.
# The two time windows (`if time >= t_start_1 and time < t_end_1 ... elseif time >= t_start_2 and time < t_end_2`) are
# the discrete variables in1, in2 (1 inside the window), each switched by two discrete events at its bounds with an
# imperative affect and a DAE re-initialization (F-15); window 1 has priority, as in the .mo. Pd, Qd keep OpenIPSL's
# extra division by S_b in the voltage branches (Pd is already in pu). `initial()` handled as in PQ.jl (header).

@component function PQvar(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0, Sn = S_b,
        t_start_1 = 1, t_end_1 = 2, dP1 = 0, dQ1 = 0, t_start_2 = 2, t_end_2 = 3, dP2 = 0, dQ2 = 0,
        Vmax = 1.2, Vmin = 0.8, forcePQ = true)
    @named base = baseLoad(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn)
    @unpack v, P, Q = base
    pars = @parameters begin
        t_start_1 = t_start_1, [description = "Start time of first load variation (s)"]
        t_end_1 = t_end_1, [description = "End time of first load variation (s)"]
        dP1 = dP1, [description = "First active load variation (W)"]
        dQ1 = dQ1, [description = "First reactive load variation (var)"]
        t_start_2 = t_start_2, [description = "Start time of second load variation (s)"]
        t_end_2 = t_end_2, [description = "End time of second load variation (s)"]
        dP2 = dP2, [description = "Second active load variation (W)"]
        dQ2 = dQ2, [description = "Second reactive load variation (var)"]
        Vmax = Vmax, [description = "Maximum voltage (pu)"]
        Vmin = Vmin, [description = "Minimum voltage (pu)"]
    end
    disc = @discretes begin
        in1(t) = 0
        in2(t) = 0
    end
    vars = @variables begin
        Pd(t), [guess = P_0 / S_b, description = "Active power demand (pu)"]
        Qd(t), [guess = Q_0 / S_b, description = "Reactive power demand (pu)"]
    end
    eqs = forcePQ ? Equation[
        P ~ Pd,
        Q ~ Qd,
    ] : Equation[
        P ~ ifelse(v > Vmax, Pd * v^2 / (Vmax^2) / S_b, ifelse(v < Vmin, Pd * v^2 / Vmin^2 / S_b, Pd)),
        Q ~ ifelse(v > Vmax, Qd * v^2 / (Vmax^2) / S_b, ifelse(v < Vmin, Qd * v^2 / (Vmin^2) / S_b, Qd)),
    ]
    append!(eqs, Equation[
        Pd ~ ifelse(in1 == 1, (P_0 + dP1) / S_b, ifelse(in2 == 1, (P_0 + dP2) / S_b, P_0 / S_b)),
        Qd ~ ifelse(in1 == 1, (Q_0 + dQ1) / S_b, ifelse(in2 == 1, (Q_0 + dQ2) / S_b, Q_0 / S_b)),
    ])
    switch(flag, tev, value) = SymbolicDiscreteCallback(t == tev,
        flag == :in1 ? ImperativeAffect((m, o, ctx, integ) -> (; in1 = value); modified = (; in1)) :
                       ImperativeAffect((m, o, ctx, integ) -> (; in2 = value); modified = (; in2));
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    events = [switch(:in1, t_start_1, 1), switch(:in1, t_end_1, 0), switch(:in2, t_start_2, 1), switch(:in2, t_end_2, 0)]
    sys = extend(System(eqs, t, vars, [pars; disc]; name, discrete_events = events), base)
    @set! sys.tstops = [[t_start_1, t_end_1, t_start_2, t_end_2]]   # extend does not merge tstops (F-21)
    sys
end
