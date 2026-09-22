# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/PSSE/WT4G/WT4G1.mo (extends Icons.VerifiedModel, nothing to port, and
# Electrical/Essentials/pfComponent.mo with every enable* at its default)
# Blocks, with the names of the .mo: K1 = SimpleLag(K = 1, T = T_IQCmd, y_start = Iy0), K = Integrator(k = 1/T_IPCmd,
# InitialOutput, y_start = Ix0), Iperr = Feedback (y(start = 0), a guess), lVACL, hVRCL(VHVRCR = V_HVRCR, CurHVRCR =
# CUR_HVRCR), lVPL = Wind_LVPL(V_LVPL1, V_LVPL2, G_LVPL), imLimited_max = Limiter(uMin = -inf, uMax = RIp_LVPL)
# (one-sided: it limits the rise of Ip only), variableLimiter (y(start = Ipcmd0), a guess; limit1 = lVPL.LVPL, which
# can be 1e6, limit2 = const.y), const = Constant(-inf) (instance `const_`), K2 = SimpleLag(K = 1, T = T_LVPL,
# y_start = v_0). Ports are plain variables (I_qcmd, I_pcmd; Iy, V, P, Q, IyL, IxL, I_qcmd0, I_pcmd0) and the pin.
# The protected parameters are those of `regc_init` in BaseREGC.jl (same expressions: p0 ... Isi0, CoB) plus
# `ir1 = -CoB*ir0`, `ii1 = -CoB*ii0`, `Ix0 = Ip0` of that function and **`Iy0 = -Iq0`** (the sign convention of
# WT4G is opposite to WECC's, sic), `Ipcmd0 = Ix0`.
# `Complex Is` is the pair of variables `Is_re`, `Is_im` (PLAN-02; the OpenModelica columns `Is.re`/`Is.im` are
# renamed in the Tests). The matrix `[IxL; -IyL] = -[cos d, sin d; -sin d, cos d]*[Is.re; Is.im]` is inverted by
# hand, as in REGCA1.jl, and written solved for the pin currents: `p.ir = -CoB*(cos(delta)*IxL + sin(delta)*IyL)`,
# `p.ii = CoB*(cos(delta)*IyL - sin(delta)*IxL)`. `P`, `Q` are in **S_b** (`-P = vr*ir + vi*ii` with the pin
# currents in S_b, unlike REGCA1's Pgen in M_b; invisible with M_b = S_b), `delta = anglev` is an alias of the bus
# angle (sic), `V = VT` and the protected input `Vtt = VT` are binding equations. The `start` values of the pin,
# `delta`, `anglev`, `VT`, `Iy`, `IyL`, `IxL`, `P`, `Q` are guesses. `atan2` is `atan(y, x)`.
# Omitted: Icons.VerifiedModel, displayPF, graphical annotations.

