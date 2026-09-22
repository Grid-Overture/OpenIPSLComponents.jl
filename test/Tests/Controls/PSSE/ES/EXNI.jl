# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/ES/EXNI.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `EXNI` is the exciter (suffix _Test), at its defaults (SWITCH = false, r_cr_fd = 10).
@component function EXNI_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENROE(; Tpd0 = 5.0, Tppd0 = 0.07, Tpq0 = 0.9, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xpq = 0.6, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        zero = Constant(; k = 0)
        eXNI = EXNI()
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        connect(gENROE.p, GEN1.p),
        eXNI.VOTHSG ~ zero.y,   # connect(eXNI.VOTHSG, zero.y)
        eXNI.ECOMP ~ gENROE.ETERM,   # connect(eXNI.ECOMP, gENROE.ETERM)
        eXNI.XADIFD ~ gENROE.XADIFD,   # connect(eXNI.XADIFD, gENROE.XADIFD)
        eXNI.EFD0 ~ gENROE.EFD0,   # connect(eXNI.EFD0, gENROE.EFD0)
        eXNI.VUEL ~ zero.y,   # connect(eXNI.VUEL, zero.y)
        eXNI.VOEL ~ zero.y,   # connect(eXNI.VOEL, zero.y)
        eXNI.EFD ~ gENROE.EFD,   # connect(eXNI.EFD, gENROE.EFD)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.ES.EXNI" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.ES.EXNI.jl"))
    validate_against_oracle(EXNI_Test, oracle)
end
