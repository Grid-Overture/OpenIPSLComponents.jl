# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Wind/PSSE/WT3G/WT3G1.mo (a Test of this port, not OpenIPSL's: PLAN-12, family H),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# The network of Tests.Wind.PSSE.WT4G.WT4G1 verbatim (a GENCLS infinite bus, two parallel 0.025 pu lines, a short
# line to the generator bus and a 0.5 + j0.5 pu fault between 2 s and 2.15 s) with the type-3 generator in place
# of the type-4 one. As in that Test the two current commands are tied to the model's own initial-value outputs,
# so the generator runs open loop; the electrical control that closes the loop is the WT3E1 Test.
# `M_b` is set to 100e6: the .mo's default is 100, in VA (sic).
# `WT3G1` is the model, so the Test function takes the suffix _Test (PLAN-02 rule).
@component function WT3G1_Test(; name, S_b = 100000000, fn = 50)
    systems = @named begin
        pwLine = PwLine(; R = 2.50000E-2, X = 2.50000E-2, G = 0.0, B = 0.05000/2, S_b, fn)
        pwLine1 = PwLine(; R = 2.50000E-2, X = 2.50000E-2, G = 0.0, B = 0.05000/2, S_b, fn)
        gENCLS2_1 = GENCLS(; angle_0 = -1.570655e-005, R_a = 0.0, X_d = 2.00000E-1, M_b = 100000000.0, V_b = 100000.0, P_0 = -1498800.0, Q_0 = -4334000.0, v_0 = 1.00000, S_b, fn)
        pwLine2 = PwLine(; G = 0.0, B = 0.0, R = 2.50000E-3, X = 2.50000E-3, S_b, fn)
        wT3G1 = WT3G1(; angle_0 = 0.02574992, M_b = 100000000.0, V_b = 100000.0, P_0 = 1500000.0, Q_0 = -5665800.0, v_0 = 0.9999999, X_eq = 0.8, K_pll = 30.0, K_ipll = 0.0, P_llmax = 0.1, P_rated = 1500000.0, S_b, fn)
        pwFault = PwFault(; R = 0.5, X = 0.5, t1 = 2.0, t2 = 2.15)
        GEN1 = Bus(; S_b, fn)
        FAULT = Bus(; S_b, fn)
        GEN2 = Bus(; S_b, fn)
    end
    eqs = Equation[
        connect(wT3G1.p, GEN1.p),
        connect(GEN1.p, pwLine2.p),
        connect(pwLine2.n, FAULT.p),
        connect(FAULT.p, pwLine.p),
        connect(pwLine1.p, pwLine.p),
        connect(pwFault.p, FAULT.p),
        connect(pwLine.n, GEN2.p),
        connect(pwLine1.n, GEN2.p),
        connect(GEN2.p, gENCLS2_1.p),
        wT3G1.Eqcmd ~ wT3G1.eqcmd0,   # connect(wT3G1.Eqcmd, wT3G1.eqcmd0)
        wT3G1.Ipcmd ~ wT3G1.ipcmd0,   # connect(wT3G1.Ipcmd, wT3G1.ipcmd0)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "PortTests.Wind.PSSE.WT3G.WT3G1" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Wind.PSSE.WT3G.WT3G1.jl"))
    validate_against_oracle(WT3G1_Test, oracle;
        rename = Dict("wT3G1.Is.re" => "wT3G1.Is_re", "wT3G1.Is.im" => "wT3G1.Is_im"))   # Complex Is (PLAN-02)
end
