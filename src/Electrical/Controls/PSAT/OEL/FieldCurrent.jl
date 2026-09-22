# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSAT/OEL/FieldCurrent.mo
# Estimates the field current from P, Q, v and the d-/q-axis reactances. Flat, three equations, no state.
# The RealInput/RealOutput ports v, p, q, ifield are plain variables; `gamma_p`, `gamma_q` are the .mo's protected
# variables. `v` is never 0 in the model's only user (OEL, fed by a machine terminal voltage), so the divisions are
# copied as written. Omitted: graphical annotations.

@component function FieldCurrent(; name, xd, xq)
    xd, xq = float.((xd, xq))   # F-21
    pars = @parameters begin
        xd = xd, [description = "d-axis reactance (pu)"]
        xq = xq, [description = "q-axis reactance (pu)"]
    end
    vars = @variables begin
        v(t), [description = "generator terminal voltage (pu)"]
        p(t), [description = "active power (pu)"]
        q(t), [description = "reactive power (pu)"]
        ifield(t), [description = "estimated field current (pu)"]
        gamma_p(t)
        gamma_q(t)
    end
    eqs = Equation[
        gamma_p ~ xq * p / v,
        gamma_q ~ xq * q / v,
        ifield ~ sqrt((v + gamma_q)^2 + p^2) +
                 ((xd / xq - 1) * (gamma_q * (v + gamma_q) + gamma_p^2) / sqrt((v + gamma_q)^2 + p^2)),
    ]
    System(eqs, t, vars, pars; name)
end
