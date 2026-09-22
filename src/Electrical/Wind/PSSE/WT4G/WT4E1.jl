# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSSE/WT4G/WT4E1.mo (extends nothing: no S_b, no fn)
# The electrical control of the type-4 wind generator, and the **first .mo of the port with local classes**: the
# three `protected model`s `ActivePowerController`, `pf_Controller`, `windControlEmulator` are the three
# `@component function`s `WT4E1_ActivePowerController`, `WT4E1_pf_Controller`, `WT4E1_windControlEmulator` of this
# file (they are not classes of the inventory).
# Top-level blocks, with the names of the .mo: Qord = Limiter(QMN, QMX), feedback1, K6 = LimIntegrator(VMINCL,
# VMAXCL, k = KQI, y_start = k60), Vcl = Feedback, cCL = CCL(Qmax = QMX, ImaxTD, Iphl, Iqhl, pqflag = PQFLAG),
# Qcmd0 = Constant(Qref), activePowerController, PF_Controller, windControlEmulator1, switch_QREF + ControlPF =
# BooleanConstant(PFAFLG), switch_WindVar + UseWindVar = BooleanConstant(VARFLG) (the `if`s on Boolean parameters
# instantiated literally, precedent REGCA1), integratorLimVar = IntegratorLimVar(K = KVI, y_start = k70) with the
# variable limits `cCL.IQmax`/`cCL.IQmin`. Ports are plain variables (P, Q, V; WIPCMD, WIQCMD).
# The 17 `fixed = false` protected parameters and their `initial equation` (F-33, F-38, the REECA1 form): `p0`,
# `q0`, `v0` are resolved from the **inputs** P, Q, V -> `missing` parameters with `initialization_eqs`; `Vref =
# v0`, `Pref = p0`, `Qref = q0`, `PFA_ref = atan2(q0, p0)`, `k0 = k10 = q0`, `k40 = k60 = v0`, `k50 = p0`, `k70 =
# q0/v0`, `k20 = k30 = k80 = 0` are symbolic expressions of those three that reach the blocks as `y_start`
# bindings (`k40`, "may be incorrect !" in the .mo, is v0 all the same); `Ip0 = WIPCMD`, `Iq0 = WIQCMD`, `Pord0 =
# v0*Ip0`, `k90 = p0` are resolved from the model's own **outputs** and read by nothing: dead, not declared
# (precedent `start_ii`/`start_ir` of REEC*). OpenModelica 1.25 cannot translate the Test of this model precisely
# because of that `initial equation` (F-70): there is no oracle; `test_WT4E1.jl` validates it by hand.
# `IPMAX` is a dead parameter (the active limit is `cCL.IPmax`, sic). `Kf = 0` makes `K3` a `Derivative` with
# `zeroGain` (Derivative.jl decides). With `PSSEMATCH = true` the emulator's integrator receives 0 and stays at
# `k10` ("ignore integrator" = feed it zero, sic). The numeric keyword arguments reach the sub-blocks before the
# `@parameters` block rebinds their names (F-22); only the three `missing` parameters are declared first, because
# the `k*` bindings are expressions of them. Omitted: graphical annotations.

