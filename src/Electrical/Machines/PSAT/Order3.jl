# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSAT/Order3.mo (extends BaseClasses/baseMachine.mo with xq0 = xq)
# Third-order machine: `extend` over baseMachine.jl; the protected scaling constants, e1q0 and vf00 are computed from
# `psat_machine_init` with the same numbers as the base. `vf(start = vf00)` of the extends modifier is the guess of
# vf; e1q starts from `initial equation der(e1q) = 0` (initialization_eqs) with e1q0 as its guess (F-11). The
# initialization must be solved with an exact Newton iteration (test harness `INIT`, F-26): the default quasi-Newton
# start of the ODE path converges to a spurious high-voltage branch of the network. Omitted: graphical annotations.

@component function Order3(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        Sn, Vn, ra, x1d, M, D, xd, T1d0, xq)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xd, T1d0, xq =
        float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xd, T1d0, xq))   # F-21
    i0 = psat_machine_init(S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, xq)   # xq0 = xq
    K = 1 / (ra^2 + xq * x1d)
    c1 = ra * K
    c2 = x1d * K
    c3 = xq * K
    e1q0 = i0.vq0 + ra * i0.iq0 + x1d * i0.id0
    vf00 = i0.V_MBtoSB * (e1q0 + (xd - x1d) * i0.id0)
    @named base = baseMachine(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xq0 = xq)
    @unpack vd, vq, id, iq, vf, vf0, vf_MB = base
    pars = @parameters begin
        xd = xd, [description = "d-axis synchronous reactance (pu)"]
        T1d0 = T1d0, [description = "d-axis open circuit transient time constant (s)"]
        xq = xq, [description = "q-axis synchronous reactance (pu)"]
        K = K, [description = "a constant for scaling"]
        c1 = c1, [description = "scaled ra"]
        c2 = c2, [description = "scaled x'd"]
        c3 = c3, [description = "scaled xq"]
        vf00 = vf00, [description = "Initial value (system base)"]
        e1q0 = e1q0, [description = "Initialization"]
    end
    vars = @variables begin
        e1q(t), [description = "q-axis transient voltage (pu)"]
    end
    eqs = Equation[
        der(e1q) ~ ((-e1q) - (xd - x1d) * id + vf_MB) / T1d0,
        id ~ (-c1 * vd) - c3 * vq + e1q * c3,
        iq ~ c2 * vd - c1 * vq + e1q * c1,
        vf0 ~ vf00,
    ]
    extend(System(eqs, t, vars, pars; name, guesses = Dict(vf => vf00, e1q => e1q0),
            initialization_eqs = [der(e1q) ~ 0]), base)
end
