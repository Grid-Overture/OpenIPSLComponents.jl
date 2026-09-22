# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Electrical/Analog/Basic.mo, model Resistor
# extends Interfaces.OnePort + ConditionalHeatPort(T = T_ref). With `useHeatPort = false` (the only case in
# OpenIPSL: AC2DCandDC2AC's `Resistor(R = Rdc)`) MSL's `T_heatPort = T` = `T_ref`, so `R_actual = R*(1 + alpha*0)`
# = `R` with the default `alpha = 0`, and the model is `v = R*i`.
# Omitted: `useHeatPort`/`T`/`T_ref`/`alpha`/`R_actual`/`LossPower` and the temperature assert (all inert here),
# graphical annotations.

@component function Resistor(; name, R = 1)
    pars = @parameters begin
        R = float(R), [description = "Resistance at temperature T_ref"]
    end
    base = OnePort(; name)
    @unpack v, i = base
    extend(System(Equation[v ~ R * i], t, [], pars; name), base)
end
