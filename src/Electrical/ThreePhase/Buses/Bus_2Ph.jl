# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Buses/Bus_2Ph.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Omitted: graphical annotations and the unused `import Modelica.Constants.pi`. The protected matrix `Vin` is an
# alias of the pins and is written inline. Pins `irreducible` (Julia only, F-30), as `Bus_1Ph`.

@component function Bus_2Ph(; name, S_b = 100e6, fn = 50, V_1 = 1, V_2 = 1, angle_1 = 0, angle_2 = -2pi / 3)
    @named base = ThreePhaseComponent(; S_b)
    n = (; V_1 = float(V_1), V_2 = float(V_2), angle_1 = float(angle_1), angle_2 = float(angle_2))
    pars = @parameters begin
        V_1 = n.V_1, [description = "Voltage magnitude for phase 1 (pu)"]
        V_2 = n.V_2, [description = "Voltage magnitude for phase 2 (pu)"]
        angle_1 = n.angle_1, [description = "Voltage angle for phase 1 (rad)"]
        angle_2 = n.angle_2, [description = "Voltage angle for phase 2 (rad)"]
    end
    systems = @named begin
        p1 = PwPin(; irreducible = true)
        p2 = PwPin(; irreducible = true)
    end
    vars = @variables begin
        V1(t), [guess = n.V_1, description = "Bus voltage magnitude for phase 1 (pu)"]
        angle1(t), [guess = n.angle_1, description = "Bus voltage angle for phase 1 (rad)"]
        V2(t), [guess = n.V_2, description = "Bus voltage magnitude for phase 2 (pu)"]
        angle2(t), [guess = n.angle_2, description = "Bus voltage angle for phase 2 (rad)"]
    end
    eqs = Equation[
        V1 ~ sqrt(p1.vr^2 + p1.vi^2),
        angle1 ~ atan(p1.vi, p1.vr),
        V2 ~ sqrt(p2.vr^2 + p2.vi^2),
        angle2 ~ atan(p2.vi, p2.vr),
        p1.ir ~ 0,
        p1.ii ~ 0,
        p2.ir ~ 0,
        p2.ii ~ 0,
    ]
    extend(System(eqs, t, vars, pars; name, systems,
        guesses = Dict(p1.vr => n.V_1 * cos(n.angle_1), p1.vi => n.V_1 * sin(n.angle_1),
            p2.vr => n.V_2 * cos(n.angle_2), p2.vi => n.V_2 * sin(n.angle_2))), base)
end
