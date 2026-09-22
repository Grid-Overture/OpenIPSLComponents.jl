# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Controls.PSSE.ES.BaseClasses.RotatingExciter* (PLAN-04, phase 1): the five variants at equilibrium, the integrator's
# slope and the variable limit, with T_E = 0.5, K_E = 1, Efd0 = 1.2 and the GENROU saturation data E_1 = 1, E_2 = 1.2,
# S_EE_1 = 0.11, S_EE_2 = 0.39 (SE(1.2) = 0.39, test_NonElectrical_Functions.jl).
# Equilibrium: T_E der(EFD) = I_C - (EFD*SE(EFD) + K_E*EFD [+ K_D*XADIFD]) is zero at EFD = Efd0 for
#   I_C = 1.2*(0.39 + 1) = 1.668 (RotatingExciter, RotatingExciterLimited) and, with K_D = 0.5 and XADIFD = 1,
#   I_C = 2.168 (the three demagnetization variants, whose V_FE = Sum.y = 2.168): EFD stays 1.2.
# Slope: with S_EE_1 = 0 (SE = 0) the exciter is linear, T_E der(EFD) = I_C - K_E EFD; a step of I_C from 1.2 to 1.7
#   at t = 0.5 gives EFD(t) = 1.7 - 0.5 e^{-(t - 0.5)/T_E}: EFD(1) = 1.7 - 0.5/e = 1.516060279414279.
# Variable limit: the VarLim variant with the same linear data (K_D = 0.5, XADIFD = 1, I_C 1.7 -> 2.2 at 0.5 s) and
#   outMax = 1.3, outMin = 0: the integrator state w follows the same exponential until it crosses 1.3 (at
#   t = 0.5 + 0.5 ln(0.5/0.4) = 0.6116 s), then EFD = y = outMax: EFD(0.6) = 1.7 - 0.5 e^{-0.2} = 1.290634623461009,
#   EFD(1) = 1.3.
@testset "Controls.PSSE.ES.BaseClasses.RotatingExciter" begin
    sat = (; T_E = 0.5, K_E = 1, E_1 = 1, E_2 = 1.2, S_EE_1 = 0.11, S_EE_2 = 0.39, Efd0 = 1.2)
    lin = (; sat..., S_EE_1 = 0)
    @named re = RotatingExciter(; sat...)
    @named rel = RotatingExciterLimited(; sat...)
    @named red = RotatingExciterWithDemagnetization(; sat..., K_D = 0.5)
    @named redl = RotatingExciterWithDemagnetizationLimited(; sat..., K_D = 0.5)
    @named redv = RotatingExciterWithDemagnetizationVarLim(; sat..., K_D = 0.5)
    @named re0 = RotatingExciter(; lin...)
    @named redv0 = RotatingExciterWithDemagnetizationVarLim(; lin..., K_D = 0.5)
    @named step = Step(; height = 0.5, offset = 1.2, startTime = 0.5)
    @named stepd = Step(; height = 0.5, offset = 1.7, startTime = 0.5)
    @named rig = System(Equation[re.I_C ~ 1.668, rel.I_C ~ 1.668,
            red.I_C ~ 2.168, red.XADIFD ~ 1, redl.I_C ~ 2.168, redl.XADIFD ~ 1,
            redv.I_C ~ 2.168, redv.XADIFD ~ 1, redv.outMax ~ 10, redv.outMin ~ 0,
            re0.I_C ~ step.y, redv0.I_C ~ stepd.y, redv0.XADIFD ~ 1, redv0.outMax ~ 1.3, redv0.outMin ~ 0],
        t, [], []; systems = [re, rel, red, redl, redv, re0, redv0, step, stepd])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    @test sol.retcode == ReturnCode.Success
    for x in (sys.re, sys.rel, sys.red, sys.redl, sys.redv)
        @test sol(0.0; idxs = x.EFD) ≈ 1.2 atol = 1e-9
        @test sol(1.0; idxs = x.EFD) ≈ 1.2 atol = 1e-6
    end
    for x in (sys.red, sys.redl, sys.redv)
        @test sol(1.0; idxs = x.V_FE) ≈ 2.168 atol = 1e-6
    end
    @test sol(0.5; idxs = sys.re0.EFD) ≈ 1.2 atol = 1e-9
    @test sol(1.0; idxs = sys.re0.EFD) ≈ 1.7 - 0.5 * exp(-1) atol = 1e-6
    @test sol(0.6; idxs = sys.redv0.EFD) ≈ 1.7 - 0.5 * exp(-0.2) atol = 1e-6
    @test sol(1.0; idxs = sys.redv0.EFD) ≈ 1.3 atol = 1e-6
end
