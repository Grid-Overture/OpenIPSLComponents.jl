# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Renewable/PSSE/WindPlant.mo, transcribed automatically --kind test
# (2026-09-17); reviewed by hand. extends: OpenIPSL.Tests.BaseClasses.SMIBRenewable (no modifier, so fn = 50).
# The only Test of the batch with `REECA1` (its two anti-windup PIs, its VDL tables with the `+k*eps` abscissas --
# here the four voltages are 0.1/0.4/0.6/0.9 and 0.1/0.5/0.9/1, distinct by far) and with the drive train.
# `TOscillation = 0` -> `pflag = false` -> `GeneratorSpeed = 1`: `wg` is computed and not used.
# `vref0 = 0` -> `Vref0 = V0`, a `missing` chain (F-38).
# Two testsets, for the same reason as PVPlant: the shipped `Kp = 18` makes the operating point unstable (F-64).
@component function WindPlant(; name, S_b = 100e6, fn = 50, Kp = 18.0)
    @named base = SMIBRenewable(; S_b, fn)
    @unpack GEN1, freq, pwVoltage, pwCurrent = base
    systems = @named begin
        wind = Wind(; P_0 = 1500000.0, Q_0 = -5665800.0, v_0 = 1.0, angle_0 = 0.02574992,
            QFunctionality = 4, PFunctionality = 0, TOscillation = 0, W0 = 0.0, S_b, fn,
            mods = (; RenewableGenerator = (; redeclare = REGCA1, Tg = 0.01, rrpwr = 3.0, Brkpt = 0.8,
                    Zerox = 0.1, Lvpl1 = 1.22, Volim = 1.2, lvpnt1 = 0.6, lvpnt0 = 0.1, Iolim = -1.3,
                    Tfltr = 0.02, Khv = 1.0, Iqrmax = 99.0, Iqrmin = -99.0),
                PlantController = (; redeclare = REPCA1, Kp = Kp),
                RenewableController = (; redeclare = REECA1, pqflag = false, dbd1 = -0.1, dbd2 = 0.1,
                    Iqh1 = 1.0, Iql1 = -1.0, vref0 = 0.0, Iqfrz = 0.07, Tp = 0.3, Qmax = 0.5, Qmin = -0.5,
                    Vmax = 1.1, Vmin = 0.9, Kqp = 0.1, Kqi = 0.1, Kvp = 1.6, Kvi = 1.0, Vbias = 0.0,
                    Tiq = 0.01, dPmax = 99.0, dPmin = -99.0, Pmax = 1.0, Pmin = 0.0, Imax = 1.2, Tpord = 0.3,
                    Vq1 = 0.1, Iq1 = 0.01, Vq2 = 0.4, Iq2 = 0.5, Vq3 = 0.6, Iq3 = 0.7, Vq4 = 0.9, Iq4 = 1.0,
                    Vp1 = 0.1, Ip1 = 0.4, Vp2 = 0.5, Ip2 = 0.7, Vp3 = 0.9, Ip3 = 1.2, Vp4 = 1.0, Ip4 = 1.2),
                DriveTrain = (; redeclare = WTDTA1, H = 0.01, Freq1 = 10.0, Dshaft = 0.015)))
    end
    eqs = Equation[
        connect(wind.pwPin, GEN1.p),
        freq.y ~ wind.FREQ,                  # connect(freq.y, wind.FREQ)
        wind.regulate_vi ~ pwVoltage.vi,     # connect(wind.regulate_vi, pwVoltage.vi)
        pwVoltage.vr ~ wind.regulate_vr,     # connect(pwVoltage.vr, wind.regulate_vr)
        wind.branch_ir ~ pwCurrent.ir,       # connect(wind.branch_ir, pwCurrent.ir)
        pwCurrent.ii ~ wind.branch_ii,       # connect(pwCurrent.ii, wind.branch_ii)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Renewable.PSSE.WindPlant" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Renewable.PSSE.WindPlant.jl"))
    validate_operating_point(WindPlant, oracle)
end

@testset "Tests.Renewable.PSSE.WindPlant (Kp = 1)" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Renewable.PSSE.WindPlant_Kp1.jl"))
    validate_against_oracle(WindPlant, oracle; Kp = 1.0)
end
