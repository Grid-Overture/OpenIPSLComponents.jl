# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/IEEET1.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: iPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `IEEET1` is the exciter (suffix _Test); the .mo imports `iPSL = OpenIPSL` (alias, no effect here).
@component function IEEET1_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        iEEET1 = IEEET1(; T_R = 0.02, K_A = 200.0, T_A = 0.001, T_E = 0.55, K_F = 0.06, E_1 = 2.85, S_EE_1 = 0.3, E_2 = 3.8, S_EE_2 = 0.6, V_RMAX = 2.0, V_RMIN = -2.0, K_E = 0.1)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        iEEET1.EFD ~ gENROE.EFD,   # connect(iEEET1.EFD, gENROE.EFD)
        iEEET1.ECOMP ~ gENROE.ETERM,   # connect(iEEET1.ECOMP, gENROE.ETERM)
        iEEET1.EFD0 ~ gENROE.EFD0,   # connect(iEEET1.EFD0, gENROE.EFD0)
        iEEET1.VOTHSG ~ zero.y,   # connect(iEEET1.VOTHSG, zero.y)
        iEEET1.VOEL ~ zero.y,   # connect(iEEET1.VOEL, zero.y)
        iEEET1.VUEL ~ zero.y,   # connect(iEEET1.VUEL, zero.y)
        connect(gENROE.p, GEN1.p),
        gENROE.XADIFD ~ iEEET1.XADIFD,   # connect(gENROE.XADIFD, iEEET1.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.IEEET1" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.IEEET1.jl"))
    validate_against_oracle(IEEET1_Test, oracle)
end
