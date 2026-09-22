# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/NonElectrical/Nonlinear/FrequencyCalc.mo (a Test of this port, not OpenIPSL's: PLAN-12,
# family A), transcribed automatically (2026-09-21); reviewed by hand.
# extends: none. Omitted: graphical annotations, displayPF.
# The block alone, fed one rotating phasor of 51 Hz built out of the harness's own Sine source (phase = pi/2 makes
# the real part a cosine), so the exact answer is y = 2*pi*51 = 320.4425 rad/s at every instant. This is the Test
# that brings Modelica.Blocks.Continuous.Der into the mini-MSL; `Ts`, `start_guess`, `real_start` and `imag_start`
# reach nothing in the model and are passed only because the .mo sets them (F-89). The Test function takes the
# suffix _Test because `FrequencyCalc` is the model (PLAN-02 rule).
@component function FrequencyCalc_Test(; name)
    systems = @named begin
        frequencyCalc = FrequencyCalc(; start_guess = true, real_start = 1, imag_start = 0, Ts = 0.01)
        real_part = Sine(; amplitude = 1, f = 51, phase = 1.5707963267948966)
        imag_part = Sine(; amplitude = 1, f = 51)
    end
    eqs = Equation[
        real_part.y ~ frequencyCalc.real_part,   # connect(real_part.y, frequencyCalc.real_part)
        imag_part.y ~ frequencyCalc.imag_part,   # connect(imag_part.y, frequencyCalc.imag_part)
    ]
    System(eqs, t, [], []; name, systems)
end

@testset "PortTests.NonElectrical.Nonlinear.FrequencyCalc" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "NonElectrical.Nonlinear.FrequencyCalc.jl"))
    validate_against_oracle(FrequencyCalc_Test, oracle)
end
