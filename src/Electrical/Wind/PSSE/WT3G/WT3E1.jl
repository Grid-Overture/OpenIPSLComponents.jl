# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSSE/WT3G/WT3E1.mo (extends nothing: no S_b, no fn)
# The electrical control of the type-3 wind generator. Like WT4E1.mo it carries local classes: the three
# `protected model`s `pf_Controller`, `ActivePowerControl`, `ReactivePowerControl` are the three
# `@component function`s `WT3E1_pf_Controller`, `WT3E1_ActivePowerControl`, `WT3E1_ReactivePowerControl` of this
# file (they are not classes of the inventory), and the local `function Speed` is the plain Julia function
# `WT3E1_Speed`.
# Top-level blocks, with the names of the .mo: Qord = Limiter(QMN, QMX), feedback1 = Feedback,
# K6 = LimIntegrator(VMINCL, VMAXCL, k = Kqi, y_start = k60, InitialOutput), Vcl = Feedback,
# K7 = LimIntegrator(k = Kqv, y_start = k70, outMax = 1 + XIQmax, outMin = XIQmin - 1), Qcmd0 = Constant(Qref),
# pf_Controller1, activePowerControl, reactivePowerControl. Ports are plain variables (PELEC, VTERM, Qelec,
# ITERM, WEQCMD0, WIPCMD0 in; WIPCMD, WEQCMD, WPCMND out) plus the protected input `SPEED`, which the .mo binds to
# its own `sp0` and therefore takes no connection (sic).
# The ten `k*` are `parameter (fixed = false)` and `PFA_ref` is another: `k70 = WEQCMD0` and `k20 = WIPCMD0*v0`
# read **inputs**, so those two are `missing` parameters with their equation in `initialization_eqs` (F-33), and
# `k30 = k20/(sp0 + 1)` chains to one of them and is `missing` too. The other eight depend only on parameters
# (`v0`, `p0`, `q0`, `sp0`) and are plain Julia arithmetic. `k90` is resolved and read by nothing: dead, not
# declared (precedent WT4E1.jl). `Qcmd0` is instantiated with `k = Qref` and its output reaches nothing either,
# but the block is kept because the OpenModelica CSV carries its `y` column.
# The two `if`s of the equation section are on **Integer parameters**, so Modelica evaluates them at translation
# time and they are decided in Julia before `@parameters` (F-22): `VLRFLG <> 0` picks `WEQCMD = K7.y` or
# `WEQCMD = Vcl.y`, and `VARFLG` (1, -1, anything else) picks what feeds `Qord.u`.
# `atan2` is `atan(y, x)`. Omitted: graphical annotations.

# `Speed`: the shaft-speed-versus-power characteristic, a five-segment piecewise line. Its `if` chain is over the
# function's own scalar argument and is evaluated at every call, so it stays an `if` in plain Julia; the model
# calls it once on a parameter (`sp0`) and once on the input PELEC (inside ActivePowerControl), where it is
# written with `ifelse` on the symbolic argument.
function WT3E1_Speed(x, PMN, wmin, w20, w40, w60, w100, Pmin)
    K1 = (w20 - wmin) / (0.2 - PMN)
    K2 = (w40 - w20) / (0.4 - 0.2)
    K3 = (w60 - w40) / (0.6 - 0.4)
    K4 = (w100 - w60) / (Pmin - 0.6)
    # the .mo's own branch order and conditions, including the gap its second one leaves between PMN and Pmin (sic)
    K, y0, x0 = x <= PMN ? (0.0, wmin, PMN) :
                (x > Pmin && x <= 0.2) ? (K1, wmin, PMN) :
                (x > 0.2 && x <= 0.4) ? (K2, w20, 0.2) :
                (x > 0.4 && x <= 0.6) ? (K3, w40, 0.4) :
                (x > 0.6 && x <= Pmin) ? (K4, w60, 0.6) : (0.0, w100, Pmin)
    K * (x - x0) + y0 - 1
end

