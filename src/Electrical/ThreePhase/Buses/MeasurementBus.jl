# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Buses/MeasurementBus.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Three-phase power measurement to be inserted in series: the three input pins p4, p5, p6 are connected to the
# three output pins p1, p2, p3 inside the model (`connect(p4, p1)`, ..., the form of SoftPMU's `connect(p, n)`), so
# each phase is electrically transparent, and the six active/reactive powers flowing through it are reported both
# in W/var (`Pa`..`Qc`, public variables, hence columns of the OpenModelica result) and in per unit of the SYSTEM
# base as the six `RealOutput`s `pa`..`qc` = `Pa/S_b` (plain variables here, as every causal port in the port).
# Omitted: graphical annotations, the `unit = "1"` of the outputs.
# Quirk reproduced (F-96): the three reactive expressions are the NEGATIVE of the three active ones'
# convention. `Pa = -(p1.vr*p1.ir + p1.vi*p1.ii)*S_p` is the active power towards the load, because p1 is the
# output pin, but `Qa = -(p1.vr*p1.ii - p1.vi*p1.ir)*S_p` evaluates to `+(vi*ir - vr*ii)*S_p` at that same pin,
# i.e. MINUS the reactive power towards the load: a load of 255 kW + j158 kvar reads `Pa = 255000` and
# `Qa = -158000`. `ThreePhase.Buses.InfiniteBus` carries the same pair of expressions and the same inconsistency.

@component function MeasurementBus(; name, S_b = 100e6, fn = 50)
    @named base = ThreePhaseComponent(; S_b)
    @unpack S_b, S_p = base
    systems = @named begin
        p1 = PwPin()
        p2 = PwPin()
        p3 = PwPin()
        p4 = PwPin()
        p5 = PwPin()
        p6 = PwPin()
    end
    vars = @variables begin
        Pa(t), [description = "Active power supplied in phase a (W)"]
        Qa(t), [description = "Reactive power supplied in phase a (var)"]
        Pb(t), [description = "Active power supplied in phase b (W)"]
        Qb(t), [description = "Reactive power supplied in phase b (var)"]
        Pc(t), [description = "Active power supplied in phase c (W)"]
        Qc(t), [description = "Reactive power supplied in phase c (var)"]
        pa(t), [description = "Active power of phase a (pu, system base)"]
        pb(t), [description = "Active power of phase b (pu, system base)"]
        pc(t), [description = "Active power of phase c (pu, system base)"]
        qa(t), [description = "Reactive power of phase a (pu, system base)"]
        qb(t), [description = "Reactive power of phase b (pu, system base)"]
        qc(t), [description = "Reactive power of phase c (pu, system base)"]
    end
    eqs = Equation[
        pa ~ Pa / S_b,
        pb ~ Pb / S_b,
        pc ~ Pc / S_b,
        qa ~ Qa / S_b,
        qb ~ Qb / S_b,
        qc ~ Qc / S_b,
        Pa ~ -(p1.vr * p1.ir + p1.vi * p1.ii) * S_p,
        Qa ~ -(p1.vr * p1.ii - p1.vi * p1.ir) * S_p,   # sic, see header (F-96)
        Pb ~ -(p2.vr * p2.ir + p2.vi * p2.ii) * S_p,
        Qb ~ -(p2.vr * p2.ii - p2.vi * p2.ir) * S_p,
        Pc ~ -(p3.vr * p3.ir + p3.vi * p3.ii) * S_p,
        Qc ~ -(p3.vr * p3.ii - p3.vi * p3.ir) * S_p,
        connect(p4, p1),
        connect(p5, p2),
        connect(p6, p3),
    ]
    extend(System(eqs, t, vars, []; name, systems), base)
end
