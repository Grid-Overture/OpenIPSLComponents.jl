# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# AVR of Gen1 alone: constant terminal voltage v = v0, vref = its own vref0, vf0 = gen1's vf00 (OM row t = 0).
# Expected equilibrium: vf = vf00, simpleLagLim.state = vr10 = Ke vf00 + Ae exp(Be |vf00|) vf00, vref0 = v0 + vr10/Ka,
# all derivatives zero. Then a voltage dip v = 0.6 in [0.5, 1.0) s: Ka (vref - vm) ≈ 10.4 > vrmax = 5, so the
# amplifier state winds up above vrmax while the output stays clamped, and when v recovers (Ka u - state crosses to
# negative) the SimpleLagLim event resets it to vrmax (F-06, F-12). The block's own equations and its clamp are
# tested in test_NonElectrical_Continuous.jl; what this test adds is the assembly of the seven blocks.
@testset "AVRTypeII" begin
    v0 = 1.025
    om = OM_T0["gen1"]
    Ka, Ke, Ae, Be = 20, 1, 0.0039, 1.555
    vr10_expected = Ke * om.vf + Ae * exp(Be * abs(om.vf)) * om.vf
    @test vr10_expected ≈ om.state atol = 1e-9
    @test v0 + vr10_expected / Ka ≈ om.vref atol = 1e-9

    @named AVR = AVRTypeII(; vrmin = -5, vrmax = 5, v0 = v0, Ka = Ka, Ta = 0.2, Kf = 0.063, Tf = 0.35, Ke = Ke,
        Te = 0.314, Tr = 0.001, Ae = Ae, Be = Be)
    @named rig = System(Equation[AVR.v ~ ifelse((t < 0.5) | (t >= 1.0), v0, 0.6), AVR.vref ~ AVR.vref0, AVR.vf0 ~ om.vf],
        t, [], []; systems = [AVR])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 2.0))
    integ = init(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)   # runs the DAE initialization
    @test integ[sys.AVR.vf] ≈ om.vf atol = 1e-9
    @test integ[sys.AVR.simpleLagLim.state] ≈ om.state atol = 1e-9
    @test integ[sys.AVR.simpleLagLim.y] ≈ om.state atol = 1e-9
    @test integ[sys.AVR.firstOrder2.y] ≈ v0 atol = 1e-9
    @test integ[sys.AVR.derivativeBlock.x] ≈ om.vf atol = 1e-9
    @test integ[sys.AVR.derivativeBlock.y] ≈ 0 atol = 1e-9
    @test integ[sys.AVR.vref0] ≈ om.vref atol = 1e-9
    for var in (sys.AVR.firstOrder2.y, sys.AVR.simpleLagLim.state, sys.AVR.derivativeBlock.x, sys.AVR.vf)
        @test abs(initial_derivative(integ, sys, var)) < 1e-9
    end

    # the dip edges are plain discontinuities of the test input, not events: tell the solver to stop at them
    sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8, tstops = [0.5, 1.0])
    @test sol.retcode == ReturnCode.Success
    dip = 0.5:0.001:0.999
    @test maximum(sol(dip; idxs = sys.AVR.simpleLagLim.state).u) > 5        # state winds up
    @test maximum(sol(dip; idxs = sys.AVR.simpleLagLim.y).u) ≈ 5 atol = 1e-9   # output clamped at vrmax
    # vm lags v by Tr = 1 ms, so Ka u - state crosses to negative about 1 ms after the recovery; the reset to vrmax
    # then shows as a drop from > 7 to <= 5 within 2 ms (a plain decay from 7.5 at Ta = 0.2 s would still be > 7.4)
    @test sol(1.0; idxs = sys.AVR.simpleLagLim.state) > 7
    @test sol(1.002; idxs = sys.AVR.simpleLagLim.state) <= 5 + 1e-6
    @test sol(1.002; idxs = sys.AVR.simpleLagLim.state) > 4.5
end