# the same characteristic on a symbolic argument: `ifelse` per branch, the tuples above written out
function WT3E1_Speed_sym(x, PMN, wmin, w20, w40, w60, w100, Pmin)
    K1 = (w20 - wmin) / (0.2 - PMN)
    K2 = (w40 - w20) / (0.4 - 0.2)
    K3 = (w60 - w40) / (0.6 - 0.4)
    K4 = (w100 - w60) / (Pmin - 0.6)
    K = ifelse(x <= PMN, 0.0, ifelse((x > Pmin) & (x <= 0.2), K1, ifelse((x > 0.2) & (x <= 0.4), K2,
        ifelse((x > 0.4) & (x <= 0.6), K3, ifelse((x > 0.6) & (x <= Pmin), K4, 0.0)))))
    y0 = ifelse(x <= PMN, wmin, ifelse((x > Pmin) & (x <= 0.2), wmin, ifelse((x > 0.2) & (x <= 0.4), w20,
        ifelse((x > 0.4) & (x <= 0.6), w40, ifelse((x > 0.6) & (x <= Pmin), w60, w100)))))
    x0 = ifelse(x <= PMN, PMN, ifelse((x > Pmin) & (x <= 0.2), PMN, ifelse((x > 0.2) & (x <= 0.4), 0.2,
        ifelse((x > 0.4) & (x <= 0.6), 0.4, ifelse((x > 0.6) & (x <= Pmin), 0.6, Pmin)))))
    K * (x - x0) + y0 - 1
end

# `protected model pf_Controller`: the power-factor regulator. Blocks: tan1 = Math.Tan, Qcmdn1 = Math.Product,
# VAR2 = Constant(PFA_ref), K0 = SimpleLag(K = 1, y_start = p0, T = Tp). Ports: u in, Q_REF_PF out.
@component function WT3E1_pf_Controller(; name, Tp = 0.50000E-01, PFA_ref, p0, q0)
    Tp, p0, q0 = float.((Tp, p0, q0))
    systems = @named begin
        tan1 = Tan()
        Qcmdn1 = Product()
        VAR2 = OpenIPSLComponents.Constant(; k = PFA_ref)
        K0 = SimpleLag(; K = 1, y_start = p0, T = Tp)
    end
    pars = @parameters begin
        Tp = Tp, [description = "Pelec filter in fast PF controller (s)"]
        PFA_ref = PFA_ref, [description = "PF angle reference if PFAFLG=1"]
        p0 = p0
        q0 = q0
    end
    vars = @variables begin
        u(t)
        Q_REF_PF(t)
    end
    eqs = Equation[
        Qcmdn1.u1 ~ tan1.y,        # connect(tan1.y, Qcmdn1.u1)
        Qcmdn1.u2 ~ K0.y,          # connect(K0.y, Qcmdn1.u2)
        tan1.u ~ VAR2.y,           # connect(VAR2.y, tan1.u)
        K0.u ~ u,                  # connect(u, K0.u)
        Q_REF_PF ~ Qcmdn1.y,       # connect(Qcmdn1.y, Q_REF_PF)
    ]
    System(eqs, t, vars, pars; name, systems)
end

