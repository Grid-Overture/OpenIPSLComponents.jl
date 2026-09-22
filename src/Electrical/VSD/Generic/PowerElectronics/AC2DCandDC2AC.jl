# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/VSD/Generic/PowerElectronics/AC2DCandDC2AC.mo
# extends: Electrical/Essentials/pfComponent.mo with `enableangle_0 = enablev_0 = enableS_b = true` (and `V_b`,
# which is used by `Vd0` and `Vmotor`, so it stays a keyword argument).
# A phasor voltage-source converter: a grid pin `p`, a motor pin `n`, and between them the DC link built from the
# mini-MSL analog subset of phase 2 --
#   Voltage(SignalVoltage, v = Vd0) - Resistor(Rdc) - Inductor(Ldc) - switch(IdealOpeningSwitch) - Capacitor(Cdc),
#   with signalCurrent(i = Ii) across the capacitor and `ground` at its negative node.
# **Three things this file must get right, each with its own finding:**
# 1. `Resistor`, `Inductor` and `Capacitor` are instances named exactly like their classes, which they shadow
#    inside the function: the classes are reached qualified (`OpenIPSLComponents.Resistor`, F-61).
# 2. `switch` owns the continuous event of its mode change (F-61, rule 6.3) and roots it on its own `control`
#    variable, which this model drives with the `.mo`'s quantity `Resistor.i`; the `.mo`'s
#    `open_circuit_condition = BooleanExpression(Resistor.i < 0)` is kept as a block because the OpenModelica CSV
#    carries its column. With `Cdc = 1e-6` (the `IEEEMicrogrid` value) a bare `ifelse` on that condition returns
#    `Unstable`.
# 3. The AC side. The `.mo` writes `P = p.vr*p.ir + p.vi*p.ii`, `Q = -p.vr*p.ii + p.vi*p.ir`, `Q = 0` and
#    `P*S_b = Pdc`, which leaves the two pin currents implicit in a pair of bilinear equations whose 2x2 matrix is
#    singular at a zero pin voltage -- the reason OpenModelica cannot initialize `IEEEMicrogrid` at all (F-63).
#    They are written **solved for the currents**, `p.ir = P*p.vr/(p.vr^2 + p.vi^2)`,
#    `p.ii = P*p.vi/(p.vr^2 + p.vi^2)` with `P = Pdc/S_b`, the same relation for `v != 0`. This is the fourth
#    explicit-current deviation of the port (F-16 loads, F-21 `PwLine`, `STATCOM`).
# Motor side, literal including the `cos(0)` / `sin(0)`: `n.vr = Vmotor.y*cos(0)`, `n.vi = Vmotor.y*sin(0)`.
# Initial values: `Vc0 = 2*sqrt(2)*Vmotor0*V_b/m0` with `Vmotor0 = (3*sqrt(3)/(2*pi))*m0`, in which `m0` cancels,
# so `Vc0 = 2*sqrt(2)*(3*sqrt(3)/(2*pi))*V_b`. The capacitor's start is **fixed** and the inductor's is a guess
# (`i(start = Il0 = 0, fixed = false)`), which leaves the component under-determined by one: the case that
# instantiates it supplies the missing condition (F-28).
# Omitted: graphical annotations, the Documentation section.