@component function WT4G1(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0,
        M_b, T_IQCmd, T_IPCmd, V_LVPL1, V_LVPL2, G_LVPL, V_HVRCR, CUR_HVRCR, RIp_LVPL, T_LVPL)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0, M_b))
    T_IQCmd, T_IPCmd, V_LVPL1, V_LVPL2, G_LVPL, V_HVRCR, CUR_HVRCR, RIp_LVPL, T_LVPL =
        float.((T_IQCmd, T_IPCmd, V_LVPL1, V_LVPL2, G_LVPL, V_HVRCR, CUR_HVRCR, RIp_LVPL, T_LVPL))
    n = regc_init(P_0, Q_0, v_0, angle_0, M_b, S_b)
    Ix0, Iy0 = n.Ip0, -n.Iq0
    Ipcmd0 = Ix0
    ir1, ii1 = -n.CoB * n.ir0, -n.CoB * n.ii0
    inf = Modelica.Constants.inf
    base = pfComponent(; name, S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    systems = @named begin
        p = PwPin()
        K1 = SimpleLag(; K = 1, T = T_IQCmd, y_start = Iy0)
        K = Integrator(; y_start = Ix0, k = 1 / T_IPCmd, initType = :InitialOutput)
        Iperr = Feedback()
        lVACL = LVACL()
        hVRCL = HVRCL(; VHVRCR = V_HVRCR, CurHVRCR = CUR_HVRCR)
        lVPL = Wind_LVPL(; VLVPL1 = V_LVPL1, VLVPL2 = V_LVPL2, GLVPL = G_LVPL)
        imLimited_max = Limiter(; uMin = -inf, uMax = RIp_LVPL)
        variableLimiter = VariableLimiter()
        const_ = OpenIPSLComponents.Constant(; k = -inf)
        K2 = SimpleLag(; K = 1, T = T_LVPL, y_start = v_0)
    end
    pars = @parameters begin
        M_b = M_b, [description = "Machine base power (VA)"]
        T_IQCmd = T_IQCmd, [description = "Converter time constant for I_Qcmd (s)"]
        T_IPCmd = T_IPCmd, [description = "Converter time constant for I_Pcmd (s)"]
        V_LVPL1 = V_LVPL1, [description = "LVPL voltage 1 (Low voltage power logic) (pu)"]
        V_LVPL2 = V_LVPL2, [description = "LVPL voltage 2 (pu)"]
        G_LVPL = G_LVPL, [description = "LVPL gain"]
        V_HVRCR = V_HVRCR, [description = "HVRCR voltage (High voltage reactive current limiter) (pu)"]
        CUR_HVRCR = CUR_HVRCR, [description = "HVRCR current (Max. reactive current at VHVRCR) (pu)"]
        RIp_LVPL = RIp_LVPL, [description = "Rate of LVACR active current change"]
        T_LVPL = T_LVPL, [description = "Voltage sensor for LVACR time constant (s)"]
        p0 = n.p0, [description = "initial value of bus active power in p.u. machinebase"]
        q0 = n.q0, [description = "initial value of bus reactive power in p.u. machinebase"]
        vr0 = n.vr0
        vi0 = n.vi0
        ir0 = n.ir0
        ii0 = n.ii0
        Isr0 = n.Isr0
        Isi0 = n.Isi0
        CoB = n.CoB
        ir1 = ir1
        ii1 = ii1
        Ipcmd0 = Ipcmd0
        Ix0 = Ix0
        Iy0 = Iy0
    end
    vars = @variables begin
        Is_re(t), [description = "Equivalent internal current source, real part (Is.re)"]
        Is_im(t), [description = "Equivalent internal current source, imaginary part (Is.im)"]
        Iy(t)
        V(t)
        P(t)
        Q(t)
        IyL(t)
        IxL(t)
        I_qcmd(t)
        I_pcmd(t)
        I_qcmd0(t)
        I_pcmd0(t)
        delta(t)
        VT(t), [description = "Bus voltage magnitude"]
        anglev(t), [description = "Bus voltage angle"]
        Vtt(t)
    end
    eqs = Equation[
        I_qcmd0 ~ Iy0,
        I_pcmd0 ~ Ix0,
        anglev ~ atan(p.vi, p.vr),   # atan2(p.vi, p.vr)
        VT ~ sqrt(p.vr * p.vr + p.vi * p.vi),
        delta ~ anglev,
        Is_re ~ p.ir / CoB,
        Is_im ~ p.ii / CoB,
        # [IxL; -IyL] = -[cos(delta), sin(delta); -sin(delta), cos(delta)]*[Is.re; Is.im], solved for the pin currents
        p.ir ~ -CoB * (cos(delta) * IxL + sin(delta) * IyL),
        p.ii ~ CoB * (cos(delta) * IyL - sin(delta) * IxL),
        -P ~ p.vr * p.ir + p.vi * p.ii,
        -Q ~ p.vi * p.ir - p.vr * p.ii,
        V ~ VT,                                  # RealOutput V = VT
        Vtt ~ VT,                                # RealInput Vtt = VT (protected)
        Iperr.u1 ~ I_pcmd,                       # connect(Iperr.u1, I_pcmd)
        lVACL.Ip_LVACL ~ IxL,                    # connect(lVACL.Ip_LVACL, IxL)
        hVRCL.Iq_HVRCL ~ IyL,                    # connect(hVRCL.Iq_HVRCL, IyL)
        I_qcmd ~ K1.u,                           # connect(I_qcmd, K1.u)
        Iperr.y ~ imLimited_max.u,               # connect(Iperr.y, imLimited_max.u)
        imLimited_max.y ~ K.u,                   # connect(imLimited_max.y, K.u)
        K.y ~ variableLimiter.u,                 # connect(K.y, variableLimiter.u)
        variableLimiter.y ~ lVACL.Ip_LVPL,       # connect(variableLimiter.y, lVACL.Ip_LVPL)
        Iperr.u2 ~ lVACL.Ip_LVPL,                # connect(Iperr.u2, lVACL.Ip_LVPL)
        const_.y ~ variableLimiter.limit2,       # connect(const.y, variableLimiter.limit2)
        K1.y ~ hVRCL.Iq,                         # connect(K1.y, hVRCL.Iq)
        Iy ~ hVRCL.Iq,                           # connect(Iy, hVRCL.Iq)
        lVPL.LVPL ~ variableLimiter.limit1,      # connect(lVPL.LVPL, variableLimiter.limit1)
        Vtt ~ hVRCL.Vt,                          # connect(Vtt, hVRCL.Vt)
        lVACL.Vt ~ hVRCL.Vt,                     # connect(lVACL.Vt, hVRCL.Vt)
        lVPL.Vt ~ K2.y,                          # connect(lVPL.Vt, K2.y)
        K2.u ~ hVRCL.Vt,                         # connect(K2.u, hVRCL.Vt)
    ]
    guesses = Dict(p.vr => n.vr0, p.vi => n.vi0, p.ir => ir1, p.ii => ii1, delta => angle_0, anglev => angle_0,
        VT => v_0, Iy => Iy0, IyL => Iy0, IxL => Ix0, P => n.p0, Q => n.q0, I_qcmd => Iy0, I_pcmd => Ipcmd0,
        Iperr.y => 0.0, variableLimiter.y => Ipcmd0)
    extend(System(eqs, t, vars, pars; name, systems, guesses), base)
end
