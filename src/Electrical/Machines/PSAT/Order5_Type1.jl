# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSAT/Order5_Type1.mo (extends BaseClasses/baseMachine.mo with xq0 = xq, vf(start = vf00))
# Fifth-order machine, type 1: `extend` over baseMachine.jl; the protected parameters are Julia arithmetic on the
# numbers `psat_machine_init` returns, reordered to their dependency order (the .mo declares vf00 before e1q0).
# The three states e1q, e1d, e2d carry a plain `start` and the .mo's `initial equation der = 0` for each of them ->
# `guesses` + `initialization_eqs` (F-11, F-20). `e1d0` and `e2d0` have the same expression (sic, the .mo's own
# duplication, its comment reads "Initialization*"). Omitted: graphical annotations.

@component function Order5_Type1(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        Sn, Vn, ra, x1d, M, D, xd = 1.9, xq = 1.7, x1q = 0.5, T1d0 = 8, T1q0 = 0.8, T2q0 = 0.02)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xd, xq, x1q, T1d0, T1q0, T2q0 =
        float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xd, xq, x1q, T1d0, T1q0, T2q0))   # F-21
    i0 = psat_machine_init(S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, xq)   # xq0 = xq
    e1q0 = i0.vq0 + ra * i0.iq0 + x1d * i0.id0
    e1d0 = i0.vd0 + ra * i0.id0 - x1q * i0.iq0
    e2d0 = i0.vd0 + ra * i0.id0 - x1q * i0.iq0
    vf00 = i0.V_MBtoSB * (e1q0 + (xd - x1d) * i0.id0)
    @named base = baseMachine(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xq0 = xq)
    @unpack vd, vq, id, iq, vf, vf0, vf_MB = base
    pars = @parameters begin
        xd = xd, [description = "d-axis synchronous reactance (pu)"]
        xq = xq, [description = "q-axis synchronous reactance (pu)"]
        x1q = x1q, [description = "q-axis transient reactance (pu)"]
        T1d0 = T1d0, [description = "d-axis open circuit transient time constant (s)"]
        T1q0 = T1q0, [description = "q-axis open circuit transient time constant (s)"]
        T2q0 = T2q0, [description = "q-axis open circuit sub-transient time constant (s)"]
        vf00 = vf00, [description = "Init. val. [pu, SB]"]
        e1q0 = e1q0, [description = "Initialization"]
        e1d0 = e1d0, [description = "Initialization*"]
        e2d0 = e2d0, [description = "Initialization"]
    end
    vars = @variables begin
        e1q(t), [description = "q-axis transient voltage (pu)"]
        e1d(t), [description = "d-axis transient voltage (pu)"]
        e2d(t), [description = "d-axis sub-transient voltage (pu)"]
    end
    eqs = Equation[
        der(e1q) ~ ((-e1q) - (xd - x1d) * id + vf_MB) / T1d0,
        der(e1d) ~ ((-e1d) + (xq - x1q - T2q0 / T1q0 * x1d / x1q * (xq - x1q)) * iq) / T1q0,
        der(e2d) ~ ((-e2d) + e1d + (x1q - x1d + T2q0 / T1q0 * x1d / x1q * (xq - x1q)) * iq) / T2q0,
        e1q ~ vq + ra * iq + x1d * id,
        e2d ~ vd + ra * id - x1q * iq,
        vf0 ~ vf00,
    ]
    extend(System(eqs, t, vars, pars; name,
            guesses = Dict(vf => vf00, e1q => e1q0, e1d => e1d0, e2d => e2d0),
            initialization_eqs = [der(e1q) ~ 0, der(e1d) ~ 0, der(e2d) ~ 0]), base)
end
