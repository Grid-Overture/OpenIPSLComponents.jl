# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSSE/TG/WSIEG1.mo, transcribed by hand (2026-09-15).
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# GENROU with no exciter (EFD0 <- EFD). The Test activates `Deadband2` (db2 = 0.01) and sets T_2 = T_7 = 0 and
# db1 = err = 0. It is the Test that settles F-22 (6): OpenModelica freezes `deadband2.y` at 0 for the whole run,
# exactly as ModelingToolkit does, and does not honour the `y(start = GV0)` modifier (F-50).
@component function WSIEG1_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROU = GENROU(; P_0 = 40000000.0, Q_0 = 5415812.0, angle_0 = 0.070619983433093, M_b = 150000000.0, Tpd0 = 4.815, Tppd0 = 0.046, Tppq0 = 0.04, H = 4.39, D = 0.0, Xd = 1.24, Xq = 1.22, Xpd = 0.216, Xppd = 0.165, Xppq = 0.165, Xl = 0.148, S10 = 0.111, S12 = 0.356, R_a = 0.0, Xpq = 0.382, Tpq0 = 1.0, v_0 = 1.0, S_b, fn)
        wSIEG1 = WSIEG1(; T_2 = 0.0, T_7 = 0.0, db1 = 0.0, err = 0.0, db2 = 0.01)
    end
    eqs = Equation[
        connect(gENROU.p, GEN1.p),
        gENROU.EFD0 ~ gENROU.EFD,          # connect(gENROU.EFD0, gENROU.EFD)
        wSIEG1.PMECH_HP ~ gENROU.PMECH,    # connect(wSIEG1.PMECH_HP, gENROU.PMECH)
        gENROU.SPEED ~ wSIEG1.SPEED_HP,    # connect(gENROU.SPEED, wSIEG1.SPEED_HP)
        gENROU.PMECH0 ~ wSIEG1.PMECH0,     # connect(gENROU.PMECH0, wSIEG1.PMECH0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSSE.TG.WSIEG1" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.TG.WSIEG1.jl"))
    validate_against_oracle(WSIEG1_Test, oracle)
end
