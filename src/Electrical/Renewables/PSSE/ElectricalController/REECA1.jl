# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/ElectricalController/REECA1.mo (extends BaseClasses/BaseREECA.mo)
# The electrical controller of a large-scale wind plant: the only one of the three with the two **PI blocks with
# anti-windup** (`pI_No_Windup` with a variable limiter, `pI_No_Windup_notVariable` with a fixed one, both on the
# F-44/F-62 form) and with the `StateTransitionSwitch` that holds the reactive injection at `State0 = 0` during a
# voltage dip. Blocks with the .mo's own names.
# The five `fixed = false` parameters, `pfaref`/`pfangle` (a symbolic `ifelse` on a `missing` value) and `Vref0`
# are exactly as in `REECB1.jl` (F-33, F-38, F-50); see that file's header. Note `vref0 = 0` by default here, so
# `Vref0` normally *is* the `missing` `V0`.
# `Voltage_dip = if Vt < Vdip or Vt > Vup then true else false` is a **Boolean** in this model (an Integer in
# REECB/REECC): an algebraic 0/1 variable with an `ifelse` all the same.
# `Vmod = if pfflag == false and vflag == false and qflag == true then V0 - PfFlag.y else Vbias` is a *variable*
# whose branch is chosen by three Boolean **parameters**: the choice is made in Julia (F-50) and only the surviving
# expression is written. `VBIAS = RealExpression(y = Vmod)` reads it, so its equation lives here (F-22).
# `GeneratorSpeed(y = if pflag then Wg else 1)` is the same kind of parameter decision.
# The VDL tables carry the abscissas `Vq_k + (k+1)*eps` of the `.mo` literally: they exist so that MSL does not see
# repeated abscissas when the defaults are `1.33, 1.33, 1.33`. With `eps = 1e-15` a segment of slope `0/(k*eps)`
# evaluates to 0, not NaN, because the numerator is exactly zero.
# `Iqfrz` and `Thld` are dead parameters (the `StateTransitionSwitch` selects `State0 = 0` during the dip, never
# `Iqfrz`): kept for fidelity, sic.
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function REECA1(; name, pfflag = true, vflag = true, qflag = true, pqflag = true, pflag = true,
        Vdip = -99, Vup = 99, Trv = 0.01, dbd1 = -0.05, dbd2 = 0.05, Kqv = 0, Iqh1 = 1.05, Iql1 = -1.05,
        vref0 = 0, Iqfrz = 0.15, Thld = 0, Tp = 0.05, Qmax = 0.4, Qmin = -0.4, Vmax = 1.1, Vmin = 0.9,
        Kqp = 0, Kqi = 0.1, Kvp = 0, Kvi = 120, Vbias = 0, Tiq = 0.02, dPmax = 99, dPmin = -99,
        Pmax = 1, Pmin = 0, Imax = 1.7, Tpord = 0.04,
        Vq1 = 0.29, Iq1 = 1.25, Vq2 = 1.33, Iq2 = 0.00, Vq3 = 1.33, Iq3 = 0.00, Vq4 = 1.33, Iq4 = 0.00,
        Vp1 = 0.00, Ip1 = 1.15, Vp2 = 1.1, Ip2 = 1.24, Vp3 = 2, Ip3 = 1.24, Vp4 = 2, Ip4 = 1.24)
    Vdip, Vup, Trv, dbd1, dbd2, Kqv, Iqh1, Iql1, vref0, Iqfrz, Thld =
        float.((Vdip, Vup, Trv, dbd1, dbd2, Kqv, Iqh1, Iql1, vref0, Iqfrz, Thld))
    Tp, Qmax, Qmin, Vmax, Vmin, Kqp, Kqi, Kvp, Kvi, Vbias, Tiq =
        float.((Tp, Qmax, Qmin, Vmax, Vmin, Kqp, Kqi, Kvp, Kvi, Vbias, Tiq))
    dPmax, dPmin, Pmax, Pmin, Imax, Tpord = float.((dPmax, dPmin, Pmax, Pmin, Imax, Tpord))
    eps = Modelica.Constants.eps
    vdl1 = float.([Vq1+2eps Iq1; Vq2+3eps Iq2; Vq3+4eps Iq3; Vq4+5eps Iq4])   # the .mo's `+k*eps`, literal
    vdl2 = float.([Vp1+2eps Ip1; Vp2+3eps Ip2; Vp3+4eps Ip3; Vp4+5eps Ip4])
    n = (; Trv, dbd1, dbd2, Kqv, Iqh1, Iql1, Tp, Qmax, Qmin, Vmax, Vmin, Kqp, Kqi, Kvp, Kvi, Tiq,
        dPmax, dPmin, Pmax, Pmin, Imax, Tpord, Vbias)
    inf = Modelica.Constants.inf
    base = BaseREECA(; name)
    @unpack Vt, Pe, Qext, Qgen, Pref, ip0, iq0, Iqcmd, Ipcmd, Wg, v0, p0, q0 = base
    pars = @parameters begin
        Vdip = Vdip, [description = "Low voltage threshold to activate reactive current injection logic"]
        Vup = Vup, [description = "Voltage above which reactive current injection logic is activated"]
        Ip0, [guess = 1.0]
        Iq0, [guess = 0.0]
        V0, [guess = 1.0]
        p00, [guess = 1.0]
        q00, [guess = 0.0]
    end
    pfaref = p00 / sqrt(p00^2 + q00^2)
    pfangle = ifelse(q00 > 0, acos(pfaref), -acos(pfaref))
    Vref0 = (vref0 > 0 || vref0 < 0) ? vref0 : V0
    vmod_is_v0 = (pfflag == false && vflag == false && qflag == true)   # the branch of Vmod, in Julia (F-50)
    systems = @named begin
        PfFlag_logic = BooleanConstant(; k = pfflag)
        PfFlag = Switch()
        limiter1 = Limiter(; uMax = n.Qmax, uMin = n.Qmin)
        add1 = Add(; k2 = -1)
        Vflag_logic = BooleanConstant(; k = vflag)
        VFlag = Switch()
        limiter3 = Limiter(; uMax = n.Vmax, uMin = n.Vmin)
        add4 = Add(; k2 = -1)
        Vt_filt2 = RealExpression(; expr = nothing)      # y = VFilter.y (F-22)
        IQMAX_ = RealExpression(; expr = nothing)        # y = CCL_REECA.Iqmax
        IQMIN_ = RealExpression(; expr = nothing)        # y = CCL_REECA.Iqmin
        QFlag = Switch()
        QFLAG = BooleanConstant(; k = qflag)
        add6 = Add(; k2 = 1)
        variableLimiter = VariableLimiter()
        IQMIN = RealExpression(; expr = nothing)
        IQMAX = RealExpression(; expr = nothing)
        add7 = Add(; k2 = -1)
        integrator2 = Integrator(; k = 1 / n.Tiq, initType = :InitialState,
            y_start = -Iq0 - (-V0 + Vref0) * n.Kqv)
        Vt_filt1 = RealExpression(; expr = nothing)
        limiter4 = Limiter(; uMax = inf, uMin = 0.01)
        division = Division()
        VDL1 = CombiTable1Ds(; table = vdl1)
        VDL2 = CombiTable1Ds(; table = vdl2)
        integrator3 = Integrator(; k = 1 / n.Tpord, initType = :InitialState, y_start = Ip0 * V0)
        add8 = Add(; k2 = -1)
        limiter5 = Limiter(; uMax = n.dPmax, uMin = n.dPmin)
        limiter6 = Limiter(; uMax = n.Pmax, uMin = n.Pmin)
        product5 = Product()
        GeneratorSpeed = RealExpression(; expr = nothing)   # y = if pflag then Wg else 1
        division1 = Division()
        limiter7 = Limiter(; uMax = inf, uMin = 0.01)
        Vt_filt3 = RealExpression(; expr = nothing)
        variableLimiter1 = VariableLimiter()
        IPMAX = RealExpression(; expr = nothing)
        IPMIN = RealExpression(; expr = nothing)
        CCL_REECA = CurrentLimitLogicREECA(; start_ii = Iq0, start_ir = Ip0, Imax = n.Imax, pqflag)
        IQCMD = RealExpression(; expr = nothing)
        PQFLAG = BooleanConstant(; k = pqflag)
        IPCMD = RealExpression(; expr = nothing)
        add = Add(; k1 = -1)
        limiter = Limiter(; uMax = n.Iqh1, uMin = n.Iql1)
        VREF0 = RealExpression(; expr = nothing)         # y = Vref0
        dbd1_dbd2 = DeadZone(; uMax = n.dbd2, uMin = n.dbd1)
        gain2 = Gain(; k = n.Kqv)
        StateTransitionSwitch = Switch()
        State0 = OpenIPSLComponents.Constant(; k = 0)
        StateTransitionLogic = BooleanExpression(; expr = nothing)   # y = Voltage_dip
        simpleLag1 = SimpleLag(; K = 1, T = n.Tp, y_start = p00)
        tan1 = Tan()
        product1 = Product()
        PFAREF = RealExpression(; expr = nothing)        # y = pfangle
        add3 = Add()
        VBIAS = RealExpression(; expr = nothing)         # y = Vmod
        pI_No_Windup = PIwithVariableLimiter(; K_P = n.Kvp, K_I = n.Kvi,
            y_start = -Iq0 - (-V0 + Vref0) * n.Kqv)
        pI_No_Windup_notVariable = PIwithNoVariableLimiter(; K_P = n.Kqp, K_I = n.Kqi,
            V_RMAX = n.Vmax, V_RMIN = n.Vmin, y_start = V0)
        VLogic = BooleanExpression(; expr = nothing)     # y = Voltage_dip
        VFilter = SimpleLag(; K = 1, T = n.Trv, y_start = V0)
    end
    vars = @variables begin
        Voltage_dip(t), [description = "Voltage dip flag (0/1)"]
        Vmod(t)
    end
    eqs = Equation[
        Voltage_dip ~ ifelse((Vt < Vdip) | (Vt > Vup), 1.0, 0.0),
        Vmod ~ (vmod_is_v0 ? V0 - PfFlag.y : n.Vbias),
        # the expression blocks whose `y` reads a variable or a derived parameter of this model (F-22)
        Vt_filt1.y ~ VFilter.y, Vt_filt2.y ~ VFilter.y, Vt_filt3.y ~ VFilter.y,
        IQMAX.y ~ CCL_REECA.Iqmax, IQMIN.y ~ CCL_REECA.Iqmin,
        IQMAX_.y ~ CCL_REECA.Iqmax, IQMIN_.y ~ CCL_REECA.Iqmin,
        IPMAX.y ~ CCL_REECA.Ipmax, IPMIN.y ~ CCL_REECA.Ipmin,
        IQCMD.y ~ Iqcmd, IPCMD.y ~ Ipcmd,
        VREF0.y ~ Vref0,
        PFAREF.y ~ pfangle,
        VBIAS.y ~ Vmod,
        GeneratorSpeed.y ~ (pflag ? Wg : 1.0),
        StateTransitionLogic.y ~ Voltage_dip,
        VLogic.y ~ Voltage_dip,
        # the .mo's connects, in its own order
        VREF0.y ~ add.u2,
        dbd1_dbd2.y ~ gain2.u,
        add.y ~ dbd1_dbd2.u,
        gain2.y ~ limiter.u,
        limiter.y ~ StateTransitionSwitch.u3,
        State0.y ~ StateTransitionSwitch.u1,
        StateTransitionLogic.y ~ StateTransitionSwitch.u2,
        simpleLag1.y ~ product1.u1,
        tan1.y ~ product1.u2,
        Pe ~ simpleLag1.u,
        PFAREF.y ~ tan1.u,
        Qext ~ PfFlag.u3,
        product1.y ~ PfFlag.u1,
        PfFlag_logic.y ~ PfFlag.u2,
        PfFlag.y ~ limiter1.u,
        limiter1.y ~ add1.u1,
        Qgen ~ add1.u2,
        Vflag_logic.y ~ VFlag.u2,
        limiter3.y ~ add4.u1,
        Vt_filt2.y ~ add4.u2,
        VFlag.y ~ limiter3.u,
        QFLAG.y ~ QFlag.u2,
        add6.y ~ variableLimiter.u,
        IQMIN.y ~ variableLimiter.limit2,
        IQMAX.y ~ variableLimiter.limit1,
        QFlag.y ~ add6.u2,
        add6.u1 ~ StateTransitionSwitch.y,
        Vt_filt1.y ~ limiter4.u,
        limiter4.y ~ division.u2,
        division.u1 ~ limiter1.u,
        division.y ~ add7.u1,
        integrator2.y ~ QFlag.u3,
        add7.u2 ~ QFlag.u3,
        VDL2.u ~ limiter4.u,
        VDL1.u ~ limiter4.u,
        add8.y ~ limiter5.u,
        integrator3.y ~ add8.u2,
        integrator3.y ~ limiter6.u,
        GeneratorSpeed.y ~ product5.u1,
        limiter6.y ~ division1.u1,
        limiter7.y ~ division1.u2,
        Vt_filt3.y ~ limiter7.u,
        division1.y ~ variableLimiter1.u,
        IPMIN.y ~ variableLimiter1.limit2,
        IPMAX.y ~ variableLimiter1.limit1,
        VDL2.y[1] ~ CCL_REECA.VDL2_out,
        VDL1.y[1] ~ CCL_REECA.VDL1_out,
        PQFLAG.y ~ CCL_REECA.pqflag,
        IQCMD.y ~ CCL_REECA.Iqcmd,
        IPCMD.y ~ CCL_REECA.Ipcmd,
        add3.y ~ VFlag.u3,
        add3.u2 ~ limiter1.u,
        VBIAS.y ~ add3.u1,
        add7.y ~ integrator2.u,
        limiter5.y ~ integrator3.u,
        product5.y ~ add8.u1,
        product5.u2 ~ Pref,
        add4.y ~ pI_No_Windup.u,
        IQMAX_.y ~ pI_No_Windup.limit1,
        IQMIN_.y ~ pI_No_Windup.limit2,
        pI_No_Windup.y ~ QFlag.u1,
        add1.y ~ pI_No_Windup_notVariable.u,
        pI_No_Windup_notVariable.y ~ VFlag.u1,
        VFilter.y ~ add.u1,
        VFilter.u ~ Vt,
        variableLimiter1.y ~ Ipcmd,
        variableLimiter.y ~ Iqcmd,
        VLogic.y ~ pI_No_Windup.voltage_dip,
        VLogic.y ~ pI_No_Windup_notVariable.voltage_dip,
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            initial_conditions = Dict(Ip0 => missing, Iq0 => missing, V0 => missing,
                p00 => missing, q00 => missing),
            initialization_eqs = [Ip0 ~ ip0, Iq0 ~ iq0, V0 ~ v0, p00 ~ p0, q00 ~ q0]), base)
end
