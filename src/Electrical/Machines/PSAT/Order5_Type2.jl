# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Machines/PSAT/Order5_Type2.mo (extends BaseClasses/baseMachine.mo with xq0 = xq, vf(start = vf00))
# Fifth-order machine, type 2: `extend` over baseMachine.jl; the protected parameters are Julia arithmetic on the
# numbers `psat_machine_init` returns, in the .mo's order (e2q0, e2d0, K1, K2, e1q0, vf00), which is their dependency
# order. The .mo's `initial equation` fixes only `der(e2q) = 0` and `der(e2d) = 0` (`der(e1q) = 0` is commented out),
# so the initialization of any user is under-determined in `e1q`: the model keeps it as a `guess` and the system that
# instantiates it passes `e1q => e1q0` as the initial condition OpenModelica chooses (F-28; test_Order5_Type2.jl and
# test_IEEE14.jl). `Taa` divides by `T1d0` (the .mo's own scaling). Omitted: graphical annotations.

@component function Order5_Type2(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        Sn, Vn, ra, x1d, M, D, xd = 1.9, xq = 1.7, x2d = 0.204, x2q = 0.3, T1d0 = 8, T2d0 = 0.8, T2q0 = 0.02,
        Taa = 0.002)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xd, xq, x2d, x2q, T1d0, T2d0, T2q0, Taa =
        float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xd, xq, x2d, x2q, T1d0, T2d0, T2q0,
            Taa))   # F-21
    i0 = psat_machine_init(S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, xq)   # xq0 = xq
    e2q0 = i0.vq0 + ra * i0.iq0 + x2d * i0.id0
    e2d0 = i0.vd0 + ra * i0.id0 - x2q * i0.iq0
    K1 = xd - x1d - (T2d0 * x2d * (xd - x1d)) / (T1d0 * x1d)
    K2 = x1d - x2d + (T2d0 * x2d * (xd - x1d)) / (T1d0 * x1d)
    e1q0 = (-K1 * Taa / T1d0 * i0.id0) + (1 - Taa / T1d0) * (e2q0 + K2 * i0.id0)
    vf00 = i0.V_MBtoSB * (K1 * i0.id0 + e1q0) / (1 - Taa / T1d0)
    @named base = baseMachine(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn, Vn, ra, x1d, M, D, xq0 = xq)
    @unpack vd, vq, id, iq, vf, vf0, vf_MB = base
    pars = @parameters begin
        xd = xd, [description = "d-axis synchronous reactance (pu)"]
        xq = xq, [description = "q-axis synchronous reactance (pu)"]
        x2d = x2d, [description = "d-axis sub-transient reactance (pu)"]
        x2q = x2q, [description = "q-axis sub-transient reactance (pu)"]
        T1d0 = T1d0, [description = "d-axis open circuit transient time constant (s)"]
        T2d0 = T2d0, [description = "d-axis open circuit sub-transient time constant (s)"]
        T2q0 = T2q0, [description = "q-axis open circuit sub-transient time constant (s)"]
        Taa = Taa, [description = "d-axis additional leakage time constant (s)"]
        e2q0 = e2q0, [description = "Initialization"]
        e2d0 = e2d0, [description = "Initialization"]
        K1 = K1, [description = "Initialization"]
        K2 = K2, [description = "Initialization"]
        e1q0 = e1q0, [description = "Initialization"]
        vf00 = vf00, [description = "Initial value (system base)"]
    end
    vars = @variables begin
        e1q(t), [description = "q-axis transient voltage (pu)"]
        e2q(t), [description = "q-axis sub-transient voltage (pu)"]
        e2d(t), [description = "d-axis sub-transient voltage (pu)"]
    end
    eqs = Equation[
        der(e1q) ~ ((-e1q) - (xd - x1d - T2d0 / T1d0 * x2d / x1d * (xd - x1d)) * id +
                    (1 - Taa / T1d0) * vf_MB) / T1d0,
        der(e2d) ~ ((-e2d) + (xq - x2q) * iq) / T2q0,
        der(e2q) ~ ((-e2q) + e1q - (x1d - x2d + T2d0 / T1d0 * x2d / x1d * (xd - x1d)) * id +
                    Taa / T1d0 * vf_MB) / T2d0,
        e2q ~ vq + ra * iq + x2d * id,
        e2d ~ vd + ra * id - x2q * iq,
        vf0 ~ vf00,
    ]
    extend(System(eqs, t, vars, pars; name,
            guesses = Dict(vf => vf00, e1q => e1q0, e2q => e2q0, e2d => e2d0),
            initialization_eqs = [der(e2q) ~ 0, der(e2d) ~ 0]), base)
end