@component function WT4E1_ActivePowerController(; name, Kpp, KIP, Kf, Tf, dPMX, dPMN, T_Power, Pref, k20, k30, k50, p0)
    Kpp, KIP, Kf, Tf, dPMX, dPMN, T_Power = float.((Kpp, KIP, Kf, Tf, dPMX, dPMN, T_Power))
    inf = Modelica.Constants.inf
    systems = @named begin
        imLimited_max = VariableLimiter()
        division = Division()
        imLimited_min = Limiter(; uMin = 0.01, uMax = inf)
        add3_1 = Add3(; k1 = -1, k3 = -1)
        VAR3 = OpenIPSLComponents.Constant(; k = Pref)
        gain = Gain(; k = Kpp)
        K2 = LimIntegrator(; y_start = k20, outMin = dPMN, outMax = dPMX, k = KIP)
        Pord = Add(; k2 = -1)
        Pord1 = Add()
        K3 = Derivative(; k = Kf, T = Tf, initType = :InitialState, x_start = k30)
        K5 = SimpleLag(; K = 1, T = T_Power, y_start = k50)
        NoLimiMin = OpenIPSLComponents.Constant(; k = -inf)
    end
    pars = @parameters begin
        Kpp = Kpp, [description = "Proportional gain in torque regulator"]
        KIP = KIP, [description = "Integrator gain in torque regulator"]
        Kf = Kf, [description = "Rate feedback gain"]
        Tf = Tf, [description = "Rate feedback time constant (s)"]
        dPMX = dPMX, [description = "Max limit in power PI controller"]
        dPMN = dPMN, [description = "Min limit in power PI controller"]
        T_Power = T_Power, [description = "Power filter time constant (s)"]
    end
    vars = @variables begin
        PELEC(t)
        I_PMAX(t)
        ipcmd(t)
        VTERM(t)
    end
    eqs = Equation[
        VAR3.y ~ add3_1.u1,                  # connect(VAR3.y, add3_1.u1)
        gain.y ~ Pord1.u2,                   # connect(gain.y, Pord1.u2)
        K3.y ~ add3_1.u3,                    # connect(K3.y, add3_1.u3)
        add3_1.y ~ K2.u,                     # connect(add3_1.y, K2.u)
        gain.u ~ add3_1.y,                   # connect(gain.u, add3_1.y)
        K5.y ~ add3_1.u2,                    # connect(K5.y, add3_1.u2)
        K2.y ~ Pord1.u1,                     # connect(K2.y, Pord1.u1)
        division.y ~ imLimited_max.u,        # connect(division.y, imLimited_max.u)
        imLimited_min.y ~ division.u2,       # connect(imLimited_min.y, division.u2)
        NoLimiMin.y ~ imLimited_max.limit2,  # connect(NoLimiMin.y, imLimited_max.limit2)
        Pord.y ~ division.u1,                # connect(Pord.y, division.u1)
        Pord1.y ~ Pord.u2,                   # connect(Pord1.y, Pord.u2)
        Pord.u1 ~ add3_1.u1,                 # connect(Pord.u1, add3_1.u1)
        K3.u ~ Pord.u2,                      # connect(K3.u, Pord.u2)
        PELEC ~ K5.u,                        # connect(PELEC, K5.u)
        ipcmd ~ imLimited_max.y,             # connect(ipcmd, imLimited_max.y)
        VTERM ~ imLimited_min.u,             # connect(VTERM, imLimited_min.u)
        I_PMAX ~ imLimited_max.limit1,       # connect(I_PMAX, imLimited_max.limit1)
    ]
    System(eqs, t, vars, pars; name, systems)
end

@component function WT4E1_pf_Controller(; name, Tp = 0.50000E-01, PFA_ref, p0, q0)
    Tp = float(Tp)
    systems = @named begin
        tan1 = Tan()
        Qcmdn1 = Product()
        VAR2 = OpenIPSLComponents.Constant(; k = PFA_ref)
        K0 = SimpleLag(; K = 1, y_start = p0, T = Tp)
    end
    pars = @parameters begin
        Tp = Tp, [description = "Pelec filter in fast PF controller (s)"]
    end
    vars = @variables begin
        u(t)
        Q_REF_PF(t)
    end
    eqs = Equation[
        tan1.y ~ Qcmdn1.u1,                  # connect(tan1.y, Qcmdn1.u1)
        K0.y ~ Qcmdn1.u2,                    # connect(K0.y, Qcmdn1.u2)
        VAR2.y ~ tan1.u,                     # connect(VAR2.y, tan1.u)
        u ~ K0.u,                            # connect(u, K0.u)
        Qcmdn1.y ~ Q_REF_PF,                 # connect(Qcmdn1.y, Q_REF_PF)
    ]
    System(eqs, t, vars, pars; name, systems)
end

