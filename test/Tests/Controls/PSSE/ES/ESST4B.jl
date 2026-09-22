# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/ESST4B.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `ESST4B` is the exciter (suffix _Test) at its defaults; its two pins sit in series between gENROU.p and GEN1.p.
# The oracle's `eSST4B.Gen_terminal.*`/`Bus.*` columns are the pins themselves. `Modelica.Constants.inf` is 1e60.
@component function ESST4B_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROU = GENROU(; Xppd = 0.2, Xppq = 0.2, Xpp = 0.2, Xl = 0.12, angle_0 = 0.070620673811798, Tpd0 = 5.0, Tppd0 = 0.50000E-01, Tppq0 = 0.1, H = 4.0000, D = 0.0, Xd = 1.41, Xq = 1.3500, Xpd = 0.3, S10 = 0.1, S12 = 0.5, Xpq = 0.6, Tpq0 = 0.7, M_b = 100000000.0, P_0 = 39999952.9123306, Q_0 = 5416571.34890556, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        eSST4B = ESST4B()
        plusInf = Constant(; k = OpenIPSLComponents.Modelica.Constants.inf)
    end
    eqs = Equation[
        connect(gENROU.p, eSST4B.Gen_terminal),
        gENROU.EFD0 ~ eSST4B.EFD0,   # connect(gENROU.EFD0, eSST4B.EFD0)
        zero.y ~ eSST4B.VUEL,   # connect(zero.y, eSST4B.VUEL)
        gENROU.PMECH0 ~ gENROU.PMECH,   # connect(gENROU.PMECH0, gENROU.PMECH)
        eSST4B.EFD ~ gENROU.EFD,   # connect(eSST4B.EFD, gENROU.EFD)
        gENROU.XADIFD ~ eSST4B.XADIFD,   # connect(gENROU.XADIFD, eSST4B.XADIFD)
        connect(eSST4B.Bus, GEN1.p),
        plusInf.y ~ eSST4B.VOEL,   # connect(plusInf.y, eSST4B.VOEL)
        eSST4B.VOTHSG ~ eSST4B.VUEL,   # connect(eSST4B.VOTHSG, eSST4B.VUEL)
        gENROU.ETERM ~ eSST4B.ECOMP,   # connect(gENROU.ETERM, eSST4B.ECOMP)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.ESST4B" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.ESST4B.jl"))
    validate_against_oracle(ESST4B_Test, oracle)
end