@component function AC2DCandDC2AC(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0, Rdc = 0.1, Ldc = 0.001, Cdc = 0.02, m0 = 0.1)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0))
    Rdc, Ldc, Cdc, m0 = float.((Rdc, Ldc, Cdc, m0))
    Vmotor0 = (3 * sqrt(3) / (2 * pi)) * m0
    Vc0 = 2 * sqrt(2) * Vmotor0 * V_b / m0
    Il0 = 0.0
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    pars = @parameters begin
        Rdc = Rdc, [description = "DC link resistance (ohm)"]
        Ldc = Ldc, [description = "DC link inductance (H)"]
        Cdc = Cdc, [description = "DC link capacitance (F)"]
        m0 = m0, [description = "Initial PWM Modulation Value"]
    end
    systems = @named begin
        p = PwPin()
        n = PwPin()
        Voltage = SignalVoltage()
        Resistor = OpenIPSLComponents.Resistor(; R = Rdc)          # the instance shadows the class (F-61)
        Inductor = OpenIPSLComponents.Inductor(; L = Ldc, i_start = Il0)
        Capacitor = OpenIPSLComponents.Capacitor(; C = Cdc, v_start = Vc0, v_fixed = true)
        signalCurrent = SignalCurrent()
        ground = Ground()
        Vd0 = RealExpression(; expr = nothing)
        Vs = RealExpression(; expr = nothing)
        Ii = RealExpression(; expr = nothing)
        Pmotor = RealExpression(; expr = nothing)
        Qmotor = RealExpression(; expr = nothing)
        Smotor = RealExpression(; expr = nothing)
        Vmotor = RealExpression(; expr = nothing)
        vr_m = RealExpression(; expr = nothing)
        vi_m = RealExpression(; expr = nothing)
        Capacitor_Voltage = RealExpression(; expr = nothing)
    end
    @named switch = IdealOpeningSwitch(; Ron = 1e-5, Goff = 1e-5)
    @named open_circuit_condition = BooleanExpression(; expr = nothing)
    push!(systems, switch, open_circuit_condition)
    vars = @variables begin
        m_input(t), [description = "PWM modulation index input"]
        Vc(t), [description = "Capacitor voltage output"]
        P(t), [description = "Active Power (pu)"]
        Pdc(t), [description = "DC Circuit Active Power (W)"]
        Q(t), [description = "Reactive Power (pu)"]
        S(t), [description = "Apparent Power (pu)"]
    end
    eqs = Equation[
        # the RealExpression blocks, whose `y` reads variables of this model (F-22)
        Vs.y ~ sqrt(p.vr^2 + p.vi^2),
        Vd0.y ~ 3 * sqrt(6) * Vs.y * V_b / pi,
        Pmotor.y ~ -(n.vr * n.ir + n.vi * n.ii),
        Qmotor.y ~ n.vr * n.ii - n.vi * n.ir,
        Smotor.y ~ sqrt(Pmotor.y^2 + Qmotor.y^2),
        Ii.y ~ Pmotor.y * S_b / Capacitor.v,
        Vmotor.y ~ Capacitor.v * m_input / (2 * sqrt(2) * V_b),
        vr_m.y ~ Vmotor.y * cos(0),
        vi_m.y ~ Vmotor.y * sin(0),
        Capacitor_Voltage.y ~ Capacitor.v,
        # the DC link
        Vd0.y ~ Voltage.v,                       # connect(Vd0.y, Voltage.v)
        connect(Voltage.p, Resistor.p),
        connect(Resistor.n, Inductor.p),
        connect(Inductor.n, switch.p),
        connect(switch.n, Capacitor.p),
        connect(Voltage.n, Capacitor.n),
        connect(switch.n, signalCurrent.p),
        connect(signalCurrent.n, Capacitor.n),
        signalCurrent.i ~ Ii.y,                  # connect(signalCurrent.i, Ii.y)
        connect(ground.p, Capacitor.n),
        # the .mo's `open_circuit_condition = BooleanExpression(y = Resistor.i < 0)` -> `switch.control`.
        # The block's event roots on `control` itself, so the parent hands it `Resistor.i` (F-61, rule 6.4);
        # the Boolean block is kept because the OpenModelica CSV carries its `y` column.
        open_circuit_condition.y ~ ifelse(Resistor.i < 0, 1.0, 0.0),
        switch.control ~ Resistor.i,             # connect(open_circuit_condition.y, switch.control)
        # the AC side: the .mo's four equations, with the two pin currents solved for (see the header)
        Q ~ 0,
        S ~ sqrt(P^2 + Q^2),
        Pdc ~ Vd0.y * Resistor.i,
        P * S_b ~ Pdc,
        p.ir ~ P * p.vr / (p.vr^2 + p.vi^2),
        p.ii ~ P * p.vi / (p.vr^2 + p.vi^2),
        # the motor side
        n.vr ~ vr_m.y,
        n.vi ~ vi_m.y,
        Capacitor_Voltage.y ~ Vc,                # connect(Capacitor_Voltage.y, Vc)
    ]
    extend(System(eqs, t, vars, pars; name, systems), base)
end
