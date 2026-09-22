# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/ElectricalController/REECB1.mo (extends BaseClasses/BaseREECB.mo)
# The electrical controller of a large-scale PV plant: the simplest of the three (no VDL tables, no PI with
# anti-windup). Blocks with the .mo's own names.
#
# **The five `fixed = false` parameters** `Ip0`, `Iq0`, `V0`, `p00`, `q00` are resolved by an `initial equation`
# from the *inputs* `ip0`, `iq0`, `v0`, `p0`, `q0` -> F-33: `@parameters ... [guess]` + `initial_conditions` of
# `missing` + `initialization_eqs`. Everything derived from them is a chain of `missing` (F-38):
#   pfaref  = p00/sqrt(p00^2 + q00^2)
#   pfangle = if q00 > 0 then acos(pfaref) else -acos(pfaref)   -- an `if` on a `missing` value, so a **symbolic
#             `ifelse`**, not a Julia decision: the value does not exist before the initialization is solved. This
#             is the first such case in the port.
#   Vref0   = if (vref0 > 0 or vref0 < 0) then vref0 else V0    -- here Julia does decide: `vref0` is a numeric
#             keyword argument; when it picks `V0` it passes the `missing` symbol down (F-38).
# and the `y_start` of `integrator` (V0), `integrator1`/`integrator2` (-Iq0 - (-V0 + Vref0)*Kqv), `simpleLag` (V0),
# `simpleLag1` (p00) and `integrator3` (Ip0*V0) receive the symbolic expression.
# Every `Integrator` of this model is `InitialState` (MSL 4.0.0's default; `integrator2` and `integrator3` do not
# write `initType` and are `InitialState` all the same). No `NoInit` anywhere in the batch.
#
# `Voltage_dip = if Vt < Vdip or Vt > Vup then 1 else 0` is an **Integer** in this model (a Boolean in REECA1): an
# algebraic 0/1 variable with an `ifelse`, no event (precedent `TGTypeI`). Its three consumers `frzState`,
# `frzState1`, `frzState2` are `RealExpression(y = if Voltage_dip == 1 then 0 else 1)`, the products that freeze the
# three integrators; they read a variable of this model, so their `y` equation is written here (F-22).
# With `Vdip = -99` and `Vup = 99` (the Test's and every case's values) it never fires.
# `Trv = 0` makes `simpleLag` a pass-through (`SimpleLag.jl`'s F-50 form handles it).
# The four flag switches (`PfFlag`, `VFlag`, `QFlag`, and `ccl.Pqflag`) are instantiated literally with their
# `BooleanConstant`, as `REGCA1`'s `switch1` is.
# Note the `.mo` has **two** `RealExpression(y = Vref0)` instances with names differing only in case, `VREF0` (into
# `add.u2`) and `VReF0` (into `VFlag.u3`): both are kept, and they are distinct Julia names.
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function REECB1(; name, pfflag = true, vflag = true, qflag = true, pqflag = true,
        Vdip = -99, Vup = 99, Trv = 0, dbd1 = -0.05, dbd2 = 0.05, Kqv = 0, Iqh1 = 1.05, Iql1 = -1.05,
        vref0 = 1, Tp = 0.05, Qmax = 0.4360, Qmin = -0.4360, Vmax = 1.1, Vmin = 0.9, Kqp = 0, Kqi = 0.1,
        Kvp = 0, Kvi = 40, Tiq = 0.02, dPmax = 99, dPmin = -99, Pmax = 1, Pmin = 0, Imax = 1.82, Tpord = 0.02)
    Vdip, Vup, Trv, dbd1, dbd2, Kqv, Iqh1, Iql1, vref0 =
        float.((Vdip, Vup, Trv, dbd1, dbd2, Kqv, Iqh1, Iql1, vref0))
    Tp, Qmax, Qmin, Vmax, Vmin, Kqp, Kqi, Kvp, Kvi, Tiq =
        float.((Tp, Qmax, Qmin, Vmax, Vmin, Kqp, Kqi, Kvp, Kvi, Tiq))
    dPmax, dPmin, Pmax, Pmin, Imax, Tpord = float.((dPmax, dPmin, Pmax, Pmin, Imax, Tpord))
    n = (; Trv, dbd1, dbd2, Kqv, Iqh1, Iql1, Tp, Qmax, Qmin, Vmax, Vmin, Kqp, Kqi, Kvp, Kvi, Tiq,
        dPmax, dPmin, Pmax, Pmin, Imax, Tpord)   # numeric copies for the blocks (F-22)
    inf = Modelica.Constants.inf
    base = BaseREECB(; name)
    @unpack Vt, Pe, Qext, Qgen, Pref, ip0, iq0, Iqcmd, Ipcmd, v0, p0, q0 = base
    pars = @parameters begin
        Vdip = Vdip, [description = "Low voltage threshold to activate reactive current injection logic"]
        Vup = Vup, [description = "Voltage above which reactive current injection logic is activated"]
        Ip0, [guess = 1.0]
        Iq0, [guess = 0.0]
        V0, [guess = 1.0]
        p00, [guess = 1.0]
        q00, [guess = 0.0]
    end
    # the protected derived parameters of the .mo, all of them `missing` chains (F-38)
    pfaref = p00 / sqrt(p00^2 + q00^2)
    pfangle = ifelse(q00 > 0, acos(pfaref), -acos(pfaref))     # symbolic: q00 does not exist yet (header)
    Vref0 = (vref0 > 0 || vref0 < 0) ? vref0 : V0              # a Julia decision on a numeric kwarg (F-50)
    systems = @named begin
        PfFlag_logic = BooleanConstant(; k = pfflag)
        PfFlag = Switch()
        limiter1 = Limiter(; uMax = n.Qmax, uMin = n.Qmin)
        add1 = Add(; k2 = -1)
        integrator = Integrator(; k = n.Kqi, initType = :InitialState, y_start = V0)
        gain = Gain(; k = n.Kqp)
        add2 = Add()
        frzState = RealExpression(; expr = nothing)      # y = if Voltage_dip == 1 then 0 else 1 (F-22)
        product2 = Product()
        limiter2 = Limiter(; uMax = n.Vmax, uMin = n.Vmin)
        Vflag_logic = BooleanConstant(; k = vflag)
        VFlag = Switch()
        limiter3 = Limiter(; uMax = n.Vmax, uMin = n.Vmin)
        add4 = Add(; k2 = -1)
        Vt_filt2 = RealExpression(; expr = nothing)      # y = simpleLag.y
        gain1 = Gain(; k = n.Kvp)
        integrator1 = Integrator(; k = n.Kvi, initType = :InitialState,
            y_start = -Iq0 - (-V0 + Vref0) * n.Kqv)
        add5 = Add()
        product3 = Product()
        frzState1 = RealExpression(; expr = nothing)
        variableLimiter2 = VariableLimiter()
        QFlag = Switch()
        QFLAG = BooleanConstant(; k = qflag)
        add6 = Add(; k2 = 1)
        variableLimiter = VariableLimiter()
        IQMIN = RealExpression(; expr = nothing)         # y = ccl.Iqmin
        IQMAX = RealExpression(; expr = nothing)         # y = ccl.Iqmax
        IQMIN_ = RealExpression(; expr = nothing)
        IQMAX_ = RealExpression(; expr = nothing)
        add7 = Add(; k2 = -1)
        integrator2 = Integrator(; k = 1 / n.Tiq, initType = :InitialState,
            y_start = -Iq0 - (-V0 + Vref0) * n.Kqv)
        product4 = Product()
        Vt_filt1 = RealExpression(; expr = nothing)
        limiter4 = Limiter(; uMax = inf, uMin = 0.01)
        division = Division()
        variableLimiter1 = VariableLimiter()
        IPMIN = RealExpression(; expr = nothing)         # y = ccl.Ipmin
        IPMAX = RealExpression(; expr = nothing)         # y = ccl.Ipmax
        simpleLag = SimpleLag(; K = 1, T = n.Trv, y_start = V0)
        add = Add(; k1 = -1)
        limiter = Limiter(; uMax = n.Iqh1, uMin = n.Iql1)
        VREF0 = RealExpression(; expr = nothing)         # y = Vref0 (a `missing` chain when vref0 = 0)
        dbd1_dbd2 = DeadZone(; uMax = n.dbd2, uMin = n.dbd1)
        gain2 = Gain(; k = n.Kqv)
        simpleLag1 = SimpleLag(; K = 1, T = n.Tp, y_start = p00)
        tan1 = Tan()
        product1 = Product()
        PFAREF = RealExpression(; expr = nothing)        # y = pfangle
        division1 = Division()
        limiter5 = Limiter(; uMax = inf, uMin = 0.01)
        add8 = Add(; k2 = -1)
        limiter7 = Limiter(; uMax = n.dPmax, uMin = n.dPmin)
        integrator3 = Integrator(; k = 1 / n.Tpord, initType = :InitialState, y_start = Ip0 * V0)
        limiter8 = Limiter(; uMax = n.Pmax, uMin = n.Pmin)
        Vt_filt3 = RealExpression(; expr = nothing)
        ccl = CurrentLimitLogicREECB(; start_ii = -Iq0, start_ir = Ip0, Imax = n.Imax, pqflag)
        Pqflag_logic = BooleanConstant(; k = pqflag)
        frzState2 = RealExpression(; expr = nothing)
        VReF0 = RealExpression(; expr = nothing)         # y = Vref0 (the .mo's second instance, sic)
        product6 = Product()
    end
    vars = @variables begin
        Voltage_dip(t), [description = "Voltage dip flag (0/1)"]
    end
    frz = ifelse(Voltage_dip > 0.5, 0.0, 1.0)     # `if Voltage_dip == 1 then 0 else 1`
    eqs = Equation[
        Voltage_dip ~ ifelse((Vt < Vdip) | (Vt > Vup), 1.0, 0.0),
        # the RealExpression blocks whose `y` reads a variable or a derived parameter of this model (F-22)
        frzState.y ~ frz,
        frzState1.y ~ frz,
        frzState2.y ~ frz,
        Vt_filt1.y ~ simpleLag.y,
        Vt_filt2.y ~ simpleLag.y,
        Vt_filt3.y ~ simpleLag.y,
        IQMIN.y ~ ccl.Iqmin,
        IQMAX.y ~ ccl.Iqmax,
        IQMIN_.y ~ ccl.Iqmin,
        IQMAX_.y ~ ccl.Iqmax,
        IPMIN.y ~ ccl.Ipmin,
        IPMAX.y ~ ccl.Ipmax,
        VREF0.y ~ Vref0,
        VReF0.y ~ Vref0,
        PFAREF.y ~ pfangle,
        simpleLag.y ~ add.u1,                # connect(simpleLag.y, add.u1)
        VREF0.y ~ add.u2,                    # connect(VREF0.y, add.u2)
        dbd1_dbd2.y ~ gain2.u,               # connect(dbd1_dbd2.y, gain2.u)
        add.y ~ dbd1_dbd2.u,                 # connect(add.y, dbd1_dbd2.u)
        gain2.y ~ limiter.u,                 # connect(gain2.y, limiter.u)
        simpleLag1.y ~ product1.u1,          # connect(simpleLag1.y, product1.u1)
        tan1.y ~ product1.u2,                # connect(tan1.y, product1.u2)
        Pe ~ simpleLag1.u,                   # connect(Pe, simpleLag1.u)
        PFAREF.y ~ tan1.u,                   # connect(PFAREF.y, tan1.u)
        Qext ~ PfFlag.u3,                    # connect(Qext, PfFlag.u3)
        product1.y ~ PfFlag.u1,              # connect(product1.y, PfFlag.u1)
        PfFlag_logic.y ~ PfFlag.u2,          # connect(PfFlag_logic.y, PfFlag.u2)
        PfFlag.y ~ limiter1.u,               # connect(PfFlag.y, limiter1.u)
        limiter1.y ~ add1.u1,                # connect(limiter1.y, add1.u1)
        Qgen ~ add1.u2,                      # connect(Qgen, add1.u2)
        gain.y ~ add2.u1,                    # connect(gain.y, add2.u1)
        integrator.y ~ add2.u2,              # connect(integrator.y, add2.u2)
        product2.y ~ integrator.u,           # connect(product2.y, integrator.u)
        frzState.y ~ product2.u2,            # connect(frzState.y, product2.u2)
        add2.y ~ limiter2.u,                 # connect(add2.y, limiter2.u)
        limiter2.y ~ VFlag.u1,               # connect(limiter2.y, VFlag.u1)
        Vflag_logic.y ~ VFlag.u2,            # connect(Vflag_logic.y, VFlag.u2)
        limiter3.y ~ add4.u1,                # connect(limiter3.y, add4.u1)
        Vt_filt2.y ~ add4.u2,                # connect(Vt_filt2.y, add4.u2)
        VFlag.y ~ limiter3.u,                # connect(VFlag.y, limiter3.u)
        gain1.y ~ add5.u1,                   # connect(gain1.y, add5.u1)
        integrator1.y ~ add5.u2,             # connect(integrator1.y, add5.u2)
        frzState1.y ~ product3.u2,           # connect(frzState1.y, product3.u2)
        product3.y ~ integrator1.u,          # connect(product3.y, integrator1.u)
        add5.y ~ variableLimiter2.u,         # connect(add5.y, variableLimiter2.u)
        IQMAX_.y ~ variableLimiter2.limit1,  # connect(IQMAX_.y, variableLimiter2.limit1)
        variableLimiter2.y ~ QFlag.u1,       # connect(variableLimiter2.y, QFlag.u1)
        QFLAG.y ~ QFlag.u2,                  # connect(QFLAG.y, QFlag.u2)
        IQMIN_.y ~ variableLimiter2.limit2,  # connect(IQMIN_.y, variableLimiter2.limit2)
        add6.y ~ variableLimiter.u,          # connect(add6.y, variableLimiter.u)
        IQMIN.y ~ variableLimiter.limit2,    # connect(IQMIN.y, variableLimiter.limit2)
        IQMAX.y ~ variableLimiter.limit1,    # connect(IQMAX.y, variableLimiter.limit1)
        QFlag.y ~ add6.u2,                   # connect(QFlag.y, add6.u2)
        add7.y ~ product4.u2,                # connect(add7.y, product4.u2)
        Vt_filt1.y ~ limiter4.u,             # connect(Vt_filt1.y, limiter4.u)
        limiter4.y ~ division.u2,            # connect(limiter4.y, division.u2)
        division.u1 ~ limiter1.u,            # connect(division.u1, limiter1.u)
        division.y ~ add7.u1,                # connect(division.y, add7.u1)
        integrator2.y ~ QFlag.u3,            # connect(integrator2.y, QFlag.u3)
        add7.u2 ~ QFlag.u3,                  # connect(add7.u2, QFlag.u3)
        product4.y ~ integrator2.u,          # connect(product4.y, integrator2.u)
        product4.u1 ~ product3.u2,           # connect(product4.u1, product3.u2)
        IPMIN.y ~ variableLimiter1.limit2,   # connect(IPMIN.y, variableLimiter1.limit2)
        IPMAX.y ~ variableLimiter1.limit1,   # connect(IPMAX.y, variableLimiter1.limit1)
        variableLimiter1.y ~ Ipcmd,          # connect(variableLimiter1.y, Ipcmd)
        Vt ~ simpleLag.u,                    # connect(Vt, simpleLag.u)
        limiter.y ~ add6.u1,                 # connect(limiter.y, add6.u1)
        limiter5.y ~ division1.u2,           # connect(limiter5.y, division1.u2)
        add8.y ~ limiter7.u,                 # connect(add8.y, limiter7.u)
        integrator3.y ~ limiter8.u,          # connect(integrator3.y, limiter8.u)
        add8.u2 ~ limiter8.u,                # connect(add8.u2, limiter8.u)
        limiter8.y ~ division1.u1,           # connect(limiter8.y, division1.u1)
        Vt_filt3.y ~ limiter5.u,             # connect(Vt_filt3.y, limiter5.u)
        add8.u1 ~ Pref,                      # connect(add8.u1, Pref)
        division1.y ~ variableLimiter1.u,    # connect(division1.y, variableLimiter1.u)
        variableLimiter.y ~ Iqcmd,           # connect(variableLimiter.y, Iqcmd)
        Pqflag_logic.y ~ ccl.Pqflag,         # connect(Pqflag_logic.y, ccl.Pqflag)
        ccl.Iqcmd ~ Iqcmd,                   # connect(ccl.Iqcmd, Iqcmd)
        ccl.Ipcmd ~ Ipcmd,                   # connect(ccl.Ipcmd, Ipcmd)
        product2.u1 ~ add1.y,                # connect(product2.u1, add1.y)
        gain.u ~ integrator.u,               # connect(gain.u, integrator.u)
        product3.u1 ~ add4.y,                # connect(product3.u1, add4.y)
        gain1.u ~ integrator1.u,             # connect(gain1.u, integrator1.u)
        frzState2.y ~ product6.u1,           # connect(frzState2.y, product6.u1)
        limiter7.y ~ product6.u2,            # connect(limiter7.y, product6.u2)
        product6.y ~ integrator3.u,          # connect(product6.y, integrator3.u)
        VReF0.y ~ VFlag.u3,                  # connect(VReF0.y, VFlag.u3)
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            initial_conditions = Dict(Ip0 => missing, Iq0 => missing, V0 => missing,
                p00 => missing, q00 => missing),
            initialization_eqs = [Ip0 ~ ip0, Iq0 ~ iq0, V0 ~ v0, p00 ~ p0, q00 ~ q0]), base)
end
