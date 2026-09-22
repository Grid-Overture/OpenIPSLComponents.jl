# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/ElectricalController/BaseClasses/CurrentLimitLogicREECA.mo
# extends: nothing. The current limit logic of REECA, whose arithmetic is the odd one of the three and is
# **replicated as written**:
#   Ipre  = if pqflag == false then sqrt(Imax) - sqrt(abs(Iqcmd)) else sqrt(Imax) - sqrt(abs(Ipcmd))
#   Ipost = if Ipre < 0 then 0 else sqrt(Ipre)
# i.e. square roots of *currents*, not of squares of currents -- REECB and REECC both write
# `sqrt(Imax^2 - I^2)`. This is a quirk of OpenIPSL 3.1.0, kept literally; a candidate upstream note.
#   Iqmax = if pqflag == false then min(VDL1_out, Imax) else min(Ipost, VDL1_out);   Iqmin = -Iqmax
#   Ipmax = if pqflag == false then min(Ipost, VDL2_out) else min(VDL2_out, Imax);   Ipmin = 0
# (`Ipmin = 0` as in REECB, unlike REECC's `-Ipmax`.)
# `pqflag` is a Boolean input fed by a `BooleanConstant`, i.e. a parameter: the branch is decided in Julia (F-50)
# from a numeric copy taken before `@variables` rebinds the name (F-22). `Ipre < 0` is on a *variable*, so it is a
# symbolic `ifelse`. `start_ii`/`start_ir` are dead (sic). Omitted: graphical annotations, the commented-out
# alternative formulas the `.mo` keeps.

@component function CurrentLimitLogicREECA(; name, start_ii, start_ir, Imax, pqflag = true)
    Imax = float(Imax)
    pqflag_n = pqflag     # numeric copy: `@variables` below rebinds the name (F-22)
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
        Ipost(t)
        Ipre(t)
    end
    eqs = Equation[
        Ipre ~ (pqflag_n ? sqrt(Imax) - sqrt(abs(Ipcmd)) : sqrt(Imax) - sqrt(abs(Iqcmd))),
        Ipost ~ ifelse(Ipre < 0, 0.0, sqrt(Ipre)),
        Iqmax ~ (pqflag_n ? min(Ipost, VDL1_out) : min(VDL1_out, Imax)),
        Iqmin ~ -Iqmax,
        Ipmax ~ (pqflag_n ? min(VDL2_out, Imax) : min(Ipost, VDL2_out)),
        Ipmin ~ 0,
    ]
    System(eqs, t, vars, pars; name)
end
