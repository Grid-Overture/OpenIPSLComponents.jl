# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Wind/PSSE/WT4G/WT4G1.mo, transcribed automatically (2026-09-19); reviewed by hand.
# extends: Modelica.Icons.Example (nothing to port). The function is `WT4G1_Test`: the Test is the homonym of its
# model (PLAN-02 rule, precedent GENCLS_Test). The network of SMIBRenewable without sensors nor `freq`; the two
# current commands are tied to the model's own initial values (`I_qcmd = I_qcmd0`, `I_pcmd = I_pcmd0`), constant.
# `Is.re`/`Is.im` of the oracle are the pair `Is_re`/`Is_im` of the port (Complex, PLAN-02). Omitted: graphical
# annotations, displayPF.
@component function WT4G1_Test(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        pwLine = PwLine(; R = 2.50000E-2, X = 2.50000E-2, G = 0.0, B = 0.05000/2, S_b, fn)
        pwLine1 = PwLine(; R = 2.50000E-2, X = 2.50000E-2, G = 0.0, B = 0.05000/2, S_b, fn)
        gENCLS2_1 = GENCLS(; angle_0 = -1.570655e-005, R_a = 0.0, X_d = 2.00000E-1, M_b = 100000000.0, V_b = 100000.0, P_0 = -1498800.0, Q_0 = -4334000.0, v_0 = 1.00000, S_b, fn)
        pwLine2 = PwLine(; G = 0.0, B = 0.0, R = 2.50000E-3, X = 2.50000E-3, S_b, fn)
        wT4G1 = WT4G1(; angle_0 = 0.02574992, M_b = 100000000.0, T_IQCmd = 0.02, T_IPCmd = 0.02, V_LVPL1 = 0.4, V_LVPL2 = 0.9, G_LVPL = 1.11, V_HVRCR = 1.2, CUR_HVRCR = 2.0, RIp_LVPL = 2.0, T_LVPL = 0.02, V_b = 100000.0, P_0 = 1500000.0, Q_0 = -5665800.0, v_0 = 0.9999999, S_b, fn)
        pwFault = PwFault(; R = 0.5, X = 0.5, t1 = 2.0, t2 = 2.15)
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
        wT4G1.I_qcmd ~ wT4G1.I_qcmd0,   # connect(wT4G1.I_qcmd, wT4G1.I_qcmd0)
        wT4G1.I_pcmd ~ wT4G1.I_pcmd0,   # connect(wT4G1.I_pcmd, wT4G1.I_pcmd0)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.Wind.PSSE.WT4G.WT4G1" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Wind.PSSE.WT4G.WT4G1.jl"))
    validate_against_oracle(WT4G1_Test, oracle; rename = Dict("wT4G1.Is.re" => "wT4G1.Is_re", "wT4G1.Is.im" => "wT4G1.Is_im"))
end
