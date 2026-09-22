# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Wind/PSSE/WT3G/WT3E1.mo (a Test of this port, not OpenIPSL's: PLAN-12, family H),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# The same network and generator as the WT3G1 Test, with the loop closed: the two current commands come from the
# electrical control and the control reads the generator's power, reactive power, terminal voltage and terminal
# current. `WPCMND` goes to the turbine model, which this batch does not port, and is left open; `SPEED` is an
# input the .mo binds to its own `sp0` and takes no connection either.
# Unlike its type-4 sibling, this model DOES have an OpenModelica oracle (F-70 does not repeat): its
# `initial equation` reads the inputs WEQCMD0 and WIPCMD0, which here are parameter-valued outputs of WT3G1, so
# the chain closes on parameters and the index reduction that stopped WT4E1 never appears.
# `WT3E1` is the model, so the Test function takes the suffix _Test (PLAN-02 rule).
@component function WT3E1_Test(; name, S_b = 100000000, fn = 50)
    systems = @named begin
        pwLine = PwLine(; R = 2.50000E-2, X = 2.50000E-2, G = 0.0, B = 0.05000/2, S_b, fn)
        pwLine1 = PwLine(; R = 2.50000E-2, X = 2.50000E-2, G = 0.0, B = 0.05000/2, S_b, fn)
        gENCLS2_1 = GENCLS(; angle_0 = -1.570655e-005, R_a = 0.0, X_d = 2.00000E-1, M_b = 100000000.0, V_b = 100000.0, P_0 = -1498800.0, Q_0 = -4334000.0, v_0 = 1.00000, S_b, fn)
        pwLine2 = PwLine(; G = 0.0, B = 0.0, R = 2.50000E-3, X = 2.50000E-3, S_b, fn)
        wT3G1 = WT3G1(; angle_0 = 0.02574992, M_b = 100000000.0, V_b = 100000.0, P_0 = 1500000.0, Q_0 = -5665800.0, v_0 = 0.9999999, X_eq = 0.8, K_pll = 30.0, K_ipll = 0.0, P_llmax = 0.1, P_rated = 1500000.0, S_b, fn)
        wT3E1 = WT3E1(; VARFLG = 1, VLRFLG = 1, Vref = 1.0, v0 = 0.9999999, p0 = 0.015, q0 = -0.056658)
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
        wT3E1.WEQCMD ~ wT3G1.Eqcmd,   # connect(wT3E1.WEQCMD, wT3G1.Eqcmd)
        wT3E1.WIPCMD ~ wT3G1.Ipcmd,   # connect(wT3E1.WIPCMD, wT3G1.Ipcmd)
        wT3E1.PELEC ~ wT3G1.P,   # connect(wT3E1.PELEC, wT3G1.P)
        wT3E1.Qelec ~ wT3G1.Q,   # connect(wT3E1.Qelec, wT3G1.Q)
        wT3E1.VTERM ~ wT3G1.V,   # connect(wT3E1.VTERM, wT3G1.V)
        wT3E1.ITERM ~ wT3G1.Iterm,   # connect(wT3E1.ITERM, wT3G1.Iterm)
        wT3E1.WEQCMD0 ~ wT3G1.eqcmd0,   # connect(wT3E1.WEQCMD0, wT3G1.eqcmd0)
        wT3E1.WIPCMD0 ~ wT3G1.ipcmd0,   # connect(wT3E1.WIPCMD0, wT3G1.ipcmd0)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "PortTests.Wind.PSSE.WT3G.WT3E1" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Wind.PSSE.WT3G.WT3E1.jl"))
    validate_against_oracle(WT3E1_Test, oracle;
        rename = Dict("wT3G1.Is.re" => "wT3G1.Is_re", "wT3G1.Is.im" => "wT3G1.Is_im"))   # Complex Is (PLAN-02)
end
