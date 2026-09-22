# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Buses/Bus_1Ph.mo (extends ThreePhase/ThreePhaseComponent.mo)
# Omitted: graphical annotations. The protected matrix `Vin = [p1.vr, p1.vi]` is an alias of the pin and is written
# inline. The pin is instantiated `irreducible` (Julia only, F-30), as `Buses/Bus.jl`: a bus is a network node and
# its voltage is an unknown of the network, never a quantity the tearing solves symbolically - `IEEE13` has
# `LRG60_632` and `L632_671` in series with identical parameters, the shape whose elimination pivot is exactly zero.

@component function Bus_1Ph(; name, S_b = 100e6, fn = 50, V_1 = 1, angle_1 = 0)
    @named base = ThreePhaseComponent(; S_b)
    n = (; V_1 = float(V_1), angle_1 = float(angle_1))   # F-21, F-22 (1): numbers for the guesses
    pars = @parameters begin
        V_1 = n.V_1, [description = "Voltage magnitude for phase 1 (pu)"]
        angle_1 = n.angle_1, [description = "Voltage angle for phase 1 (rad)"]
    end
    systems = @named begin
        p1 = PwPin(; irreducible = true)
    end
    vars = @variables begin
        V1(t), [guess = n.V_1, description = "Bus voltage magnitude for phase 1 (pu)"]
        angle1(t), [guess = n.angle_1, description = "Bus voltage angle for phase 1 (rad)"]
    end
    eqs = Equation[
        V1 ~ sqrt(p1.vr^2 + p1.vi^2),
        angle1 ~ atan(p1.vi, p1.vr),   # atan2(Vin[1, 2], Vin[1, 1])
        p1.ir ~ 0,
        p1.ii ~ 0,
    ]
    # p1(vr(start = V_1*cos(angle_1)), vi(start = V_1*sin(angle_1)))
    extend(System(eqs, t, vars, pars; name, systems,
        guesses = Dict(p1.vr => n.V_1 * cos(n.angle_1), p1.vi => n.V_1 * sin(n.angle_1))), base)
end