@component function WT4E1_windControlEmulator(; name, Tfv, Kpv, KIV, QMX, QMN, TRV, Tv = 0.50000E-01, Vref, k0, k10,
        k40, k80, PSSEMATCH)
    Tfv, Kpv, KIV, QMX, QMN, TRV, Tv = float.((Tfv, Kpv, KIV, QMX, QMN, TRV, Tv))
    systems = @named begin
        K = SimpleLag(; K = 1, T = Tfv, y_start = k0)
        add3 = Add(; k2 = -1)
        VARL = OpenIPSLComponents.Constant(; k = Vref)
        add4 = Add()
        Qord1 = Limiter(; uMin = QMN, uMax = QMX)
        K8 = SimpleLag(; K = Kpv, y_start = k80, T = Tv)
        K8_extra = SimpleLag(; y_start = k40, K = 1, T = TRV)
        integrator = Integrator(; k = KIV, initType = :InitialOutput, y_start = k10)
        VARL1 = OpenIPSLComponents.Constant(; k = 0)
        booleanConstant = BooleanConstant(; k = PSSEMATCH)
        switch1 = Switch()
    end
    pars = @parameters begin
        Tfv = Tfv, [description = "Filter time constant in voltage regulator (s)"]
        Kpv = Kpv, [description = "Proportional gain in voltage regulator"]
        KIV = KIV, [description = "Integrator gain in voltage regulator"]
        QMX = QMX, [description = "Max limit in voltage regulator"]
        QMN = QMN, [description = "Min limit in voltage regulator"]
        TRV = TRV, [description = "Voltage sensor time constant (s)"]
        Tv = Tv, [description = "Lag time constant in WindVar controller (s)"]
    end
    vars = @variables begin
        V_REG(t)
        Q_ord(t)
    end
    eqs = Equation[
        add4.y ~ Qord1.u,                    # connect(add4.y, Qord1.u)
        Qord1.y ~ K.u,                       # connect(Qord1.y, K.u)
        VARL.y ~ add3.u1,                    # connect(VARL.y, add3.u1)
        K.y ~ Q_ord,                         # connect(K.y, Q_ord)
        add3.u2 ~ K8_extra.y,                # connect(add3.u2, K8_extra.y)
        K8_extra.u ~ V_REG,                  # connect(K8_extra.u, V_REG)
        K8.y ~ add4.u2,                      # connect(K8.y, add4.u2)
        add3.y ~ K8.u,                       # connect(add3.y, K8.u)
        integrator.y ~ add4.u1,              # connect(integrator.y, add4.u1)
        integrator.u ~ switch1.y,            # connect(integrator.u, switch1.y)
        VARL1.y ~ switch1.u1,                # connect(VARL1.y, switch1.u1)
        switch1.u3 ~ K8.u,                   # connect(switch1.u3, K8.u)
        booleanConstant.y ~ switch1.u2,      # connect(booleanConstant.y, switch1.u2)
    ]
    System(eqs, t, vars, pars; name, systems)
end

