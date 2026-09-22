# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Buses/BusExt.mo
# Bus with arrays of pins representing the same node. ModelingToolkit cannot name a subsystem `p[1]`: the pins are the
# subsystems p_1 … p_np and n_1 … n_nn (OpenModelica writes `busExt.p[1].vr`; a Test that compares them uses `rename`
# in the harness). The pins are joined with `connect` as in the .mo (`connect(p[1], p[i])`, `connect(n[1], n[i])`,
# `connect(p[1], n[1])`); v and angle are read from p[1], else n[1], else 0. S_b (outer SystemBase) and fn are accepted
# and unused.
# Two Julia-only annotations, neither of which changes an equation (batch 5, F-52):
#  * the pins are `irreducible`, as `Bus`'s is (F-30): a bus is a network node and its voltage must stay an unknown
#    of the network instead of being solved symbolically by the tearing.
#  * every pin voltage carries the `guess` `vr0 = v_0 cos(angle_0)`, `vi0 = v_0 sin(angle_0)` - the two protected
#    parameters `BusExt.mo` computes and then never uses (no pin of the .mo has a `start` modifier). OpenModelica
#    reaches the operating point from the default zeros with three homotopy steps; ModelingToolkit's exact Newton
#    does not, and `Examples.SevenBus.Network` converged to a collapsed-voltage root (buses at 0.06-0.23 pu instead
#    of 1.0695) with every solver tried until the guesses were attached.
# Omitted: graphical annotations.

@component function BusExt(; name, np = 0, nn = 0, v_0 = 1, angle_0 = 0, V_b = 130e3, S_b = 100e6, fn = 50)
    v_0, angle_0, V_b, S_b = float.((v_0, angle_0, V_b, S_b))
    vr0, vi0 = v_0 * cos(angle_0), v_0 * sin(angle_0)   # the .mo's protected parameters
    pars = @parameters begin
        v_0 = v_0, [description = "Initial voltage magnitude (pu)"]
        angle_0 = angle_0, [description = "Initial voltage angle (rad)"]
        V_b = V_b, [description = "Base voltage (V)"]
        S_b = S_b, [description = "System base power (VA)"]
    end
    # only the reference pin is irreducible: the others are joined to it by `connect` and are its aliases, and
    # marking them too leaves those equalities as extra equations (`The system is unbalanced`)
    ps = [PwPin(; name = Symbol("p_", i), irreducible = (i == 1)) for i in 1:np]
    ns = [PwPin(; name = Symbol("n_", i), irreducible = (i == 1 && np == 0)) for i in 1:nn]
    guesses = Dict{Any, Any}()
    for pin in [ps; ns]
        guesses[pin.vr] = vr0
        guesses[pin.vi] = vi0
    end
    vars = @variables begin
        v(t), [guess = v_0, description = "Bus voltage magnitude (pu)"]
        angle(t), [guess = angle_0, description = "Bus voltage angle (rad)"]
    end
    eqs = Equation[]
    for i in 2:np
        push!(eqs, connect(ps[1], ps[i]))
    end
    for i in 2:nn
        push!(eqs, connect(ns[1], ns[i]))
    end
    np > 0 && nn > 0 && push!(eqs, connect(ps[1], ns[1]))
    ref = np > 0 ? ps[1] : nn > 0 ? ns[1] : nothing
    if ref === nothing
        push!(eqs, v ~ 0, angle ~ 0)
    else
        push!(eqs, v ~ sqrt(ref.vr^2 + ref.vi^2), angle ~ atan(ref.vi, ref.vr))   # atan2(vi, vr)
    end
    System(eqs, t, vars, pars; name, systems = [ps; ns], guesses)
end
