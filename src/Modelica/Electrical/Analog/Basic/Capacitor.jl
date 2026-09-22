# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Electrical/Analog/Basic.mo, model Capacitor
# extends Interfaces.OnePort(v(start = 0)): `i = C*der(v)`. `v_start` is the guess and `v_fixed` says whether the
# `start` is a fixed initial condition: `AC2DCandDC2AC` writes `Capacitor(v(start = Vc0, fixed = true), C = Cdc)`,
# the one fixed start of the DC link (its Inductor's is free). Omitted: graphical annotations.

@component function Capacitor(; name, C = 1, v_start = 0, v_fixed = false)
    pars = @parameters begin
        C = float(C), [description = "Capacitance"]
    end
    base = OnePort(; name)
    @unpack v, i = base
    v_start = float(v_start)
    kw = v_fixed ? (; guesses = Dict(v => v_start), initialization_eqs = [v ~ v_start]) : (; guesses = Dict(v => v_start))
    extend(System(Equation[i ~ C * der(v)], t, [], pars; name, kw...), base)
end
