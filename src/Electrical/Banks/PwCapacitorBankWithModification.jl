# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Banks/PwCapacitorBankWithModification.mo
# Literal, as PwCapacitorBank.jl: the pin voltage is written explicitly from the current, V = I/(G + jB), and with
# G = B = 0 the division by G^2 + B^2 is OpenIPSL's. Unlike that model, `nsteps` IS used here: the number of
# elements in service is `nt`, an Integer that changes once, at `t1`.
# Omitted: graphical annotations.

# `if time > t1 then nt = nsteps + nmod else nt = nsteps` is a jump in time, so it is a discrete event with DAE
# re-initialization and a `tstop` at t1, never a bare `ifelse` on `t` (rule 6.3, F-24/F-25), following
# Load_variation.jl. `nt` is the discrete memory and `G`/`B` are read from it, so the admittance of the branch
# changes exactly at the event.
@component function PwCapacitorBankWithModification(; name, nsteps, Go, Bo, t1, nmod)
    Go, Bo, t1 = float.((Go, Bo, t1))
    nt0, nt1, t1n = float(nsteps), float(nsteps + nmod), t1   # numeric copies for the affect and the tstop (F-22)
    pars = @parameters begin
        nsteps = nsteps, [description = "Number of steps"]
        Go = Go, [description = "Active power losses in each element (pu)"]
        Bo = Bo, [description = "Reactive power in each element (pu)"]
        t1 = t1, [description = "Time for bank Modification (s)"]
        nmod = nmod, [description = "Number of step to switch on/off (+/-)"]
    end
    disc = @discretes begin
        nt(t) = nt0
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        G(t)
        B(t)
    end
    eqs = Equation[
        G ~ nt * Go,
        B ~ nt * Bo,
        p.vr ~ (p.ir * G + p.ii * B) / (G * G + B * B),
        p.vi ~ ((-p.ir * B) + p.ii * G) / (G * G + B * B),
    ]
    switch = SymbolicDiscreteCallback(t == t1n,
        ImperativeAffect((m, o, ctx, integ) -> (; nt = nt1); modified = (; nt));
        reinitializealg = OrdinaryDiffEqCore.BrownFullBasicInit())
    sys = System(eqs, t, vars, [pars; disc]; name, systems, discrete_events = [switch])
    @set! sys.tstops = [[t1n]]
    sys
end