# `protected model ActivePowerControl`: the torque regulator. Blocks: K5 = SimpleLag(1, T_Power, k50),
# add = Add(k2 = -1), K3 = Integrator(y_start = k30, k = KIP, InitialOutput), imGain = Gain(Kpp), add1 = Add,
# feedback = Feedback, imLimited = Limiter(RPMN, RPMX), K2 = LimIntegrator(PMN, PMX, k = 1/TFP, y_start = k20,
# InitialOutput), imLimited_max = Limiter(-inf, IPMAX), add2 = Add, const_ = Constant(1), division = Division,
# imLimited_min = Limiter(0.01, inf), Qcmdn2 = Product. Ports: SPEED, VTERM, PELEC in; WIPCMD, WPCMND out; the
# protected WNDSP_1 is the `Speed` characteristic of PELEC.
@component function WT3E1_ActivePowerControl(; name, TFP, Kpp, KIP, PMX, PMN, IPMAX, RPMX, RPMN, T_Power,
        k20, k30, k50, wPmin, wP20, wP40, wP60, Pmin, wP100)
    TFP, Kpp, KIP, PMX, PMN, IPMAX, RPMX, RPMN, T_Power, wPmin, wP20, wP40, wP60, Pmin, wP100 =
        float.((TFP, Kpp, KIP, PMX, PMN, IPMAX, RPMX, RPMN, T_Power, wPmin, wP20, wP40, wP60, Pmin, wP100))
    inf = Modelica.Constants.inf
    sp = (PMN, wPmin, wP20, wP40, wP60, wP100, Pmin)   # numeric coefficients of the characteristic (F-22)
    systems = @named begin
        K5 = SimpleLag(; K = 1, T = T_Power, y_start = k50)
        add = Add(; k2 = -1)
        K3 = Integrator(; y_start = k30, k = KIP, initType = :InitialOutput)
        imGain = Gain(; k = Kpp)
        add1 = Add()
        feedback = Feedback()
        imLimited = Limiter(; uMin = RPMN, uMax = RPMX)
        K2 = LimIntegrator(; outMin = PMN, outMax = PMX, k = 1 / TFP, y_start = k20, initType = :InitialOutput)
        imLimited_max = Limiter(; uMin = -inf, uMax = IPMAX)
        add2 = Add()
        const_ = OpenIPSLComponents.Constant(; k = 1)
        division = Division()
        imLimited_min = Limiter(; uMin = 0.01, uMax = inf)
        Qcmdn2 = Product()
    end
    pars = @parameters begin
        TFP = TFP, [description = "Filter time constant in torque regulator (s)"]
        Kpp = Kpp, [description = "Proportional gain in torque regulator (pu)"]
        KIP = KIP, [description = "Integrator gain in torque regulator"]
        PMX = PMX, [description = "Max limit in torque regulator (pu)"]
        PMN = PMN, [description = "Min limit in torque regulator (pu)"]
        IPMAX = IPMAX, [description = "Max active current limit (pu)"]
        RPMX = RPMX, [description = "Max power order derivative (pu)"]
        RPMN = RPMN, [description = "Min power order derivative (pu)"]
        T_Power = T_Power, [description = "Power filter time constant (s)"]
        wPmin = wPmin, [description = "Shaft speed at Pmin (pu)"]
        wP20 = wP20, [description = "Shaft speed at 20% rated power (pu)"]
        wP40 = wP40, [description = "Shaft speed at 40% rated power (pu)"]
        wP60 = wP60, [description = "Shaft speed at 60% rated power (pu)"]
        Pmin = Pmin, [description = "Minimum power for operating at P100 speed (pu)"]
        wP100 = wP100, [description = "Shaft speed at 100% rated power (pu)"]
    end
    vars = @variables begin
        SPEED(t)
        VTERM(t)
        PELEC(t)
        WIPCMD(t)
        WPCMND(t)
        WNDSP_1(t)
    end
    eqs = Equation[
        WNDSP_1 ~ WT3E1_Speed_sym(PELEC, sp...),
        division.u2 ~ imLimited_min.y,   # connect(imLimited_min.y, division.u2)
        K5.u ~ WNDSP_1,                  # connect(WNDSP_1, K5.u)
        division.u1 ~ K2.y,              # connect(K2.y, division.u1)
        imLimited_max.u ~ division.y,    # connect(division.y, imLimited_max.u)
        add.u2 ~ K5.y,                   # connect(K5.y, add.u2)
        K3.u ~ add.y,                    # connect(add.y, K3.u)
        imGain.u ~ K3.u,                 # connect(imGain.u, K3.u)
        add1.u1 ~ K3.y,                  # connect(K3.y, add1.u1)
        add1.u2 ~ imGain.y,              # connect(imGain.y, add1.u2)
        Qcmdn2.u2 ~ add1.y,              # connect(add1.y, Qcmdn2.u2)
        add2.u2 ~ const_.y,              # connect(const.y, add2.u2)
        add2.u1 ~ SPEED,                 # connect(SPEED, add2.u1)
        add.u1 ~ add2.u1,                # connect(add.u1, add2.u1)
        Qcmdn2.u1 ~ add2.y,              # connect(add2.y, Qcmdn2.u1)
        feedback.u1 ~ Qcmdn2.y,          # connect(Qcmdn2.y, feedback.u1)
        imLimited.u ~ feedback.y,        # connect(feedback.y, imLimited.u)
        K2.u ~ imLimited.y,              # connect(imLimited.y, K2.u)
        feedback.u2 ~ division.u1,       # connect(feedback.u2, division.u1)
        imLimited_min.u ~ VTERM,         # connect(VTERM, imLimited_min.u)
        WPCMND ~ division.u1,            # connect(WPCMND, division.u1)
        WIPCMD ~ imLimited_max.y,        # connect(imLimited_max.y, WIPCMD)
    ]
    System(eqs, t, vars, pars; name, systems)
end

