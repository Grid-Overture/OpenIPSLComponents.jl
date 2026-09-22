# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/ElectricalController/BaseClasses/CurrentLimitLogicREECC.mo
# extends: nothing. The current limit logic of REECC, with the two VDL tables feeding it:
#   Iqmax = if pqflag then min(VDL1_out, sqrt(Imax^2 - Ipcmd^2)) else min(VDL1_out, Imax);   Iqmin = -Iqmax
#   Ipmax = if pqflag then min(VDL2_out, Imax) else min(VDL2_out, sqrt(Imax^2 - Iqcmd^2));   Ipmin = -Ipmax
# Note the difference from REECA/REECB, replicated: here `Ipmin = -Ipmax`, not 0.
# `pqflag` is a Boolean *input* fed by a `BooleanConstant(k = pqflag)`, i.e. a parameter in every user: the branch
# is decided in Julia (F-50) and `pqflag` is kept as a plain 0/1 variable so the connect and the OM column stay.
# `min` is `min` (precedent `Min.jl`). `start_ii`/`start_ir` are declared and used by nothing (sic): dead keyword
# arguments, kept for fidelity. Omitted: graphical annotations.

@component function CurrentLimitLogicREECC(; name, start_ii, start_ir, Imax, pqflag = true)
    Imax = float(Imax)
    # the .mo names the Boolean input `pqflag` too, and `@variables` below rebinds the name: the Julia decision
    # keeps its own copy (F-22, the `n = (; ...)` rule)
    pqflag_n = pqflag
    pars = @parameters begin
        Imax = Imax, [description = "Maximum limit on total converter current"]
    end
    vars = @variables begin
        VDL1_out(t)
        VDL2_out(t)
        pqflag(t), [description = "Priority to reactive current (0) or active current (1)"]
        Iqcmd(t)
        Ipcmd(t)
        Iqmax(t)
        Iqmin(t)
        Ipmax(t)
        Ipmin(t)
    end
    eqs = Equation[
        Iqmax ~ (pqflag_n ? min(VDL1_out, sqrt(Imax^2 - Ipcmd^2)) : min(VDL1_out, Imax)),
        Iqmin ~ -Iqmax,
        Ipmax ~ (pqflag_n ? min(VDL2_out, Imax) : min(VDL2_out, sqrt(Imax^2 - Iqcmd^2))),
        Ipmin ~ -Ipmax,
    ]
    System(eqs, t, vars, pars; name)
end
