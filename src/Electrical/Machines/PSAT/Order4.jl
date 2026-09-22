# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSAT/Order4.mo (extends BaseClasses/baseMachine.mo with xq0 = xq, vf(start = vf00))
# Fourth-order machine: `extend` over baseMachine.jl; the protected parameters (vf00, e1q0, e1d0) are Julia arithmetic
# on the numbers `psat_machine_init` returns. They are written e1q0, e1d0, vf00 (dependency order) because the .mo
# declares vf00 first although it uses e1q0, which Modelica resolves by declaration-independent binding.
# `e1q` starts from the .mo's `initial equation der(e1q) = 0` (guess + initialization_eqs, F-11); `e1d` has a plain
# `start` that OpenModelica's under-determined initialization fixes, so it is an `initial_conditions` entry rather
# than a metadata default, which a Test can override (F-20; F-54: the OEL Test overrides it).
# Quirk of OpenIPSL 3.1.0 (F-04): the guard `if abs(xq - x1q) < Modelica.Constants.small` selects the *general*
# e1d equation in the degenerate branch and the truncated one otherwise - the two branches are swapped upstream.
# It is transcribed literally; being a relation between parameters, the branch is chosen in Julia (F-50).
# Omitted: graphical annotations.

@component function Order4(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        Sn, Vn, ra, x1d, M, D, xd = 1.9, xq = 1.7, x1q = 0.5, T1d0 = 8, T1q0 = 0.8)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xd, xq, x1q, T1d0, T1q0 =
        float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xd, xq, x1q, T1d0, T1q0))   # F-21
    i0 = psat_machine_init(S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, xq)   # xq0 = xq
    e1q0 = i0.vq0 + ra * i0.iq0 + x1d * i0.id0
    e1d0 = i0.vd0 + ra * i0.id0 - x1q * i0.iq0
    vf00 = i0.V_MBtoSB * (e1q0 + (xd - x1d) * i0.id0)
    # F-50: a relation between parameters is decided here, before @parameters shadows xq and x1q with symbolics
    degenerate = abs(xq - x1q) < Modelica.Constants.small
    @named base = baseMachine(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xq0 = xq)
    @unpack vd, vq, id, iq, vf, vf0, vf_MB = base
    pars = @parameters begin
        xd = xd, [description = "d-axis synchronous reactance (pu)"]
        xq = xq, [description = "q-axis synchronous reactance (pu)"]
        x1q = x1q, [description = "q-axis transient reactance (pu)"]
        T1d0 = T1d0, [description = "d-axis open circuit transient time constant (s)"]
        T1q0 = T1q0, [description = "q-axis open circuit transient time constant (s)"]
        vf00 = vf00, [description = "Initial value (system base)"]
        e1q0 = e1q0, [description = "Initialization"]
        e1d0 = e1d0, [description = "Initialization"]
    end
    vars = @variables begin
        e1q(t), [description = "q-axis transient voltage (pu)"]
        e1d(t), [description = "d-axis transient voltage (pu)"]
    end
    eqs = Equation[
        der(e1q) ~ ((-e1q) - (xd - x1d) * id + vf_MB) / T1d0,
        # if abs(xq - x1q) < Modelica.Constants.small then der(e1d) = ((-e1d) + (xq - x1q)*iq)/T1q0
        # else der(e1d) = (-e1d)/T1q0 (F-04: the branches are swapped in OpenIPSL 3.1.0)
        degenerate ? der(e1d) ~ ((-e1d) + (xq - x1q) * iq) / T1q0 : der(e1d) ~ (-e1d) / T1q0,
        e1q ~ vq + ra * iq + x1d * id,
        e1d ~ vd + ra * id - x1q * iq,
        vf0 ~ vf00,
    ]
    extend(System(eqs, t, vars, pars; name,
            initial_conditions = Dict(e1d => e1d0),
            guesses = Dict(vf => vf00, e1q => e1q0),
            initialization_eqs = [der(e1q) ~ 0]), base)
end
