# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Renewables/PSSE/ElectricalController/REECCU1.mo (extends BaseClasses/BaseREECC.mo)
# The electrical controller of a utility-scale battery: `REECB1`'s structure plus the two VDL tables
# (`CombiTable1Ds` with `HoldLastPoint`, new in this batch) feeding `CurrentLimitLogicREECC`, the state-of-charge
# logic, and the auxiliary power input `Paux`. Blocks with the .mo's own names.
# The five `fixed = false` parameters, `pfaref`/`pfangle` (a symbolic `ifelse` on a `missing` value) and `Vref0`
# are exactly as in `REECB1.jl` (F-33, F-38, F-50); see that file's header.
# `Voltage_dip` is an Integer 0/1 here as well, and `frzState`/`frzState1`/`frzState2` freeze the three integrators.
# `integrator1(k = 1/T, y_start = p00)` is the charge integral: with the default `T = 999` and `SOCini = 0.5`
# inside [SOCmin, SOCmax] = [0.2, 0.8], both state-of-charge flags stay at 1 for a whole 5 s run.
# The VDL tables are assembled as numeric matrices before `@parameters` (F-22, point 1).
# Omitted: Icons.VerifiedModel, graphical annotations.

@component function REECCU1(; name, pfflag = true, vflag = true, qflag = true, pqflag = true,
        Vdip = -99, Vup = 99, Trv = 0.01, dbd1 = 0, dbd2 = 0, Kqv = 0, Iqh1 = 1, Iql1 = -1,
        vref0 = 1, Tp = 0.01, Qmax = 1, Qmin = -1, Vmax = 1.1, Vmin = 0.9, Kqp = 0, Kqi = 0.1,
        Kvp = 0, Kvi = 40, Tiq = 0.01, dPmax = 99, dPmin = -99, Pmax = 1, Pmin = 0, Imax = 1.1, Tpord = 0.02,
        Vq1 = 0.2, Iq1 = 0.75, Vq2 = 0.5, Iq2 = 0.75, Vq3 = 0.75, Iq3 = 0.75, Vq4 = 1, Iq4 = 0.75,
        Vp1 = 0.2, Ip1 = 1.11, Vp2 = 0.5, Ip2 = 1.11, Vp3 = 0.75, Ip3 = 1.11, Vp4 = 1, Ip4 = 1.11,
        T = 999, SOCini = 0.5, SOCmax = 0.8, SOCmin = 0.2)
    Vdip, Vup, Trv, dbd1, dbd2, Kqv, Iqh1, Iql1, vref0 =
        float.((Vdip, Vup, Trv, dbd1, dbd2, Kqv, Iqh1, Iql1, vref0))
    Tp, Qmax, Qmin, Vmax, Vmin, Kqp, Kqi, Kvp, Kvi, Tiq =
        float.((Tp, Qmax, Qmin, Vmax, Vmin, Kqp, Kqi, Kvp, Kvi, Tiq))
    dPmax, dPmin, Pmax, Pmin, Imax, Tpord = float.((dPmax, dPmin, Pmax, Pmin, Imax, Tpord))
    T, SOCini, SOCmax, SOCmin = float.((T, SOCini, SOCmax, SOCmin))
    vdl1 = float.([Vq1 Iq1; Vq2 Iq2; Vq3 Iq3; Vq4 Iq4])     # numeric tables before @parameters (F-22)
    vdl2 = float.([Vp1 Ip1; Vp2 Ip2; Vp3 Ip3; Vp4 Ip4])
    n = (; Trv, dbd1, dbd2, Kqv, Iqh1, Iql1, Tp, Qmax, Qmin, Vmax, Vmin, Kqp, Kqi, Kvp, Kvi, Tiq,
        dPmax, dPmin, Pmax, Pmin, Imax, Tpord, T, SOCini, SOCmax, SOCmin)
    inf = Modelica.Constants.inf
    base = BaseREECC(; name)
    @unpack Vt, Pe, Qext, Qgen, Pref, Paux, ip0, iq0, Iqcmd, Ipcmd, v0, p0, q0 = base
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
    pfangle = ifelse(q00 > 0, acos(pfaref), -acos(pfaref))     # symbolic: q00 does not exist yet (REECB1.jl header)
    Vref0 = (vref0 > 0 || vref0 < 0) ? vref0 : V0
    systems = @named begin
        division1 = Division()
        limiter5 = Limiter(; uMax = inf, uMin = 0.01)
        add8 = Add(; k2 = -1)
        limiter7 = Limiter(; uMax = n.dPmax, uMin = n.dPmin)
        integrator3 = Integrator(; k = 1 / n.Tpord, initType = :InitialState, y_start = Ip0 * V0)
        limiter8 = Limiter(; uMax = n.Pmax, uMin = n.Pmin)
        Vt_filt3 = RealExpression(; expr = nothing)      # y = simpleLag.y (F-22)
        add7 = Add(; k1 = 1, k2 = 1)
        variableLimiter2 = VariableLimiter()
        product2 = Product()
        product3 = Product()
        SOC_ipmax = RealExpression(; expr = nothing)     # y = sOC_logic.ipmax_SOC
        SOC_ipmin = RealExpression(; expr = nothing)     # y = sOC_logic.ipmin_SOC
        PELEC = RealExpression(; expr = nothing)         # y = Pe
        integrator1 = Integrator(; k = 1 / n.T, initType = :InitialState, y_start = p00)
        add1 = Add(; k1 = -1, k2 = 1)
        limiter1 = Limiter(; uMax = n.SOCmax, uMin = n.SOCmin)
        sOC_logic = StateOfChargeLogic(; SOCmin = n.SOCmin, SOCmax = n.SOCmax)
        PfFlag_logic = BooleanConstant(; k = pfflag)
        PfFlag = Switch()
        limiter2 = Limiter(; uMax = n.Qmax, uMin = n.Qmin)
        add2 = Add(; k2 = -1)
        integrator = Integrator(; k = n.Kqi, initType = :InitialState, y_start = V0)
        gain = Gain(; k = n.Kqp)
        add3 = Add()
        frzState = RealExpression(; expr = nothing)      # y = if Voltage_dip == 1 then 0 else 1
        product1 = Product()
        limiter3 = Limiter(; uMax = n.Vmax, uMin = n.Vmin)
        Vflag_logic = BooleanConstant(; k = vflag)
        VFlag = Switch()
        limiter4 = Limiter(; uMax = n.Vmax, uMin = n.Vmin)
        add5 = Add(; k2 = -1)
        Vt_filt2 = RealExpression(; expr = nothing)
        gain1 = Gain(; k = n.Kvp)
        integrator2 = Integrator(; k = n.Kvi, initType = :InitialState,
            y_start = -Iq0 - (-V0 + Vref0) * n.Kqv)
        add6 = Add()
        product4 = Product()
        frzState1 = RealExpression(; expr = nothing)
        variableLimiter1 = VariableLimiter()
        QFlag = Switch()
        QFLAG = BooleanConstant(; k = qflag)
        add9 = Add(; k2 = 1)
        variableLimiter = VariableLimiter()
        IQMIN = RealExpression(; expr = nothing)         # y = ccl_reecc.Iqmin
        IQMAX = RealExpression(; expr = nothing)         # y = ccl_reecc.Iqmax
        IQMIN_ = RealExpression(; expr = nothing)
        IQMAX_ = RealExpression(; expr = nothing)
        IPMIN = RealExpression(; expr = nothing)         # y = ccl_reecc.Ipmin
        IPMAX = RealExpression(; expr = nothing)         # y = ccl_reecc.Ipmax
        add10 = Add(; k2 = -1)
        integrator4 = Integrator(; k = 1 / n.Tiq, initType = :InitialState,
            y_start = -Iq0 - (-V0 + Vref0) * n.Kqv)
        product5 = Product()
        Vt_filt1 = RealExpression(; expr = nothing)
        limiter6 = Limiter(; uMax = inf, uMin = 0.01)
        division = Division()
        VDL1 = CombiTable1Ds(; table = vdl1, smoothness = :LinearSegments, extrapolation = :HoldLastPoint)
        VDL2 = CombiTable1Ds(; table = vdl2, smoothness = :LinearSegments, extrapolation = :HoldLastPoint)
        ccl_reecc = CurrentLimitLogicREECC(; start_ii = -Iq0, start_ir = Ip0, Imax = n.Imax, pqflag)
        IQCMD = RealExpression(; expr = nothing)         # y = Iqcmd
        PQFLAG = BooleanConstant(; k = pqflag)
        IPCMD = RealExpression(; expr = nothing)         # y = Ipcmd
        simpleLag = SimpleLag(; K = 1, T = n.Trv, y_start = V0)
        add = Add(; k1 = -1)
        limiter = Limiter(; uMax = n.Iqh1, uMin = n.Iql1)
        VREF0 = RealExpression(; expr = nothing)         # y = Vref0
        dbd1_dbd2 = DeadZone(; uMax = n.dbd2, uMin = n.dbd1)
        gain2 = Gain(; k = n.Kqv)
        simpleLag1 = SimpleLag(; K = 1, T = n.Tp, y_start = p00)
        tan1 = Tan()
        product6 = Product()
        PFAREF = RealExpression(; expr = nothing)        # y = pfangle
        product7 = Product()
        frzState2 = RealExpression(; expr = nothing)
        VReF0 = RealExpression(; expr = nothing)         # y = Vref0 (the .mo's second instance, sic)
        SOC = OpenIPSLComponents.Constant(; k = n.SOCini)
    end
    vars = @variables begin
        Voltage_dip(t), [description = "Voltage dip flag (0/1)"]
    end
    frz = ifelse(Voltage_dip > 0.5, 0.0, 1.0)     # `if Voltage_dip == 1 then 0 else 1`
    eqs = Equation[
        Voltage_dip ~ ifelse((Vt < Vdip) | (Vt > Vup), 1.0, 0.0),
        # the expression blocks whose `y` reads a variable or a derived parameter of this model (F-22)
        frzState.y ~ frz, frzState1.y ~ frz, frzState2.y ~ frz,
        Vt_filt1.y ~ simpleLag.y, Vt_filt2.y ~ simpleLag.y, Vt_filt3.y ~ simpleLag.y,
        SOC_ipmax.y ~ sOC_logic.ipmax_SOC,
        SOC_ipmin.y ~ sOC_logic.ipmin_SOC,
        PELEC.y ~ Pe,
        IQMIN.y ~ ccl_reecc.Iqmin, IQMAX.y ~ ccl_reecc.Iqmax,
        IQMIN_.y ~ ccl_reecc.Iqmin, IQMAX_.y ~ ccl_reecc.Iqmax,
        IPMIN.y ~ ccl_reecc.Ipmin, IPMAX.y ~ ccl_reecc.Ipmax,
        IQCMD.y ~ Iqcmd, IPCMD.y ~ Ipcmd,
        VREF0.y ~ Vref0, VReF0.y ~ Vref0,
        PFAREF.y ~ pfangle,
        # the .mo's connects, in its own order
        limiter5.y ~ division1.u2,
        add8.y ~ limiter7.u,
        integrator3.y ~ limiter8.u,
        add8.u2 ~ limiter8.u,
        Vt_filt3.y ~ limiter5.u,
        add8.u1 ~ Pref,
        limiter8.y ~ division1.u1,
        division1.y ~ add7.u1,
        Paux ~ add7.u2,
        variableLimiter2.y ~ Ipcmd,
        add7.y ~ variableLimiter2.u,
        product2.y ~ variableLimiter2.limit1,
        IPMAX.y ~ product2.u1,
        product3.u2 ~ IPMIN.y,
        variableLimiter2.limit2 ~ product3.y,
        product2.u2 ~ SOC_ipmax.y,
        product3.u1 ~ SOC_ipmin.y,
        PELEC.y ~ integrator1.u,
        integrator1.y ~ add1.u1,
        add1.y ~ limiter1.u,
        limiter1.y ~ sOC_logic.SOC,
        simpleLag.y ~ add.u1,
        VREF0.y ~ add.u2,
        dbd1_dbd2.y ~ gain2.u,
        add.y ~ dbd1_dbd2.u,
        gain2.y ~ limiter.u,
        simpleLag1.y ~ product6.u1,
        tan1.y ~ product6.u2,
        Pe ~ simpleLag1.u,
        PFAREF.y ~ tan1.u,
        Qext ~ PfFlag.u3,
        product6.y ~ PfFlag.u1,
        PfFlag_logic.y ~ PfFlag.u2,
        PfFlag.y ~ limiter2.u,
        limiter2.y ~ add2.u1,
        Qgen ~ add2.u2,
        gain.y ~ add3.u1,
        integrator.y ~ add3.u2,
        product1.y ~ integrator.u,
        frzState.y ~ product1.u2,
        add3.y ~ limiter3.u,
        limiter3.y ~ VFlag.u1,
        Vflag_logic.y ~ VFlag.u2,
        limiter4.y ~ add5.u1,
        Vt_filt2.y ~ add5.u2,
        VFlag.y ~ limiter4.u,
        gain1.y ~ add6.u1,
        integrator2.y ~ add6.u2,
        frzState1.y ~ product4.u2,
        product4.y ~ integrator2.u,
        add6.y ~ variableLimiter1.u,
        IQMAX_.y ~ variableLimiter1.limit1,
        variableLimiter1.y ~ QFlag.u1,
        QFLAG.y ~ QFlag.u2,
        IQMIN_.y ~ variableLimiter1.limit2,
        add9.y ~ variableLimiter.u,
        IQMIN.y ~ variableLimiter.limit2,
        IQMAX.y ~ variableLimiter.limit1,
        QFlag.y ~ add9.u2,
        add10.y ~ product5.u2,
        Vt_filt1.y ~ limiter6.u,
        limiter6.y ~ division.u2,
        division.u1 ~ limiter2.u,
        division.y ~ add10.u1,
        integrator4.y ~ QFlag.u3,
        add10.u2 ~ QFlag.u3,
        product5.y ~ integrator4.u,
        product5.u1 ~ product4.u2,
        VDL2.u ~ limiter6.u,
        VDL1.u ~ limiter6.u,
        VDL2.y[1] ~ ccl_reecc.VDL2_out,
        VDL1.y[1] ~ ccl_reecc.VDL1_out,
        PQFLAG.y ~ ccl_reecc.pqflag,
        IQCMD.y ~ ccl_reecc.Iqcmd,
        IPCMD.y ~ ccl_reecc.Ipcmd,
        limiter.y ~ add9.u1,
        variableLimiter.y ~ Iqcmd,
        Vt ~ simpleLag.u,
        product1.u1 ~ add2.y,
        gain.u ~ product1.y,
        gain1.u ~ integrator2.u,
        product4.u1 ~ add5.y,
        product7.y ~ integrator3.u,
        limiter7.y ~ product7.u2,
        frzState2.y ~ product7.u1,
        VReF0.y ~ VFlag.u3,
        SOC.y ~ add1.u2,
    ]
    extend(System(eqs, t, vars, pars; name, systems,
            initial_conditions = Dict(Ip0 => missing, Iq0 => missing, V0 => missing,
                p00 => missing, q00 => missing),
            initialization_eqs = [Ip0 ~ ip0, Iq0 ~ iq0, V0 ~ v0, p00 ~ p0, q00 ~ q0]), base)
end