# `protected model ReactivePowerControl`: the WindVar regulator. Blocks: K4 = SimpleLag(1, TRV, k40),
# K8 = SimpleLag(Kpv, Tv, k80), K = SimpleLag(1, Tfv, k0), XC = Gain(Xc), add3 = Add(k2 = -1),
# VARL = Constant(Vref), portion = Gain(1/Fn), K1 = SimpleLag(KIV, Tv, k10), add4 = Add, add5 = Add(k2 = -1),
# Qord1 = Limiter(QMN, QMX), K10 = SimpleLag(1, Tv, k80). Ports: ITERM, VTERM in; Q_ord out.
@component function WT3E1_ReactivePowerControl(; name, Tfv, Kpv, KIV, Xc, QMX, QMN, TRV, Tv = 0.50000E-01, Fn,
        Vref, k0, k10, k40, k80)
    Tfv, Kpv, KIV, Xc, QMX, QMN, TRV, Tv, Fn, Vref = float.((Tfv, Kpv, KIV, Xc, QMX, QMN, TRV, Tv, Fn, Vref))
    systems = @named begin
        K4 = SimpleLag(; K = 1, T = TRV, y_start = k40)
        K8 = SimpleLag(; K = Kpv, T = Tv, y_start = k80)
        K = SimpleLag(; K = 1, T = Tfv, y_start = k0)
        XC = Gain(; k = Xc)
        add3 = Add(; k2 = -1)
        VARL = OpenIPSLComponents.Constant(; k = Vref)
        portion = Gain(; k = 1 / Fn)
        K1 = SimpleLag(; y_start = k10, K = KIV, T = Tv)
        add4 = Add()
        add5 = Add(; k2 = -1)
        Qord1 = Limiter(; uMin = QMN, uMax = QMX)
        K10 = SimpleLag(; T = Tv, y_start = k80, K = 1)
    end
    pars = @parameters begin
        Tfv = Tfv, [description = "Filter time constant in voltage regulator (s)"]
        Kpv = Kpv, [description = "Proportional gain in voltage regulator (pu)"]
        KIV = KIV, [description = "Integrator gain in voltage regulator"]
        Xc = Xc, [description = "Line drop compensation reactance (pu)"]
        QMX = QMX, [description = "Max limit in voltage regulator (pu)"]
        QMN = QMN, [description = "Min limit in voltage regulator (pu)"]
        TRV = TRV, [description = "Voltage sensor time constant (s)"]
        Tv = Tv, [description = "Lag time constant in WindVar controller (s)"]
        Fn = Fn, [description = "A portion of online wind turbines"]
        Vref = Vref, [description = "Remote bus ref voltage (pu)"]
    end
    vars = @variables begin
        ITERM(t)
        VTERM(t)
        Q_ord(t)
    end
    eqs = Equation[
        add3.u1 ~ VARL.y,      # connect(VARL.y, add3.u1)
        add5.u2 ~ XC.y,        # connect(XC.y, add5.u2)
        portion.u ~ add3.y,    # connect(add3.y, portion.u)
        K4.u ~ add5.y,         # connect(add5.y, K4.u)
        add3.u2 ~ K4.y,        # connect(K4.y, add3.u2)
        K.u ~ Qord1.y,         # connect(Qord1.y, K.u)
        add5.u1 ~ VTERM,       # connect(VTERM, add5.u1)
        Qord1.u ~ add4.y,      # connect(add4.y, Qord1.u)
        add4.u1 ~ K1.y,        # connect(K1.y, add4.u1)
        K1.u ~ K10.y,          # connect(K10.y, K1.u)
        add4.u2 ~ K8.y,        # connect(K8.y, add4.u2)
        K10.u ~ portion.y,     # connect(portion.y, K10.u)
        K8.u ~ K10.u,          # connect(K8.u, K10.u)
        XC.u ~ ITERM,          # connect(ITERM, XC.u)
        Q_ord ~ K.y,           # connect(K.y, Q_ord)
    ]
    System(eqs, t, vars, pars; name, systems)
end