@component function WT4E1(; name, PFAFLG, VARFLG, PQFLAG, Tfv, Kpv, KIV, Kpp, KIP, Kf, Tf, QMX, QMN, IPMAX, TRV, dPMX,
        dPMN, T_Power, KQI, VMINCL = 0.9, VMAXCL = 1.1, KVI = 120, Tv = 0.50000E-01, Tp = 0.50000E-01, ImaxTD = 1.7,
        Iphl = 1.11, Iqhl = 1.11, PSSEMATCH)
    Tfv, Kpv, KIV, Kpp, KIP, Kf, Tf, QMX, QMN, IPMAX, TRV, dPMX, dPMN, T_Power, KQI =
        float.((Tfv, Kpv, KIV, Kpp, KIP, Kf, Tf, QMX, QMN, IPMAX, TRV, dPMX, dPMN, T_Power, KQI))
    VMINCL, VMAXCL, KVI, Tv, Tp, ImaxTD, Iphl, Iqhl = float.((VMINCL, VMAXCL, KVI, Tv, Tp, ImaxTD, Iphl, Iqhl))
    pars0 = @parameters begin
        p0, [guess = 1.0]
        q0, [guess = 0.0]
        v0, [guess = 1.0]
    end
    # the protected parameters resolved from p0, q0, v0 (F-38: symbolic bindings for the blocks)
    Vref = v0
    Pref = p0
    Qref = q0
    PFA_ref = atan(q0, p0)   # atan2(q0, p0)
    k0 = q0
    k10 = q0
    k80 = 0.0
    k40 = v0
    k50 = p0
    k20 = 0.0
    k30 = 0.0
    k60 = v0
    k70 = q0 / v0
    systems = @named begin
        Qord = Limiter(; uMin = QMN, uMax = QMX)
        feedback1 = Feedback()
        K6 = LimIntegrator(; outMin = VMINCL, outMax = VMAXCL, k = KQI, y_start = k60)
        Vcl = Feedback()
        cCL = CCL(; Qmax = QMX, ImaxTD, Iphl, Iqhl, pqflag = PQFLAG)
        Qcmd0 = OpenIPSLComponents.Constant(; k = Qref)
        activePowerController = WT4E1_ActivePowerController(; Kpp, KIP, Kf, Tf, dPMX, dPMN, T_Power, Pref, k20, k30, k50, p0)
        PF_Controller = WT4E1_pf_Controller(; Tp, PFA_ref, p0, q0)
        windControlEmulator1 = WT4E1_windControlEmulator(; Tfv, Kpv, KIV, QMX, QMN, TRV, Tv, Vref, k0, k10, k40, k80, PSSEMATCH)
        switch_QREF = Switch()
        ControlPF = BooleanConstant(; k = PFAFLG)
        switch_WindVar = Switch()
        UseWindVar = BooleanConstant(; k = VARFLG)
        integratorLimVar = IntegratorLimVar(; K = KVI, y_start = k70)
    end
    pars = @parameters begin
        Tfv = Tfv, [description = "Filter time constant in voltage regulator (s)"]
        Kpv = Kpv, [description = "Proportional gain in voltage regulator"]
        KIV = KIV, [description = "Integrator gain in voltage regulator"]
        Kpp = Kpp, [description = "Proportional gain in torque regulator"]
        KIP = KIP, [description = "Integrator gain in torque regulator"]
        Kf = Kf, [description = "Rate feedback gain"]
        Tf = Tf, [description = "Rate feedback time constant (s)"]
        QMX = QMX, [description = "Max limit in voltage regulator"]
        QMN = QMN, [description = "Min limit in voltage regulator"]
        IPMAX = IPMAX, [description = "Max active current limit (dead)"]
        TRV = TRV, [description = "Voltage sensor time constant (s)"]
        dPMX = dPMX, [description = "Max limit in power PI controller"]
        dPMN = dPMN, [description = "Min limit in power PI controller"]
        T_Power = T_Power, [description = "Power filter time constant (s)"]
        KQI = KQI, [description = "Mvar/Voltage gain"]
        VMINCL = VMINCL, [description = "Min voltage limit"]
        VMAXCL = VMAXCL, [description = "Max voltage limit"]
        KVI = KVI, [description = "Voltage/Mvar gain"]
        Tv = Tv, [description = "Lag time constant in WindVar controller (s)"]
        Tp = Tp, [description = "Pelec filter in fast PF controller (s)"]
        ImaxTD = ImaxTD, [description = "Converter current limit"]
        Iphl = Iphl, [description = "Hard active current limit"]
        Iqhl = Iqhl, [description = "Hard reactive current limit"]
    end
    vars = @variables begin
        P(t)
        Q(t)
        V(t)
        WIPCMD(t)
        WIQCMD(t)
    end
    eqs = Equation[
        Q ~ feedback1.u2,                                    # connect(Q, feedback1.u2)
        V ~ Vcl.u2,                                          # connect(V, Vcl.u2)
        cCL.Vt ~ V,                                          # connect(cCL.Vt, V)
        Qord.y ~ feedback1.u1,                               # connect(Qord.y, feedback1.u1)
        K6.u ~ feedback1.y,                                  # connect(K6.u, feedback1.y)
        cCL.IqCMD ~ WIQCMD,                                  # connect(cCL.IqCMD, WIQCMD)
        activePowerController.ipcmd ~ WIPCMD,                # connect(activePowerController.ipcmd, WIPCMD)
        activePowerController.VTERM ~ Vcl.u2,                # connect(activePowerController.VTERM, Vcl.u2)
        P ~ PF_Controller.u,                                 # connect(P, PF_Controller.u)
        activePowerController.PELEC ~ PF_Controller.u,       # connect(activePowerController.PELEC, PF_Controller.u)
        windControlEmulator1.V_REG ~ Vcl.u2,                 # connect(windControlEmulator1.V_REG, Vcl.u2)
        ControlPF.y ~ switch_QREF.u2,                        # connect(ControlPF.y, switch_QREF.u2)
        PF_Controller.Q_REF_PF ~ switch_QREF.u1,             # connect(PF_Controller.Q_REF_PF, switch_QREF.u1)
        Qcmd0.y ~ switch_QREF.u3,                            # connect(Qcmd0.y, switch_QREF.u3)
        switch_QREF.y ~ switch_WindVar.u3,                   # connect(switch_QREF.y, switch_WindVar.u3)
        windControlEmulator1.Q_ord ~ switch_WindVar.u1,      # connect(windControlEmulator1.Q_ord, switch_WindVar.u1)
        UseWindVar.y ~ switch_WindVar.u2,                    # connect(UseWindVar.y, switch_WindVar.u2)
        switch_WindVar.y ~ Qord.u,                           # connect(switch_WindVar.y, Qord.u)
        K6.y ~ Vcl.u1,                                       # connect(K6.y, Vcl.u1)
        cCL.IpCMD ~ WIPCMD,                                  # connect(cCL.IpCMD, WIPCMD)
        activePowerController.I_PMAX ~ cCL.IPmax,            # connect(activePowerController.I_PMAX, cCL.IPmax)
        Vcl.y ~ integratorLimVar.u,                          # connect(Vcl.y, integratorLimVar.u)
        integratorLimVar.y ~ WIQCMD,                         # connect(integratorLimVar.y, WIQCMD)
        cCL.IQmin ~ integratorLimVar.outMin,                 # connect(cCL.IQmin, integratorLimVar.outMin)
        cCL.IQmax ~ integratorLimVar.outMax,                 # connect(cCL.IQmax, integratorLimVar.outMax)
    ]
    System(eqs, t, vars, [pars0; pars]; name, systems,
        initial_conditions = Dict(p0 => missing, q0 => missing, v0 => missing),
        initialization_eqs = [p0 ~ P, q0 ~ Q, v0 ~ V])
end
