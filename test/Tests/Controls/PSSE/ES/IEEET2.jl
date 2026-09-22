# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/IEEET2.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `IEEET2` is the exciter (suffix _Test).
@component function IEEET2_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        iEEET2 = IEEET2(; T_R = 0.02, K_A = 200.0, T_A = 0.001, T_E = 0.55, K_F = 0.06, T_F1 = 0.3, T_F2 = 0.6, E_1 = 2.85, S_EE_1 = 0.3, E_2 = 3.8, S_EE_2 = 0.6, V_RMAX = 2.0, V_RMIN = -2.0, K_E = 0.1)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        iEEET2.EFD ~ gENROE.EFD,   # connect(iEEET2.EFD, gENROE.EFD)
        iEEET2.ECOMP ~ gENROE.ETERM,   # connect(iEEET2.ECOMP, gENROE.ETERM)
        iEEET2.EFD0 ~ gENROE.EFD0,   # connect(iEEET2.EFD0, gENROE.EFD0)
        iEEET2.VOTHSG ~ zero.y,   # connect(iEEET2.VOTHSG, zero.y)
        iEEET2.VOEL ~ zero.y,   # connect(iEEET2.VOEL, zero.y)
        iEEET2.VUEL ~ zero.y,   # connect(iEEET2.VUEL, zero.y)
        connect(gENROE.p, GEN1.p),
        gENROE.XADIFD ~ iEEET2.XADIFD,   # connect(gENROE.XADIFD, iEEET2.XADIFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.IEEET2" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.IEEET2.jl"))
    validate_against_oracle(IEEET2_Test, oracle)
end
