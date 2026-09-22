# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/TG/HYGOV.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# GENSAL + SCRX (VOEL, VOTHSG and VUEL to `zero`), the same machine and exciter as the IEESGO Test.
@component function HYGOV_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENSAL = GENSAL(; Xppd = 0.2, Xppq = 0.2, Xl = 0.12, angle_0 = 0.07068583470577, Tpd0 = 6.7, Tppd0 = 0.028, Tppq0 = 0.0358, H = 4.41, D = 0.0, Xd = 1.22, Xq = 0.76, Xpd = 0.297, S10 = 0.186, S12 = 0.802, M_b = 100000000.0, P_0 = 39999950.0, Q_0 = 5416571.0, v_0 = 1.0, S_b, fn)
        hYGOV = HYGOV(; VELM = 0.02, G_MAX = 0.415, R = 0.05, r = 0.3, T_r = 5.0, T_f = 0.05, T_g = 0.5, G_MIN = 0.0, T_w = 1.25, A_t = 1.2, D_turb = 0.2, q_NL = 0.08)
        sCRX = SCRX(; T_B = 10.0, K = 100.0, T_E = 0.05, E_MIN = 0.0, E_MAX = 5.0, r_cr_fd = 0.0, C_SWITCH = false, T_AT_B = 0.1)
        zero = Constant(; k = 0)
    end
    eqs = Equation[
        sCRX.VOEL ~ zero.y,             # connect(sCRX.VOEL, zero.y)
        sCRX.VOTHSG ~ zero.y,           # connect(sCRX.VOTHSG, zero.y)
        gENSAL.EFD0 ~ sCRX.EFD0,        # connect(gENSAL.EFD0, sCRX.EFD0)
        gENSAL.PMECH0 ~ hYGOV.PMECH0,   # connect(gENSAL.PMECH0, hYGOV.PMECH0)
        gENSAL.SPEED ~ hYGOV.SPEED,     # connect(gENSAL.SPEED, hYGOV.SPEED)
        hYGOV.PMECH ~ gENSAL.PMECH,     # connect(hYGOV.PMECH, gENSAL.PMECH)
        sCRX.EFD ~ gENSAL.EFD,          # connect(sCRX.EFD, gENSAL.EFD)
        gENSAL.ETERM ~ sCRX.ECOMP,      # connect(gENSAL.ETERM, sCRX.ECOMP)
        gENSAL.XADIFD ~ sCRX.XADIFD,    # connect(gENSAL.XADIFD, sCRX.XADIFD)
        connect(gENSAL.p, GEN1.p),
        sCRX.VUEL ~ zero.y,             # connect(sCRX.VUEL, zero.y)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

# `atol = 3e-4`: HYGOV drives its velocity limiter through `SimpleLead`, a block that differentiates its input, so
# the local truncation error of the governor chain is amplified. At the experiment tolerance (1e-6) MTK differs from
# the oracle by 1.9e-4 on `simpleLead.y`/`Velocity_Limiter.u` (limit 1.8e-4) and 1.1e-4 on `add2.y`/`q.u` (limit
# 1.06e-4); at abstol = reltol = 1e-8 the same MTK model matches the oracle to 1.3e-5 on every variable, i.e. the
# difference is ModelingToolkit's own error at 1e-6, not a difference of model (F-27's check, opposite conclusion).
@testset "Tests.Controls.PSSE.TG.HYGOV" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.TG.HYGOV.jl"))
    validate_against_oracle(HYGOV_Test, oracle; atol = 3e-4)
end
