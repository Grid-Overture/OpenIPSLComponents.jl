# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSAT/TG/TGTypeVI_test.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.TGTestBase. Omitted: graphical annotations, displayPF.
# With `dref = 0` the RealToBoolean/Switch pair selects the `pe - pref` branch, and with `Kd = 0` the Derivative is
# the zeroGain branch (its output is identically 0).
@component function TGTypeVI_test(; name, S_b = 100e6, fn = 50)
    @named base = TGTestBase(; S_b, fn)
    @unpack gen = base
    systems = @named begin
        tGTypeVI = TGTypeVI(; Ka = 3.33333, Ta = 0.07, vmin = -0.1, vmax = 0.1, gmax = 0.97518, gmin = 0.01,
            Rp = 0.05, Kp = 1.163, Ki = 0.105, Kd = 0.0, Td = 0.01, beta = 0.1, Tw = 2.67, dref = 0.0, po = 0.16074)
        sine2 = Sine(; f = 0.2, startTime = 10, amplitude = -0.001, offset = 0)
        Perturbation = Add(; k2 = +1)
        sine1 = Sine(; f = 0.2, startTime = 5, amplitude = 0.001, offset = 1)
    end
    eqs = Equation[
        Perturbation.u1 ~ sine1.y,          # connect(sine1.y, Perturbation.u1)
        gen.pm ~ tGTypeVI.Pm,               # connect(tGTypeVI.Pm, gen.pm)
        Perturbation.u2 ~ sine2.y,          # connect(Perturbation.u2, sine2.y)
        tGTypeVI.wref ~ Perturbation.y,     # connect(Perturbation.y, tGTypeVI.wref)
        tGTypeVI.pref ~ gen.pm0,            # connect(gen.pm0, tGTypeVI.pref)
        tGTypeVI.pe ~ gen.P,                # connect(gen.P, tGTypeVI.pe)
        tGTypeVI.we ~ gen.w,                # connect(gen.w, tGTypeVI.we)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSAT.TG.TGTypeVI_test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSAT.TG.TGTypeVI_test.jl"))
    # five states carry no initialization equation - the three Integrator(NoInit), the TransferFunction (MSL's
    # default NoInit) and the Derivative, whose zeroGain branch makes der(x) = 0 for any x with Kd = 0 - and
    # OpenModelica fixes all five at their own start: po*(gmax - gmin), po, po*(gmax - gmin), 0, 0
    # (F-28, confirmed in row 0 of the oracle)
    y_int = 0.16074 * (0.97518 - 0.01)
    validate_against_oracle(TGTypeVI_test, oracle;
        u0 = sys -> [sys.tGTypeVI.integrator.y => y_int, sys.tGTypeVI.integrator3.y => 0.16074,
            sys.tGTypeVI.integrator5.y => y_int, sys.tGTypeVI.transferFunction.x_scaled => [0.0],
            sys.tGTypeVI.derivative.x => 0.0])
end
