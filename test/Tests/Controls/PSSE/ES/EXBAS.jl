# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/EXBAS.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `EXBAS` is the exciter (suffix _Test); `SMIB(SysData(fn = 60))` is the fn keyword; `const` is `const_`.
@component function EXBAS_Test(; name, S_b = 100e6, fn = 60)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        eXBAS = EXBAS(; T_R = 0.0, K_PR = 140.0, K_IR = 20.0, K_A = 7.0, T_A = 0.0, T_B = 0.03, T_C = 0.214, V_RMAX = 12.536, V_RMIN = -11.282, K_F = 0.0, T_F = 1.0, T_F1 = 0.0, T_F2 = 0.0, K_E = 1.0, T_E = 4.5, K_C = 0.254, K_D = 0.463, E_1 = 2.9250, S_EE_1 = 0.5300, E_2 = 3.9, S_EE_2 = 0.6700)
        gENROU = GENROU(; P_0 = 39999952.912331, Q_0 = 5416571.3489056, v_0 = 1.0, angle_0 = 0.070620673811798, M_b = 160000000.0, Tpd0 = 14.4, Tppd0 = 0.07, Tppq0 = 0.07, H = 4.376, D = 0.0, Xd = 2.58, Xq = 2.23, Xpd = 0.219, Xppd = 0.16, Xppq = 0.16, Xl = 0.123, S10 = 0.1684, S12 = 0.5132, R_a = 0.0, w0 = 0.0, Xpq = 0.36, Tpq0 = 3.9, Xpp = 0.16, S_b, fn)
        const_ = Constant(; k = 0)
    end
    eqs = Equation[
        gENROU.PMECH0 ~ gENROU.PMECH,   # connect(gENROU.PMECH0, gENROU.PMECH)
        eXBAS.EFD ~ gENROU.EFD,   # connect(eXBAS.EFD, gENROU.EFD)
        connect(gENROU.p, GEN1.p),
        gENROU.EFD0 ~ eXBAS.EFD0,   # connect(gENROU.EFD0, eXBAS.EFD0)
        gENROU.ETERM ~ eXBAS.ECOMP,   # connect(gENROU.ETERM, eXBAS.ECOMP)
        eXBAS.VUEL ~ const_.y,   # connect(eXBAS.VUEL, const.y)
        const_.y ~ eXBAS.VOEL,   # connect(const.y, eXBAS.VOEL)
        gENROU.XADIFD ~ eXBAS.XADIFD,   # connect(gENROU.XADIFD, eXBAS.XADIFD)
        eXBAS.VOTHSG ~ const_.y,   # connect(eXBAS.VOTHSG, const.y)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.EXBAS" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.EXBAS.jl"))
    validate_against_oracle(EXBAS_Test, oracle)
end
