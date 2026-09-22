# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSAT/Order2.mo (extends BaseClasses/baseMachine.mo with xq0 = x1d)
# Second-order machine: `extend` over baseMachine.jl (`@unpack` of the dq variables and the field-voltage ports); the
# protected scaling constants and vf00 are computed from `psat_machine_init` with the same numbers as the base.
# `vf(start = vf00)` of the extends modifier is the guess of vf. Omitted: graphical annotations.

@component function Order2(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        Sn, Vn, ra, x1d, M, D)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D =
        float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D))   # F-21
    i0 = psat_machine_init(S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d)   # xq0 = x1d
    K = 1 / (ra^2 + x1d^2)
    c1 = ra * K
    c2 = x1d * K
    c3 = x1d * K
    vf00 = i0.V_MBtoSB * (i0.vq0 + ra * i0.iq0 + x1d * i0.id0)
    @named base = baseMachine(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xq0 = x1d)
    @unpack vd, vq, id, iq, vf, vf0, vf_MB = base
    pars = @parameters begin
        K = K, [description = "a constant for scaling"]
        c1 = c1, [description = "scaled ra"]
        c2 = c2, [description = "scaled x'd"]
        c3 = c3, [description = "scaled x'd"]
        vf00 = vf00, [description = "Initial value (SB)"]
    end
    eqs = Equation[
        id ~ -c1 * vd - c3 * vq + vf_MB * c3,
        iq ~ c2 * vd - c1 * vq + vf_MB * c1,
        vf0 ~ vf00,
    ]
    extend(System(eqs, t, [], pars; name, guesses = Dict(vf => vf00)), base)
end
