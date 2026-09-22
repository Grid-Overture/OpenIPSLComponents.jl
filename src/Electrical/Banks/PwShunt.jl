# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Banks/PwShunt.mo: thyristor-controlled shunt reactor/capacitor.
# Ports: the PwPin `p` and the RealInput `Q` (a plain variable). Omitted: graphical annotations.

# The `if Q >= 0` is over an *input*, and the two branches are not a coefficient change but two different sets of
# equations for the same unknowns (c, l, i, anglei and the two pin currents). Each branch is written as one
# `ifelse` per equation, which is the same algebraic system in both modes, and the crossing Q = 0 is registered as
# a continuous event without affect so that the integrator steps exactly onto it (rule 6.3: a structure-changing
# `if` on a signal is a blend, not a discrete).
#
# **Julia-only deviation (F-93).** The .mo gives the pin current implicitly, by
# `i = sqrt(p.ir^2 + p.ii^2)` and `anglei = atan2(p.ii, p.ir)` next to the branch equations for `i` and `anglei`.
# Those two are written here in their exact inverse, `p.ir = i*cos(anglei)` and `p.ii = i*sin(anglei)`, which is
# what OpenModelica's own symbolic solver produces and is equivalent for `i >= 0` - which the .mo's own
# `i = sqrt(...)` guarantees. The reason is not style: the implicit pair is undefined at `i = 0`, where `atan2`
# has no value, and `i` is exactly zero whenever `Q` crosses zero, which the model's only user (`Banks.PSSE.SVC`)
# does four times in a ten-second run. Written implicitly, `mtkcompile` keeps the 2x2 residual, its Jacobian
# determinant is `1/i`, and the solve goes unstable at the first crossing (t = 0.149 s in the SVC Test, under
# both `Rodas5P` and `FBDF`). Written explicitly the current goes through zero continuously, as it should.
# One consequence to note: the .mo's `anglei = atan2(...)` constrains the angle to (-pi, pi], and the branch
# equation `anglei = anglev +/- pi/2` does not, so the two forms differ when the bus angle is beyond +/- pi/2.
# The .mo is over-determined there and OpenModelica resolves it its own way; no network of this port reaches it.
@component function PwShunt(; name, fn = 50)
    fn = float(fn)
    pars = @parameters begin
        fn = fn, [description = "Frequency rating (Hz)"]
    end
    systems = @named begin
        p = PwPin()
    end
    vars = @variables begin
        Q(t), [description = "Reactive power produced by the shunt (pu)"]
        c(t), [description = "Capacitance"]
        l(t), [description = "Inductance"]
        v(t), [guess = 1.0]
        anglev(t), [guess = 0.0]
        i(t)
        anglei(t)
    end
    w = 2 * pi * fn   # C.pi of the .mo
    # Modelica keeps only the equations of the branch the `if` selects; an `ifelse` evaluates both sides, and the
    # inactive one here divides by zero - `v^2/(w*(-Q))` at Q = 0 and `v/(w*l)` whenever l = 0, which is the whole
    # `Q >= 0` branch. The Infs reach no equation, but they do reach the Jacobian, where `Inf * 0` is `NaN`. Each
    # dead denominator is therefore floored to a value it never takes in its own live branch.
    Qmag = max(abs(Q), 1e-12)
    eqs = Equation[
        v ~ sqrt(p.vr^2 + p.vi^2),
        anglev ~ atan(p.vi, p.vr),
        p.ir ~ i * cos(anglei),   # the .mo's `i = sqrt(p.ir^2 + p.ii^2)` ...
        p.ii ~ i * sin(anglei),   # ... and `anglei = atan2(p.ii, p.ir)`, inverted (F-93)
        c ~ ifelse(Q >= 0, Q / (v^2 * w), 0),
        l ~ ifelse(Q >= 0, 0, v^2 / (w * Qmag)),
        anglei ~ anglev + ifelse(Q >= 0, pi / 2, -pi / 2),
        i ~ ifelse(Q >= 0, v * w * c, v / (w * max(l, 1e-12))),
    ]
    System(eqs, t, vars, pars; name, systems,
        continuous_events = [SymbolicContinuousCallback([Q ~ 0], nothing)])
end
