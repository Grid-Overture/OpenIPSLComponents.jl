# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSSE/Load.mo (extends BaseClasses/baseLoad.mo, the PSSE one: PSSE_baseLoad.jl)
# The two power-balance equations are literal (bilinear in the pin currents; PLAN-02: current-explicit only if the
# tearing lands on the v = 0 branch, F-16). Omitted: graphical annotations.

@component function Load(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        S_p = complex(P_0, Q_0), S_i = complex(0.0, 0.0), S_y = complex(0.0, 0.0), a = complex(1.0, 0.0),
        b = complex(0.0, 1.0), PQBRAK = 0.7, characteristic = 1)
    @named base = PSSE_baseLoad(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, S_p, S_i, S_y, a, b, PQBRAK, characteristic)
    @unpack v, kP, kI, p, S_P_re, S_P_im, S_I_re, S_I_im, S_Y_re, S_Y_im = base
    eqs = Equation[
        kI * S_I_re * v + S_Y_re * v^2 + kP * S_P_re ~ p.vr * p.ir + p.vi * p.ii,
        kI * S_I_im * v + S_Y_im * v^2 + kP * S_P_im ~ (-p.vr * p.ii) + p.vi * p.ir,
    ]
    extend(System(eqs, t, [], []; name), base)
end
