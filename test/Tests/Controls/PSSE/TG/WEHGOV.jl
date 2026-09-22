# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/TG/WEHGOV.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB(pwFault(t1 = 2, t2 = 2.15)) - the modifier repeats the base's own
# defaults, so it is a no-op and is transcribed as such (precedent: the AC7B Test of batch 4).
# Omitted: graphical annotations, displayPF.
# GENSAL with no exciter (EFD0 <- EFD). `S_b = SysData.S_b` is the base's system power and `M_b = gENSAL.M_b` the
# machine's rating (120 MVA); both are dead parameters inside WEHGOV, which passes them down and uses neither.
@component function WEHGOV_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENSAL = GENSAL(; P_0 = 40000000.0, Q_0 = 5415812.0, angle_0 = 0.070619983433093, M_b = 120000000.0, Tpd0 = 4.1, Tppd0 = 0.019, Tppq0 = 0.048, H = 3.42, D = 0.0, Xd = 1.1106, Xq = 0.642, Xpd = 0.247, Xppd = 0.232, Xppq = 0.232, Xl = 0.171, S10 = 0.106, S12 = 0.433, R_a = 0.0091, v_0 = 1.0, S_b, fn)
        wEHGOV = WEHGOV(; S_b, M_b = 120000000.0, R_PERM_PE = 0.057, R_PERM_GATE = 0.0, M = 0, TDV = 0.1, TW = 1.2)
    end
    eqs = Equation[
        connect(gENSAL.p, GEN1.p),
        gENSAL.EFD0 ~ gENSAL.EFD,       # connect(gENSAL.EFD0, gENSAL.EFD)
        wEHGOV.PMECH ~ gENSAL.PMECH,    # connect(wEHGOV.PMECH, gENSAL.PMECH)
        gENSAL.SPEED ~ wEHGOV.SPEED,    # connect(gENSAL.SPEED, wEHGOV.SPEED)
        gENSAL.PELEC ~ wEHGOV.PELEC,    # connect(gENSAL.PELEC, wEHGOV.PELEC)
        gENSAL.PMECH0 ~ wEHGOV.PMECH0,  # connect(gENSAL.PMECH0, wEHGOV.PMECH0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.TG.WEHGOV" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.TG.WEHGOV.jl"))
    validate_against_oracle(WEHGOV_Test, oracle)
end
