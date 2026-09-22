# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Buses/Bus_3Ph.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Omitted: graphical annotations. The protected matrix `Vin` is an alias of the pins and is written inline.
# Pins `irreducible` (Julia only, F-30), as `Bus_1Ph`. `IEEE4` passes `angle_A = -30, angle_B = -150, angle_C = 90`
# and `IEEE13` +-120 in radians (F-79): they are start values only and are copied as given.

@component function Bus_3Ph(; name, S_b = 100e6, fn = 50, V_A = 1, V_B = 1, V_C = 1,
        angle_A = 0, angle_B = -2pi / 3, angle_C = 2pi / 3)
    @named base = ThreePhaseComponent(; S_b)
    n = (; V_A = float(V_A), V_B = float(V_B), V_C = float(V_C),
        angle_A = float(angle_A), angle_B = float(angle_B), angle_C = float(angle_C))
    pars = @parameters begin
        V_A = n.V_A, [description = "Voltage magnitude for phase A (pu)"]
        V_B = n.V_B, [description = "Voltage magnitude for phase B (pu)"]
        V_C = n.V_C, [description = "Voltage magnitude for phase C (pu)"]
        angle_A = n.angle_A, [description = "Voltage angle for phase A (rad)"]
        angle_B = n.angle_B, [description = "Voltage angle for phase B (rad)"]
        angle_C = n.angle_C, [description = "Voltage angle for phase C (rad)"]
    end
    systems = @named begin
        p1 = PwPin(; irreducible = true)
        p2 = PwPin(; irreducible = true)
        p3 = PwPin(; irreducible = true)
    end
    vars = @variables begin
        Va(t), [guess = n.V_A, description = "Bus voltage magnitude for phase A (pu)"]
        angle_a(t), [guess = n.angle_A, description = "Bus voltage angle for phase A (rad)"]
        Vb(t), [guess = n.V_B, description = "Bus voltage magnitude for phase B (pu)"]
        angle_b(t), [guess = n.angle_B, description = "Bus voltage angle for phase B (rad)"]
        Vc(t), [guess = n.V_C, description = "Bus voltage magnitude for phase C (pu)"]
        angle_c(t), [guess = n.angle_C, description = "Bus voltage angle for phase C (rad)"]
    end
    eqs = Equation[
        Va ~ sqrt(p1.vr^2 + p1.vi^2),
        angle_a ~ atan(p1.vi, p1.vr),
        Vb ~ sqrt(p2.vr^2 + p2.vi^2),
        angle_b ~ atan(p2.vi, p2.vr),
        Vc ~ sqrt(p3.vr^2 + p3.vi^2),
        angle_c ~ atan(p3.vi, p3.vr),
        p1.ir ~ 0,
        p1.ii ~ 0,
        p2.ir ~ 0,
        p2.ii ~ 0,
        p3.ir ~ 0,
        p3.ii ~ 0,
    ]
    extend(System(eqs, t, vars, pars; name, systems,
        guesses = Dict(p1.vr => n.V_A * cos(n.angle_A), p1.vi => n.V_A * sin(n.angle_A),
            p2.vr => n.V_B * cos(n.angle_B), p2.vi => n.V_B * sin(n.angle_B),
            p3.vr => n.V_C * cos(n.angle_C), p3.vi => n.V_C * sin(n.angle_C))), base)
end
