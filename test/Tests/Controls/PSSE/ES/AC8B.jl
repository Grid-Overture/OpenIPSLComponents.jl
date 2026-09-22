# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/AC8B.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `AC8B` is the exciter (suffix _Test); VPID_MAX/MIN = ±inf (1e60).
@component function AC8B_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROU = GENROU(; Xppd = 0.2059, Xppq = 0.2059, Xpp = 0.2059, Xl = 0.129, angle_0 = 0.070620673811798, Tpd0 = 6.27, Tppd0 = 0.059, Tppq0 = 0.096, H = 4.4710, D = 0.0, Xd = 2.014, Xq = 1.96, Xpd = 0.331, S10 = 0.14, S12 = 0.56, Xpq = 0.466, Tpq0 = 0.7, M_b = 100000000.0, P_0 = 39999952.912331, Q_0 = 5416571.3489056, v_0 = 1.0, S_b, fn)
        const5 = Constant(; k = 0)
        aC8B = AC8B(; T_R = 0.02, K_PR = 160.0, K_IR = 6.0, K_DR = 8.0, T_DR = 0.08, VPID_MAX = OpenIPSLComponents.Modelica.Constants.inf, VPID_MIN = -OpenIPSLComponents.Modelica.Constants.inf, K_A = 1.0, T_A = 0.01, V_RMAX = 7.76, V_RMIN = -6.96, T_E = 1.0, K_C = 0.2, K_D = 0.2, K_E = 1.0, E_1 = 1.0, S_EE_1 = 0.05, E_2 = 2.0, S_EE_2 = 0.5, VFE_MAX = 8.0, VE_MIN = 0.0)
    end
    eqs = Equation[
        aC8B.EFD0 ~ gENROU.EFD0,   # connect(aC8B.EFD0, gENROU.EFD0)
        gENROU.XADIFD ~ aC8B.XADIFD,   # connect(gENROU.XADIFD, aC8B.XADIFD)
        aC8B.ECOMP ~ gENROU.ETERM,   # connect(aC8B.ECOMP, gENROU.ETERM)
        gENROU.PMECH0 ~ gENROU.PMECH,   # connect(gENROU.PMECH0, gENROU.PMECH)
        aC8B.EFD ~ gENROU.EFD,   # connect(aC8B.EFD, gENROU.EFD)
        connect(gENROU.p, GEN1.p),
        const5.y ~ aC8B.VOTHSG,   # connect(const5.y, aC8B.VOTHSG)
        aC8B.VUEL ~ const5.y,   # connect(aC8B.VUEL, const5.y)
        aC8B.VOEL ~ const5.y,   # connect(aC8B.VOEL, const5.y)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.AC8B" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.AC8B.jl"))
    validate_against_oracle(AC8B_Test, oracle)
end
