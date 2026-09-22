# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Renewable/PSSE/BESSPlant.mo, transcribed automatically --kind test
# (2026-09-17); reviewed by hand. extends: OpenIPSL.Tests.BaseClasses.SMIBRenewable (no modifier, so fn = 50 here;
# `fn = SysData.fn` on the plant is that same 50).
# `V_b = 100e3` comes from the `redeclare`, which wins over the `V_b = V_b` of the `replaceable` declaration
# (MLS 7.3.2, the merge `BESS.jl` implements). `pfflag/vflag/qflag/pqflag = false` are written by the redeclare and
# also by the declaration: they agree.
# Two testsets, for the same reason as PVPlant: the shipped `Kp = 18` makes the operating point unstable (F-64).
@component function BESSPlant(; name, S_b = 100e6, fn = 50, Kp = 18.0)
    @named base = SMIBRenewable(; S_b, fn)
    @unpack GEN1, freq, pwVoltage, pwCurrent = base
    systems = @named begin
        bESS = BESS(; fn, P_0 = 1500000.0, Q_0 = -5665800.0, v_0 = 1.0, angle_0 = 0.02574992,
            QFunctionality = 4, PFunctionality = 0, S_b,
            mods = (; RenewableGenerator = (; redeclare = REGCA1, V_b = 100000.0, Tg = 0.017, Brkpt = 0.1,
                    lvpnt1 = 0.2, lvpnt0 = 0.05, Iqrmax = 99.0, Iqrmin = -99.0, Lvplsw = true),
                RenewableController = (; redeclare = REECCU1, pfflag = false, vflag = false, qflag = false,
                    pqflag = false, dbd1 = -0.05, dbd2 = 0.05, Kqv = 15.0, Iqh1 = 0.75, Iql1 = -0.75, Tp = 0.05,
                    Qmax = 0.75, Qmin = -0.75, Kqi = 1.0, Kvi = 1.0, Tiq = 0.017, Pmin = -0.667, Imax = 1.11,
                    Tpord = 0.017, Vq1 = 0.0, Vq2 = 0.2, Vq3 = 0.5, Vq4 = 1.0),
                PlantController = (; redeclare = REPCA1, Kp = Kp)))
    end
    eqs = Equation[
        connect(bESS.pwPin, GEN1.p),
        freq.y ~ bESS.FREQ,                  # connect(freq.y, bESS.FREQ)
        pwVoltage.vi ~ bESS.regulate_vi,     # connect(pwVoltage.vi, bESS.regulate_vi)
        pwVoltage.vr ~ bESS.regulate_vr,     # connect(pwVoltage.vr, bESS.regulate_vr)
        bESS.branch_ir ~ pwCurrent.ir,       # connect(bESS.branch_ir, pwCurrent.ir)
        pwCurrent.ii ~ bESS.branch_ii,       # connect(pwCurrent.ii, bESS.branch_ii)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Renewable.PSSE.BESSPlant" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Renewable.PSSE.BESSPlant.jl"))
    validate_operating_point(BESSPlant, oracle)
end

@testset "Tests.Renewable.PSSE.BESSPlant (Kp = 1)" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Renewable.PSSE.BESSPlant_Kp1.jl"))
    validate_against_oracle(BESSPlant, oracle; Kp = 1.0)
end
