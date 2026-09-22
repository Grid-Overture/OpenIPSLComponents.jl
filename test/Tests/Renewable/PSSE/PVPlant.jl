# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Renewable/PSSE/PVPlant.mo, transcribed automatically --kind test
# (2026-09-17); reviewed by hand. extends: OpenIPSL.Tests.BaseClasses.SMIBRenewable(SysData(fn = 60),
# freq(k = SysData.fn)), i.e. just `fn = 60` here.
# `angle_0(displayUnit = "deg") = 0.02574992` is the value in radians (the displayUnit is a dialog annotation).
# The `redeclare`s bring only `vref0 = 1` on the controller; every other modifier of the `replaceable` declarations
# (V_b, M_b, P_0, Q_0, v_0, angle_0, pfflag, vflag, qflag, pqflag, fflag, refflag) survives the redeclare, which is
# the MLS 7.3.2 merge `PV.jl` implements. Omitted: graphical annotations, displayPF.
#
# **Two testsets, because the shipped operating point is an unstable equilibrium (F-64).** With the plant
# controller's default `Kp = 18` the reactive loop has a right-half-plane pole: OpenModelica's own run leaves the
# power-flow point between t = 1.73 s and t = 2.50 s when the fault is removed, and after the fault its PI slams
# between +-Qmax for the rest of the run. Neither tool reproduces that trajectory - each amplifies its own seed - so
# the literal Test is validated at its operating point only, and the trajectory is validated on the same model with
# the single Julia-only override `Kp = 1`, for which OpenModelica is stable and the two tools agree on all 317
# variables through the whole fault. Both oracles come from `run_om_tests.mos` (the second via `simflags`).
@component function PVPlant(; name, S_b = 100e6, fn = 60, Kp = 18.0)
    @named base = SMIBRenewable(; S_b, fn)
    @unpack GEN1, freq, pwVoltage, pwCurrent = base
    systems = @named begin
        pV = PV(; P_0 = 1500000.0, Q_0 = -5665800.0, v_0 = 1.0, angle_0 = 0.02574992,
            QFunctionality = 4, PFunctionality = 0, Irr2Pow = false, S_b, fn,
            mods = (; RenewableGenerator = (; redeclare = REGCA1),
                RenewableController = (; redeclare = REECB1, vref0 = 1.0),
                PlantController = (; redeclare = REPCA1, Kp = Kp)))
    end
    eqs = Equation[
        connect(pV.pwPin, GEN1.p),
        freq.y ~ pV.FREQ,                  # connect(freq.y, pV.FREQ)
        pwVoltage.vi ~ pV.regulate_vi,     # connect(pwVoltage.vi, pV.regulate_vi)
        pwVoltage.vr ~ pV.regulate_vr,     # connect(pwVoltage.vr, pV.regulate_vr)
        pV.branch_ir ~ pwCurrent.ir,       # connect(pV.branch_ir, pwCurrent.ir)
        pwCurrent.ii ~ pV.branch_ii,       # connect(pwCurrent.ii, pV.branch_ii)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Renewable.PSSE.PVPlant" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Renewable.PSSE.PVPlant.jl"))
    validate_operating_point(PVPlant, oracle)
end

@testset "Tests.Renewable.PSSE.PVPlant (Kp = 1)" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Renewable.PSSE.PVPlant_Kp1.jl"))
    validate_against_oracle(PVPlant, oracle; Kp = 1.0)
end
