# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/TG/IEESGO.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# GENSAL + SCRX (VOEL, VOTHSG and VUEL to `zero`). The governor is set with T_2 = 0, which selects the T2_dummy
# branch of LeadLag (batch 1).
@component function IEESGO_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENSAL = GENSAL(; Xppd = 0.2, Xppq = 0.2, Xl = 0.12, angle_0 = 0.07068583470577, Tpd0 = 6.7, Tppd0 = 0.028, Tppq0 = 0.0358, H = 4.41, D = 0.0, Xd = 1.22, Xq = 0.76, Xpd = 0.297, S10 = 0.186, S12 = 0.802, M_b = 100000000.0, P_0 = 39999950.0, Q_0 = 5416571.0, v_0 = 1.0, S_b, fn)
        sCRX = SCRX(; T_B = 10.0, K = 100.0, T_E = 0.05, E_MIN = 0.0, E_MAX = 5.0, r_cr_fd = 0.0, C_SWITCH = false, T_AT_B = 0.1)
        zero = Constant(; k = 0)
        iEESGO = IEESGO(; T_1 = 0.01, T_2 = 0.0, T_3 = 0.15, T_4 = 0.3, T_5 = 8.0, T_6 = 0.4, K_2 = 0.7, K_3 = 0.43, P_MAX = 1.0, P_MIN = 0.0, K_1 = 0.1)
    end
    eqs = Equation[
        sCRX.VOEL ~ zero.y,             # connect(sCRX.VOEL, zero.y)
        sCRX.VOTHSG ~ zero.y,           # connect(sCRX.VOTHSG, zero.y)
        gENSAL.EFD0 ~ sCRX.EFD0,        # connect(gENSAL.EFD0, sCRX.EFD0)
        sCRX.EFD ~ gENSAL.EFD,          # connect(sCRX.EFD, gENSAL.EFD)
        gENSAL.ETERM ~ sCRX.ECOMP,      # connect(gENSAL.ETERM, sCRX.ECOMP)
        gENSAL.XADIFD ~ sCRX.XADIFD,    # connect(gENSAL.XADIFD, sCRX.XADIFD)
        iEESGO.SPEED ~ gENSAL.SPEED,    # connect(iEESGO.SPEED, gENSAL.SPEED)
        iEESGO.PMECH ~ gENSAL.PMECH,    # connect(iEESGO.PMECH, gENSAL.PMECH)
        iEESGO.PMECH0 ~ gENSAL.PMECH0,  # connect(iEESGO.PMECH0, gENSAL.PMECH0)
        connect(gENSAL.p, GEN1.p),
        zero.y ~ sCRX.VUEL,             # connect(zero.y, sCRX.VUEL)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.TG.IEESGO" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.TG.IEESGO.jl"))
    validate_against_oracle(IEESGO_Test, oracle)
end
