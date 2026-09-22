# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSAT/PSAT_Type_3/MechaBlk.mo (extends nothing)
# Blocks: none. Ports are plain variables (Tm, Tel; omega_m). `der(omega_m) = (Tm - Tel)/(2*Hm)`. The `initial
# equation` `if Pc < Pnom/Sbase and Pc > 0 then omega_m = 0.5*Pc*Sbase/Pnom + 0.5 elseif Pc*Sbase >= Pnom then
# omega_m = 1 else omega_m = 0.5` is an `if` on parameters, decided in Julia (F-50; it is PSAT_WT's `omega_m0`)
# and written as an `initial_conditions` entry (F-54); `Tel = Tm` is the second initial equation, which the
# ElecDynBlk states have to satisfy. Omitted: graphical annotations.

@component function MechaBlk(; name, Sbase = 100000000, Pnom = 10000000, Hm = 0.3, Pc = 0.016)
    Sbase, Pnom, Hm, Pc = float.((Sbase, Pnom, Hm, Pc))
    omega_m0 = (Pc < Pnom / Sbase && Pc > 0) ? 0.5 * Pc * Sbase / Pnom + 0.5 : (Pc * Sbase >= Pnom ? 1.0 : 0.5)
    pars = @parameters begin
        Sbase = Sbase, [description = "Power Rating [Normalization Factor] (VA)"]
        Pnom = Pnom, [description = "Nominal Power (VA)"]
        Hm = Hm, [description = "inertia (s)"]
        Pc = Pc, [description = "Input Power Flow (pu)"]
    end
    vars = @variables begin
        Tm(t), [description = "engine shaft torque"]
        Tel(t), [description = "electromagnetical torque"]
        omega_m(t), [description = "engine shaft angular velocity"]
    end
    System(Equation[der(omega_m) ~ (Tm - Tel) / (2 * Hm)], t, vars, pars; name,
        initial_conditions = Dict(omega_m => omega_m0), guesses = Dict(omega_m => omega_m0),
        initialization_eqs = [Tel ~ Tm])
end
