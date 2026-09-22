# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Wind/GE/WT_Test.mo, transcribed automatically (2026-09-19); reviewed by hand.
# extends: Modelica.Icons.Example (nothing to port). The function is `GE_WT_Test`: `Tests.Wind.PSAT.WT_Test` is its
# homonym (PLAN-08). No Bus: `infBus` - five PwLines - `GE_WT_init.pwPin1`, the fault at the first node between 10 and
# 10.1 s; `windGenerator1` with its defaults (typ = 1, Vw = 14); `SysData` by default (fn = 50, sic: GE_WT carries its
# own freq = 60 and SYS_base = 100e6 and reads neither S_b nor fn). The Test does not start at an equilibrium (F-72).
# Omitted: graphical annotations, displayPF.
@component function GE_WT_Test(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        GE_WT_init = GE_WT(; )
        infBus = InfiniteBus(; angle_0 = -0.000216626610049175, v_0 = 1.05999999985841, S_b, fn)
        pwLine2 = PwLine(; R = 0.009, X = 0.065, B = 0.063, G = 0.0, S_b, fn)
        pwLine3 = PwLine(; R = 0.0006, X = 0.0333, G = 0.0, B = 0.0, S_b, fn)
        pwLine4 = PwLine(; R = 0.05, X = 0.015, B = 0.045, G = 0.0, S_b, fn)
        pwLine5 = PwLine(; R = 0.00222, X = 0.0222, G = 0.0, B = 0.0, S_b, fn)
        windGenerator1 = WindGenerator(; )
        pwLine1 = PwLine(; R = 0.013, X = 0.13, G = 0.0, B = 0.0, S_b, fn)
        pwFault1 = PwFault(; R = 1/99999.999, t1 = 10.0, t2 = 10.1, X = 1/99999.999)
    end
    eqs = Equation[
        connect(infBus.p, pwLine1.p),
        connect(pwLine1.n, pwLine2.p),
        connect(pwLine2.n, pwLine3.p),
        windGenerator1.Vw ~ GE_WT_init.Wind_Speed,   # connect(windGenerator1.Vw, GE_WT_init.Wind_Speed)
        connect(pwLine5.n, GE_WT_init.pwPin1),
        connect(pwLine4.n, pwLine5.p),
        connect(pwLine3.n, pwLine4.p),
        connect(pwFault1.p, pwLine1.n),
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "Tests.Wind.GE.WT_Test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Wind.GE.WT_Test.jl"))
    validate_against_oracle(GE_WT_Test, oracle)
end
