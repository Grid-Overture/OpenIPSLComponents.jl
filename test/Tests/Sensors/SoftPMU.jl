# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Sensors/SoftPMU.mo (a Test of this port, not OpenIPSL's: PLAN-12, family F), transcribed by
# the transcriber (2026-09-21); reviewed by hand.
# extends: none (the network is this port's own). Omitted: graphical annotations, displayPF.
# An ideal VoltageSourceReImInput driven by a 0.2 Hz rotating phasor, a 0.1 pu line, a 20 MW / 4 Mvar PSS/E load,
# and the PMU in the line on the bus2 side, so the voltage it differentiates is an algebraic unknown of the
# network and not the source's own imposed phasor. The exact answer is freq = fn + 0.2 = 50.2 Hz at every
# instant. This network is this port's third attempt: the natural shape, the SMIB with the PMU at the machine
# terminal, does not initialize in OpenModelica under any flag or integrator, because the model puts the analytic
# `Der` on a bus voltage and the differentiated SMIB is singular at the operating point (F-89). ModelingToolkit
# reduces the index of this one without help (F-91). `SoftPMU` is the model, so the Test function takes the
# suffix _Test (PLAN-02 rule).
@component function SoftPMU_Test(; name, S_b = 100e6, fn = 50)
    systems = @named begin
        vRe = Sine(; amplitude = 1, f = 0.2, phase = 1.5707963267948966)
        vIm = Sine(; amplitude = 1, f = 0.2)
        vSource = VoltageSourceReImInput(; S_b, fn)
        bus1 = Bus(; S_b, fn)
        pwLine = PwLine(; R = 0.001, X = 0.1, G = 0.0, B = 0.0, S_b, fn)
        softPMU = SoftPMU(; v_0 = 0.9954344, angle_0 = -0.0203907, Ts = 0.01, S_b, fn)
        bus2 = Bus(; S_b, fn)
        load = Load(; P_0 = 20000000.0, Q_0 = 4000000.0, v_0 = 0.9954344, angle_0 = -0.0203867, characteristic = 2, PQBRAK = 0.7, S_b, fn)
    end
    eqs = Equation[
        vRe.y ~ vSource.vRe,   # connect(vRe.y, vSource.vRe)
        vIm.y ~ vSource.vIm,   # connect(vIm.y, vSource.vIm)
        connect(vSource.p, bus1.p),
        connect(bus1.p, pwLine.p),
        connect(pwLine.n, softPMU.p),
        connect(softPMU.n, bus2.p),
        connect(load.p, bus2.p),
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "PortTests.Sensors.SoftPMU" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "oracle", "Sensors.SoftPMU.jl"))
    validate_against_oracle(SoftPMU_Test, oracle)
end
