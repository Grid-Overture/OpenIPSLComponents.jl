# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSSE/Submodels/CCL.mo (extends nothing)
# Blocks, with the names of the .mo: min1..min5 = Min, const1 = Constant(Iphl), const2 = Constant(Iqhl), const3 =
# Constant(ImaxTD), const4 = Constant(ImaxTD) (two identical constants, sic), gain, gain1 = Gain(-1). Ports are plain
# variables (IpCMD, IqCMD, Vt; IQmin, IQmax, IPmax) and the protected `Iqmax`, `IQmin1`, `IQmax1`, `IQmin2`,
# `IQmax2`, `IPmax1`, `IPmax2`, `Available_remain1`, `Available_remain2` are algebraic variables with their names.
# `pqflag` is a Boolean parameter: the three output equations are chosen in Julia (F-50) and both branches of
# blocks are instantiated (the OpenModelica CSV carries their columns). `sqrt(ImaxTD^2 - I^2)` is a NaN when
# |I| > ImaxTD, no guard in the .mo (sic); `Iqmax = (Qmax - 1.6)*(Vt - 1) + Qmax` carries the hard-coded 1.6.
# Omitted: graphical annotations.

@component function CCL(; name, Qmax, pqflag, ImaxTD, Iphl, Iqhl)
    Qmax, ImaxTD, Iphl, Iqhl = float.((Qmax, ImaxTD, Iphl, Iqhl))
    systems = @named begin
        min1 = Min()
        const1 = OpenIPSLComponents.Constant(; k = Iphl)
        const2 = OpenIPSLComponents.Constant(; k = Iqhl)
        min2 = Min()
        min3 = Min()
        min4 = Min()
        min5 = Min()
        gain = Gain(; k = -1)
        gain1 = Gain(; k = -1)
        const3 = OpenIPSLComponents.Constant(; k = ImaxTD)
        const4 = OpenIPSLComponents.Constant(; k = ImaxTD)
    end
    pars = @parameters begin
        Qmax = Qmax, [description = "Maximum reactive power (pu)"]
        ImaxTD = ImaxTD, [description = "Converter current limit (pu)"]
        Iphl = Iphl, [description = "Hard active current limit (pu)"]
        Iqhl = Iqhl, [description = "Hard reactive current limit (pu)"]
    end
    vars = @variables begin
        IQmin(t)
        IpCMD(t)
        IqCMD(t)
        IQmax(t)
        IPmax(t)
        Vt(t)
        Iqmax(t)
        IQmin1(t)
        IQmax1(t)
        IQmin2(t)
        IQmax2(t)
        IPmax1(t)
        IPmax2(t)
        Available_remain1(t), [description = "sqrt(ImaxTD^2 - IpCMD^2)"]
        Available_remain2(t), [description = "sqrt(ImaxTD^2 - IqCMD^2)"]
    end
    eqs = Equation[
        Available_remain1 ~ sqrt(ImaxTD^2 - IpCMD^2),
        Available_remain2 ~ sqrt(ImaxTD^2 - IqCMD^2),
        Iqmax ~ (Qmax - 1.6) * (Vt - 1) + Qmax,
        (pqflag ? [IQmin ~ IQmin1, IQmax ~ IQmax1, IPmax ~ IPmax1] : [IQmin ~ IQmin2, IQmax ~ IQmax2, IPmax ~ IPmax2])...,
        const1.y ~ min1.u2,                      # connect(const1.y, min1.u2)
        const1.y ~ min3.u1,                      # connect(const1.y, min3.u1)
        const2.y ~ min5.u1,                      # connect(const2.y, min5.u1)
        min5.y ~ min4.u2,                        # connect(min5.y, min4.u2)
        min2.u1 ~ min5.y,                        # connect(min2.u1, min5.y)
        min2.y ~ IQmax2,                         # connect(min2.y, IQmax2)
        min1.y ~ IPmax2,                         # connect(min1.y, IPmax2)
        min3.y ~ IPmax1,                         # connect(min3.y, IPmax1)
        gain.u ~ min2.y,                         # connect(gain.u, min2.y)
        gain.y ~ IQmin2,                         # connect(gain.y, IQmin2)
        gain1.u ~ min4.y,                        # connect(gain1.u, min4.y)
        Iqmax ~ min5.u2,                         # connect(Iqmax, min5.u2)
        min1.u1 ~ Available_remain2,             # connect(min1.u1, Available_remain2)
        const3.y ~ min2.u2,                      # connect(const3.y, min2.u2)
        const4.y ~ min3.u2,                      # connect(const4.y, min3.u2)
        Available_remain1 ~ min4.u1,             # connect(Available_remain1, min4.u1)
        gain1.y ~ IQmin1,                        # connect(gain1.y, IQmin1)
        IQmax1 ~ min4.y,                         # connect(IQmax1, min4.y)
    ]
    System(eqs, t, vars, pars; name, systems)
end
