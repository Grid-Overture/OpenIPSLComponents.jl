# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/WECC/PVD1/PQPriority.mo (extends nothing)
# Blocks, with the names of the .mo: IpLimiter, IqLimiter = VariableLimiter, Imax_ = RealExpression(y = Imax),
# diffQ, diffP = Feedback, Ipcmd2, Iqcmd2, Imax2 = Product, Ipmax_, Iqmax_ = Switch, PqFlag_ =
# BooleanExpression(y = PqFlag), zero = RealExpression(y = 0), neg = Gain(-1). Ports are plain variables (Ip, Iq;
# Ipcmd, Iqcmd). `PqFlag` is a Boolean parameter, but the `BooleanExpression` and the two `Switch` are instantiated
# literally because the OpenModelica CSV carries their columns (precedent: `Lvplsw_logic`/`switch1` of REGCA1).
# Quirk reproduced, sic: the limits are `Imax^2 - I^2` **without a square root** (P priority: Ipmax = Imax,
# Iqmax = Imax^2 - Ipcmd^2; Q priority the other way round), a squared current used as a current limit; and
# `Ipcmd >= 0` always (`zero` is IpLimiter's lower limit). Omitted: graphical annotations.

@component function PQPriority(; name, PqFlag, Imax)
    Imax = float(Imax)
    Imaxn = Imax
    pars = @parameters begin
        Imax = Imax, [description = "Maximum allowable total converter current (pu)"]
    end
    systems = @named begin
        IpLimiter = VariableLimiter()
        IqLimiter = VariableLimiter()
        Imax_ = RealExpression(; expr = Imaxn)
        diffQ = Feedback()
        Ipcmd2 = Product()
        Iqcmd2 = Product()
        Ipmax_ = Switch()
        Iqmax_ = Switch()
        PqFlag_ = BooleanExpression(; expr = PqFlag)
        Imax2 = Product()
        zero = RealExpression(; expr = 0.0)
        neg = Gain(; k = -1)
        diffP = Feedback()
    end
    vars = @variables begin
        Ip(t), [description = "Active current command input"]
        Iq(t), [description = "Reactive current command input"]
        Iqcmd(t), [description = "Limited reactive current command"]
        Ipcmd(t), [description = "Limited active current command"]
    end
    eqs = Equation[
        IqLimiter.y ~ Iqcmd,                 # connect(IqLimiter.y, Iqcmd)
        IpLimiter.y ~ Ipcmd,                 # connect(IpLimiter.y, Ipcmd)
        Ip ~ IpLimiter.u,                    # connect(Ip, IpLimiter.u)
        Iq ~ IqLimiter.u,                    # connect(Iq, IqLimiter.u)
        IpLimiter.y ~ Ipcmd2.u2,             # connect(IpLimiter.y, Ipcmd2.u2)
        Iqcmd2.u1 ~ IqLimiter.y,             # connect(Iqcmd2.u1, IqLimiter.y)
        Ipmax_.y ~ IpLimiter.limit1,         # connect(Ipmax_.y, IpLimiter.limit1)
        Imax_.y ~ Ipmax_.u1,                 # connect(Imax_.y, Ipmax_.u1)
        PqFlag_.y ~ Ipmax_.u2,               # connect(PqFlag_.y, Ipmax_.u2)
        Imax2.y ~ diffQ.u1,                  # connect(Imax2.y, diffQ.u1)
        Iqcmd2.y ~ diffQ.u2,                 # connect(Iqcmd2.y, diffQ.u2)
        diffQ.y ~ Ipmax_.u3,                 # connect(diffQ.y, Ipmax_.u3)
        Imax2.u1 ~ Imax_.y,                  # connect(Imax2.u1, Imax_.y)
        zero.y ~ IpLimiter.limit2,           # connect(zero.y, IpLimiter.limit2)
        Iqmax_.u2 ~ PqFlag_.y,               # connect(Iqmax_.u2, PqFlag_.y)
        Iqcmd2.u2 ~ Iqcmd2.u1,               # connect(Iqcmd2.u2, Iqcmd2.u1)
        Imax_.y ~ Imax2.u2,                  # connect(Imax_.y, Imax2.u2)
        Ipcmd2.u2 ~ Ipcmd2.u1,               # connect(Ipcmd2.u2, Ipcmd2.u1)
        Imax_.y ~ Iqmax_.u3,                 # connect(Imax_.y, Iqmax_.u3)
        Iqmax_.y ~ IqLimiter.limit1,         # connect(Iqmax_.y, IqLimiter.limit1)
        IqLimiter.limit2 ~ neg.y,            # connect(IqLimiter.limit2, neg.y)
        neg.u ~ Iqmax_.y,                    # connect(neg.u, Iqmax_.y)
        diffP.u1 ~ Imax2.y,                  # connect(diffP.u1, Imax2.y)
        diffP.u2 ~ Ipcmd2.y,                 # connect(diffP.u2, Ipcmd2.y)
        diffP.y ~ Iqmax_.u1,                 # connect(diffP.y, Iqmax_.u1)
    ]
    System(eqs, t, vars, pars; name, systems)
end
