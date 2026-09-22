# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/ElectricalController/BaseClasses/CurrentLimitLogicREECB.mo
# extends: nothing. The current limit logic of REECB:
#   Ipmax = if Pqflag then Imax else sqrt(Imax^2 - Iqcmd^2);  Ipmin = 0
#   Iqmax = if Pqflag then sqrt(Imax^2 - Ipcmd^2) else Imax;  Iqmin = -Iqmax
# `Pqflag` is a Boolean *input* in the .mo, fed by a `BooleanConstant(k = pqflag)`, i.e. a parameter in every user:
# the branch is therefore decided in Julia from the `pqflag` keyword argument (F-50) and `Pqflag` is kept as a plain
# 0/1 variable so that the connect from the parent's `Pqflag_logic` stays (and the OM column compares).
# `start_ii` and `start_ir` are declared and used by nothing (sic): dead keyword arguments, kept for fidelity.
# Ports are plain variables (Iqcmd, Ipcmd, Pqflag inputs; Iqmin, Iqmax, Ipmin, Ipmax outputs).
# Omitted: graphical annotations.

@component function CurrentLimitLogicREECB(; name, start_ii, start_ir, Imax, pqflag = true)
    Imax = float(Imax)
    pars = @parameters begin
        Imax = Imax, [description = "Maximum limit on total converter current"]
    end
    vars = @variables begin
        Iqcmd(t)
        Ipcmd(t)
        Pqflag(t), [description = "Priority to reactive current (0) or active current (1)"]
        Iqmin(t)
        Iqmax(t)
        Ipmin(t)
        Ipmax(t)
    end
    eqs = Equation[
        Ipmax ~ (pqflag ? Imax : sqrt(Imax^2 - Iqcmd^2)),
        Ipmin ~ 0,
        Iqmax ~ (pqflag ? sqrt(Imax^2 - Ipcmd^2) : Imax),
        Iqmin ~ -Iqmax,
    ]
    System(eqs, t, vars, pars; name)
end
