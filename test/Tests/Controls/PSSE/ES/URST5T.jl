# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/URST5T.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `URST5T` is the exciter (suffix _Test) at its defaults; ECOMP is fed with PELEC and angle_0 = 4.046 rad (sic, PLAN-04). rtol = 1e-2 (F-27's form, F-45): the Test's machine starts 232 degrees from its
# equilibrium (`angle_0 = 4.046`, sic) and its exciter regulates `PELEC` (sic), a 3 Hz swing with the terminal voltage
# collapsing to 0.1 pu and the variable limits of `simpleLagLimVar` crossing sign every 150 ms; OpenModelica's own
# trajectory moves by up to 8.9e-3 between tolerances 1e-6 and 1e-8, the MTK solution at 1e-6 and 1e-7 is within
# 1.5 % of the 1e-6 oracle and closer to OM at 1e-8, so the oracle's floor is 1e-2 here.
@component function URST5T_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROU = GENROU(; Xppd = 0.2, Xppq = 0.2, Xpp = 0.2, Xl = 0.12, angle_0 = 4.04626655578613, Tpd0 = 5.0, Tppd0 = 0.50000E-01, Tppq0 = 0.1, H = 4.0000, D = 0.0, Xd = 1.41, Xq = 1.3500, Xpd = 0.3, S10 = 0.1, S12 = 0.5, Xpq = 0.6, Tpq0 = 0.7, M_b = 100000000.0, P_0 = 39999952.9123306, Q_0 = 5416571.34890556, v_0 = 1.0, S_b, fn)
        const2 = Constant(; k = 0)
        VOEL = Constant(; k = 1000)
        uRST5T = URST5T()
        VUEL = Constant(; k = -1000)
        VOTHSG = Constant(; k = 0)
    end
    eqs = Equation[
        VUEL.y ~ uRST5T.VUEL,   # connect(VUEL.y, uRST5T.VUEL)
        VOEL.y ~ uRST5T.VOEL,   # connect(VOEL.y, uRST5T.VOEL)
        VOTHSG.y ~ uRST5T.VOTHSG,   # connect(VOTHSG.y, uRST5T.VOTHSG)
        gENROU.XADIFD ~ uRST5T.XADIFD,   # connect(gENROU.XADIFD, uRST5T.XADIFD)
        gENROU.EFD0 ~ uRST5T.EFD0,   # connect(gENROU.EFD0, uRST5T.EFD0)
        gENROU.PMECH0 ~ gENROU.PMECH,   # connect(gENROU.PMECH0, gENROU.PMECH)
        gENROU.PELEC ~ uRST5T.ECOMP,   # connect(gENROU.PELEC, uRST5T.ECOMP)
        uRST5T.EFD ~ gENROU.EFD,   # connect(uRST5T.EFD, gENROU.EFD)
        connect(gENROU.p, GEN1.p),
        uRST5T.VT ~ uRST5T.ECOMP,   # connect(uRST5T.VT, uRST5T.ECOMP)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.URST5T" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.URST5T.jl"))
    validate_against_oracle(URST5T_Test, oracle; rtol = 1e-2)
end
