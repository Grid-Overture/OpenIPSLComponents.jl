# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/BaseClasses/SelectLogic.mo (model): picks the voltage signal
# according to the excitation limiters, Vout = if VOEL > 0 then V3 else if VUEL > 0 then V2 else V1.
# Ports are plain variables (V1, V2, V3, VOEL, VUEL, VERR, Vout). No sub-blocks.
# Omitted: graphical annotations. `VERR` is declared by the .mo and never read (sic): it is kept as a port.

# The `if` is over variables and has no `when`/`reinit`, so it is an `ifelse` chain; the two crossings are
# registered as continuous events without affect so that the integrator steps exactly onto them.
@component function SelectLogic(; name)
    vars = @variables begin
        V1(t)
        V2(t)
        V3(t)
        VOEL(t)
        VUEL(t)
        VERR(t)
        Vout(t)
    end
    eqs = Equation[Vout ~ ifelse(VOEL > 0, V3, ifelse(VUEL > 0, V2, V1))]
    events = [SymbolicContinuousCallback([VOEL ~ 0], nothing), SymbolicContinuousCallback([VUEL ~ 0], nothing)]
    System(eqs, t, vars, []; name, continuous_events = events)
end