@component function WT3E1(; name, VARFLG, VLRFLG, Tfv = 0.15000, Kpv = 18.000, KIV = 5.0000, Xc = 0.0000,
        TFP = 0.50000E-01, Kpp = 3.0000, KIP = 0.60000, PMX = 1.1200, PMN = 0.10000, QMX = 0.29600,
        QMN = -0.43600, IPMAX = 1.1000, TRV = 0.50000E-01, RPMX = 0.45000, RPMN = -0.45000, T_Power = 5.0000,
        Kqi = 0.50000E-01, VMINCL = 0.90000, VMAXCL = 1.2000, Kqv = 40.000, XIQmin = -0.50000, XIQmax = 0.40000,
        Tv = 0.50000E-01, Tp = 0.50000E-01, Fn = 1.0000, wPmin = 0.69000, wP20 = 0.78000, wP40 = 0.98000,
        wP60 = 1.1200, Pmin = 0.74000, wP100 = 1.2000, Vref, v0, p0, q0)
    Tfv, Kpv, KIV, Xc, TFP, Kpp, KIP, PMX, PMN, QMX, QMN, IPMAX, TRV, RPMX, RPMN, T_Power, Kqi, VMINCL, VMAXCL,
        Kqv, XIQmin, XIQmax, Tv, Tp, Fn, wPmin, wP20, wP40, wP60, Pmin, wP100, Vref, v0, p0, q0 =
        float.((Tfv, Kpv, KIV, Xc, TFP, Kpp, KIP, PMX, PMN, QMX, QMN, IPMAX, TRV, RPMX, RPMN, T_Power, Kqi,
            VMINCL, VMAXCL, Kqv, XIQmin, XIQmax, Tv, Tp, Fn, wPmin, wP20, wP40, wP60, Pmin, wP100, Vref, v0,
            p0, q0))
    # the protected parameters that depend only on parameters: plain Julia (F-22, F-33)
    Qref = q0
    sp0 = WT3E1_Speed(p0, PMN, wPmin, wP20, wP40, wP60, wP100, Pmin)
    PFA_ref = atan(q0, p0)   # atan2(q0, p0)
    k0 = q0
    k10 = q0
    k40 = v0
    k50 = sp0
    k60 = v0
    k80 = 0.0
    # k90 = p0 is resolved by the .mo and read by nothing: dead, not declared (precedent WT4E1.jl)
    varflg, vlrflg = VARFLG, VLRFLG   # the two `if`s are on Integer parameters: decided here (F-22)
    pars0 = @parameters begin
        k20, [guess = 0.0]   # k20 = WIPCMD0*v0 reads an input (F-33)
        k30, [guess = 0.0]   # k30 = k20/(sp0 + 1) chains to it
        k70, [guess = 0.0]   # k70 = WEQCMD0 reads an input
    end
    systems = @named begin
        Qord = Limiter(; uMin = QMN, uMax = QMX)
        feedback1 = Feedback()
        K6 = LimIntegrator(; outMin = VMINCL, outMax = VMAXCL, k = Kqi, y_start = k60,
            initType = :InitialOutput)
        Vcl = Feedback()
        K7 = LimIntegrator(; k = Kqv, y_start = k70, outMax = 1 + XIQmax, outMin = XIQmin - 1)
        Qcmd0 = OpenIPSLComponents.Constant(; k = Qref)
        pf_Controller1 = WT3E1_pf_Controller(; Tp, p0, PFA_ref, q0)
        activePowerControl = WT3E1_ActivePowerControl(; TFP, Kpp, KIP, PMX, PMN, IPMAX, RPMX, RPMN, T_Power,
            k20, k30, k50, wPmin, wP20, wP40, wP60, Pmin, wP100)
        reactivePowerControl = WT3E1_ReactivePowerControl(; Tfv, Kpv, KIV, Xc, QMX, QMN, TRV, Tv, Fn, Vref,
            k0, k10, k40, k80)
    end
    pars = @parameters begin
        VARFLG = VARFLG
        VLRFLG = VLRFLG
        Tfv = Tfv, [description = "Filter time constant in voltage regulator (s)"]
        Kpv = Kpv, [description = "Proportional gain in voltage regulator (pu)"]
        KIV = KIV, [description = "Integrator gain in voltage regulator"]
        Xc = Xc, [description = "Line drop compensation reactance (pu)"]
        TFP = TFP, [description = "Filter time constant in torque regulator (s)"]
        Kpp = Kpp, [description = "Proportional gain in torque regulator (pu)"]
        KIP = KIP, [description = "Integrator gain in torque regulator"]
        PMX = PMX, [description = "Max limit in torque regulator (pu)"]
        PMN = PMN, [description = "Min limit in torque regulator (pu)"]
        QMX = QMX, [description = "Max limit in voltage regulator (pu)"]
        QMN = QMN, [description = "Min limit in voltage regulator (pu)"]
        IPMAX = IPMAX, [description = "Max active current limit (pu)"]
        TRV = TRV, [description = "Voltage sensor time constant (s)"]
        RPMX = RPMX, [description = "Max power order derivative (pu)"]
        RPMN = RPMN, [description = "Min power order derivative (pu)"]
        T_Power = T_Power, [description = "Power filter time constant (s)"]
        Kqi = Kqi, [description = "Mvar/Voltage gain (pu)"]
        VMINCL = VMINCL, [description = "Min voltage limit (pu)"]
        VMAXCL = VMAXCL, [description = "Max voltage limit (pu)"]
        Kqv = Kqv, [description = "Voltage/Mvar gain (pu)"]
        XIQmin = XIQmin
        XIQmax = XIQmax
        Tv = Tv, [description = "Lag time constant in WindVar controller (s)"]
        Tp = Tp, [description = "Pelec filter in fast PF controller (s)"]
        Fn = Fn, [description = "A portion of online wind turbines"]
        wPmin = wPmin, [description = "Shaft speed at Pmin (pu)"]
        wP20 = wP20, [description = "Shaft speed at 20% rated power (pu)"]
        wP40 = wP40, [description = "Shaft speed at 40% rated power (pu)"]
        wP60 = wP60, [description = "Shaft speed at 60% rated power (pu)"]
        Pmin = Pmin, [description = "Minimum power for operating at P100 speed (pu)"]
        wP100 = wP100, [description = "Shaft speed at 100% rated power (pu)"]
        Vref = Vref, [description = "Remote bus ref voltage (pu)"]
        v0 = v0
        p0 = p0
        q0 = q0
        PFA_ref = PFA_ref, [description = "PF angle reference if PFAFLG=1"]
        Qref = Qref, [description = "Q reference if PFAFLG=0 & VARFLG"]
        sp0 = sp0
    end
    vars = @variables begin
        PELEC(t), [guess = p0]
        VTERM(t), [guess = v0]
        Qelec(t), [guess = q0]
        ITERM(t)
        WEQCMD0(t)
        WIPCMD0(t)
        WIPCMD(t)
        WEQCMD(t)
        WPCMND(t)
        SPEED(t)
    end
    eqs = Equation[
        SPEED ~ sp0,                      # RealInput SPEED = sp0 (protected, bound by the .mo)
        WEQCMD ~ (vlrflg != 0 ? K7.y : Vcl.y),
        Qord.u ~ (varflg == 1 ? reactivePowerControl.Q_ord : varflg == -1 ? pf_Controller1.Q_REF_PF : Qref),
        feedback1.u2 ~ Qelec,             # connect(Qelec, feedback1.u2)
        Vcl.u2 ~ VTERM,                   # connect(Vcl.u2, VTERM)
        K6.u ~ feedback1.y,               # connect(feedback1.y, K6.u)
        Vcl.u1 ~ K6.y,                    # connect(K6.y, Vcl.u1)
        feedback1.u1 ~ Qord.y,            # connect(Qord.y, feedback1.u1)
        pf_Controller1.u ~ PELEC,         # connect(PELEC, pf_Controller1.u)
        activePowerControl.SPEED ~ SPEED, # connect(SPEED, activePowerControl.SPEED)
        activePowerControl.VTERM ~ VTERM, # connect(activePowerControl.VTERM, VTERM)
        WIPCMD ~ activePowerControl.WIPCMD,   # connect(activePowerControl.WIPCMD, WIPCMD)
        activePowerControl.PELEC ~ PELEC, # connect(PELEC, activePowerControl.PELEC)
        WPCMND ~ activePowerControl.WPCMND,
        reactivePowerControl.ITERM ~ ITERM,
        reactivePowerControl.VTERM ~ VTERM,
        K7.u ~ Vcl.y,
    ]
    System(eqs, t, vars, [pars0; pars]; name, systems,
        initialization_eqs = [k70 ~ WEQCMD0, k20 ~ WIPCMD0 * v0, k30 ~ k20 / (sp0 + 1)],
        initial_conditions = Dict(k70 => missing, k20 => missing, k30 => missing))
end
