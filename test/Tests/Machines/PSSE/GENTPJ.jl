# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Machines/PSSE/GENTPJ.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `GENTPJ` is the machine (PLAN-02: a Test named as its model gets the suffix _Test). The .mo repeats ten of SMIB's
# thirteen `connect` statements: in Modelica a repeated connect between the same two pins is redundant, in
# ModelingToolkit it would add the equations twice, so they are not transcribed (PLAN-03).
@component function GENTPJ_Test(; name, S_b = 100e6, fn = 60)
    @named base = SMIB(; S_b, fn, mods = (; gENCLS = (; P_0 = 10017030, Q_0 = 8005052), GEN1 = (; angle_0 = 0.070619983433093), FAULT = (; v_0 = 0.995985, angle_0 = -0.0050086621115692)))
    @unpack GEN1 = base
    systems = @named begin
        gENTPJ = GENTPJ(; Tpd0 = 6.7, Tppd0 = 0.039, Tpq0 = 0.586, Tppq0 = 0.079, D = 0.0, Xd = 2.12, Xq = 2.02, Xpd = 0.26, Xpq = 0.464, Xppd = 0.195, Xppq = 0.195, Xl = 0.15, S10 = 0.057, S12 = 0.441, angle_0 = 0.070619983433093, R_a = 0.0, H = 4.88, M_b = 234000000.0, P_0 = 40000000.0, Q_0 = 5415812.0, v_0 = 1.0, Kis = 0.03, S_b, fn)
    end
    eqs = Equation[
        gENTPJ.PMECH ~ gENTPJ.PMECH0,   # connect(gENTPJ.PMECH, gENTPJ.PMECH0)
        gENTPJ.EFD ~ gENTPJ.EFD0,   # connect(gENTPJ.EFD, gENTPJ.EFD0)
        connect(gENTPJ.p, GEN1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Machines.PSSE.GENTPJ" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Machines.PSSE.GENTPJ.jl"))
    validate_against_oracle(GENTPJ_Test, oracle)
end
