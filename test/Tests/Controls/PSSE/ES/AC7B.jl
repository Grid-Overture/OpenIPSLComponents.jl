# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/AC7B.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `AC7B` is the exciter (suffix _Test); `SMIB(pwFault(t1 = 2, t2 = 2.15))` equals the defaults; `const` is `const_`.
@component function AC7B_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn, mods = (; pwFault = (; t1 = 2, t2 = 2.15)))
    @unpack GEN1 = base
    systems = @named begin
        gENROU = GENROU(; P_0 = 40000000.0, Q_0 = 5415812.0, angle_0 = 0.070619983433093, M_b = 100000000.0, Tpd0 = 6.9, Tppd0 = 0.06, Tppq0 = 0.3, H = 7.79, D = 0.0, Xd = 1.18, Xq = 1.27, Xpd = 0.15, Xppd = 0.083, Xppq = 0.083, Xl = 0.064, S10 = 0.155, S12 = 0.58, Xpq = 0.407, Tpq0 = 1.5, S_b, fn)
        aC7B = AC7B(; T_R = 0.0, K_PR = 9.0, K_IR = 1.5, K_DR = 2.2, T_DR = 0.0167, V_RMAX = 5.5, V_RMIN = -5.5, K_PA = 1.0, K_IA = 0.005, VA_MIN = -5.5, VA_MAX = 5.5, K_P = 1.0, K_L = 99.0, T_E = 0.8, K_C = 0.0, K_D = 0.0, K_E = 1.0, K_F1 = 0.0, K_F2 = 0.0, K_F3 = 0.0, T_F3 = 1.0, VE_MIN = 0.0, VFE_MAX = 5.5, E_1 = 2.75, S_EE_1 = 0.08, E_2 = 3.8, S_EE_2 = 0.3)
        const_ = Constant(; k = 0)
    end
    eqs = Equation[
        connect(gENROU.p, GEN1.p),
        gENROU.PMECH0 ~ gENROU.PMECH,   # connect(gENROU.PMECH0, gENROU.PMECH)
        const_.y ~ aC7B.VOEL,   # connect(const.y, aC7B.VOEL)
        aC7B.VUEL ~ aC7B.VOEL,   # connect(aC7B.VUEL, aC7B.VOEL)
        gENROU.ETERM ~ aC7B.ECOMP,   # connect(gENROU.ETERM, aC7B.ECOMP)
        gENROU.XADIFD ~ aC7B.XADIFD,   # connect(gENROU.XADIFD, aC7B.XADIFD)
        gENROU.EFD0 ~ aC7B.EFD0,   # connect(gENROU.EFD0, aC7B.EFD0)
        aC7B.VT ~ aC7B.ECOMP,   # connect(aC7B.VT, aC7B.ECOMP)
        aC7B.VOTHSG ~ aC7B.VOEL,   # connect(aC7B.VOTHSG, aC7B.VOEL)
        aC7B.EFD ~ gENROU.EFD,   # connect(aC7B.EFD, gENROU.EFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.AC7B" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.AC7B.jl"))
    validate_against_oracle(AC7B_Test, oracle)
end
