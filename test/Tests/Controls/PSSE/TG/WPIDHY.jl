# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/TG/WPIDHY.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB(constantLoad(angle_0 = -0.0100577809552), SysData(fn = 60)).
# Omitted: graphical annotations, displayPF.
# The `SysData(fn = 60)` modifier of the extends is the base's `fn` keyword (every component of the transcribed SMIB
# takes it), and the `constantLoad` modifier goes through `mods` (precedent: the batch-4 Tests).
# GENSAL with no exciter (EFD0 <- EFD); `WPIDHY` takes SPEED and PELEC and has no PMECH0 port.
@component function WPIDHY_Test(; name, S_b = 100e6, fn = 60)
    @named base = SMIB(; S_b, fn, mods = (; constantLoad = (; angle_0 = -0.0100577809552)))
    @unpack GEN1 = base
    systems = @named begin
        gENSAL = GENSAL(; Xppd = 0.2, Xppq = 0.2, Xl = 0.12, Tpd0 = 5.0, Tppd0 = 0.05, Tppq0 = 0.1, H = 4.0, D = 0.0, Xd = 1.41, Xq = 1.35, Xpd = 0.3, S10 = 0.1, S12 = 0.5, angle_0 = 0.07068583470577, M_b = 100000000.0, P_0 = 39999950.0, Q_0 = 5416571.0, v_0 = 1.0, S_b, fn)
        wPIDHY = WPIDHY(; T_REG = 1.0, REG = -0.05, K_P = 3.0, K_I = 0.3, K_D = 0.0, T_A = 0.01, T_W = 1.47, T_B = 0.25, VELMX = 0.132, VELMN = -0.132, GATMX = 1.0, GATMN = 0.0, PMAX = 1.0, PMIN = 0.258, D = 0.0, G0 = 0.0833, G1 = 0.5, G2 = 0.75, P1 = 0.591, P2 = 0.817, P3 = 0.9785)
    end
    eqs = Equation[
        wPIDHY.PELEC ~ gENSAL.PELEC,     # connect(wPIDHY.PELEC, gENSAL.PELEC)
        gENSAL.EFD0 ~ gENSAL.EFD,        # connect(gENSAL.EFD0, gENSAL.EFD)
        wPIDHY.PMECH ~ gENSAL.PMECH,     # connect(wPIDHY.PMECH, gENSAL.PMECH)
        gENSAL.SPEED ~ wPIDHY.SPEED,     # connect(gENSAL.SPEED, wPIDHY.SPEED)
        connect(gENSAL.p, GEN1.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.TG.WPIDHY" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.TG.WPIDHY.jl"))
    validate_against_oracle(WPIDHY_Test, oracle)
end
