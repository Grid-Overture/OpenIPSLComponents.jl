# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Buses/Bus.mo (+ Electrical/Essentials/pfComponent.mo, flattened)
# Omitted: graphical annotations, displayPF, angleDisplay, and the pfComponent parameters that Bus disables
# (S_b, V_b, fn, P_0, Q_0). S_b, fn (pfComponent's outer SystemBase) and V_b are accepted as keyword arguments and
# ignored: `enableV_b = false` only removes V_b from the Dialog and a modifier may still set it, as
# `Examples.IEEE14.IEEE_14_Buses` does for its fourteen buses (the same reason Interfaces/Generator.jl takes it).
# The pin is instantiated `irreducible` (Julia only, F-30): a bus is a network node and its voltage is an unknown of
# the network, never a quantity the tearing solves symbolically - an elimination whose pivot is the determinant of two
# proportional branch impedances (`SMIB`'s two lines with the same R and X) divides by zero.

@component function Bus(; name, v_0 = 1, angle_0 = 0, S_b = 100e6, V_b = 400e3, fn = 50)   # S_b, V_b, fn: unused here
    pars = @parameters begin
        v_0 = v_0, [description = "Initial voltage magnitude (pu)"]
        angle_0 = angle_0, [description = "Initial voltage angle (rad)"]
    end
    systems = @named begin
        p = PwPin(; irreducible = true)
    end
    vars = @variables begin
        v(t), [guess = v_0, description = "Bus voltage magnitude (pu)"]
        angle(t), [guess = angle_0, description = "Bus voltage angle (rad)"]
    end
    eqs = Equation[
        v ~ sqrt(p.vr^2 + p.vi^2),
        angle ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
        p.ir ~ 0,
        p.ii ~ 0,
    ]
    # p(vr(start = v_0*cos(angle_0)), vi(start = v_0*sin(angle_0)))
    System(eqs, t, vars, pars; name, systems,
        guesses = Dict(p.vr => v_0 * cos(angle_0), p.vi => v_0 * sin(angle_0)))
end
