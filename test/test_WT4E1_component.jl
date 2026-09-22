# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# The network of Tests/Wind/PSSE/WT4G/WT4E1.mo (see test_WT4E1.jl): the component alone, so that a scratch diagnostic can include it.
@component function WT4E1_Test(; name, S_b = 100e6, fn = 50, PFAFLG = false, PQFLAG = false, PSSEMATCH = true)
    systems = @named begin
        pwLine = PwLine(; R = 2.50000E-2, X = 2.50000E-2, G = 0.0, B = 0.05000 / 2, S_b, fn)
        pwLine1 = PwLine(; R = 2.50000E-2, X = 2.50000E-2, G = 0.0, B = 0.05000 / 2, S_b, fn)
        gENCLS2_1 = GENCLS(; angle_0 = -1.570655e-005, R_a = 0.0, X_d = 2.00000E-1, M_b = 100000000.0, V_b = 100000.0,
            P_0 = -1498800.0, Q_0 = -4334000.0, v_0 = 1.00000, S_b, fn)
        pwLine2 = PwLine(; G = 0.0, B = 0.0, R = 2.50000E-3, X = 2.50000E-3, S_b, fn)
        wT4G1 = WT4G1(; angle_0 = 0.02574992, M_b = 100000000.0, T_IQCmd = 0.02, T_IPCmd = 0.02, V_LVPL1 = 0.4, V_LVPL2 = 0.9,
            G_LVPL = 1.11, V_HVRCR = 1.2, CUR_HVRCR = 2.0, RIp_LVPL = 2.0, T_LVPL = 0.02, V_b = 100000.0, P_0 = 1500000.0,
            Q_0 = -5665800.0, v_0 = 0.9999999, S_b, fn)
        pwFault = PwFault(; R = 0.5, X = 0.5, t1 = 2.0, t2 = 2.15)
        wT4E1 = WT4E1(; PFAFLG, VARFLG = true, Tfv = 0.15, Kpv = 18.0, KIV = 5.0, Kpp = 0.05, KIP = 0.15, Kf = 0.0, Tf = 0.08,
            QMX = 0.48, QMN = -0.47, IPMAX = 1.1, TRV = 0.1, dPMX = 0.5, dPMN = -0.5, T_Power = 0.05, KQI = 0.15, VMINCL = 0.9,
            VMAXCL = 1.1, KVI = 120.0, Tv = 0.05, Tp = 0.05, ImaxTD = 1.7, Iphl = 1.11, Iqhl = 1.11, PQFLAG, PSSEMATCH)
        GEN1 = Bus(; S_b, fn)
        FAULT = Bus(; S_b, fn)
        GEN2 = Bus(; S_b, fn)
    end
    eqs = Equation[
        connect(wT4G1.p, GEN1.p),
        connect(GEN1.p, pwLine2.p),
        connect(pwLine2.n, FAULT.p),
        connect(FAULT.p, pwLine.p),
        connect(pwLine1.p, pwLine.p),
        connect(pwFault.p, FAULT.p),
        connect(pwLine.n, GEN2.p),
        connect(pwLine1.n, GEN2.p),
        connect(GEN2.p, gENCLS2_1.p),
        wT4E1.WIQCMD ~ wT4G1.I_qcmd,   # connect(wT4E1.WIQCMD, wT4G1.I_qcmd)
        wT4E1.WIPCMD ~ wT4G1.I_pcmd,   # connect(wT4E1.WIPCMD, wT4G1.I_pcmd)
        wT4G1.P ~ wT4E1.P,             # connect(wT4G1.P, wT4E1.P)
        wT4G1.V ~ wT4E1.V,             # connect(wT4G1.V, wT4E1.V)
        wT4G1.Q ~ wT4E1.Q,             # connect(wT4G1.Q, wT4E1.Q)
    ]
    System(eqs, t, [], []; name, systems)
end

