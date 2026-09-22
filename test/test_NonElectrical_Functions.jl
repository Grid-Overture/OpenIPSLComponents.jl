# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# NonElectrical.Functions (PLAN-01): numeric calls of the functions and the ImSE block on a constant input.
# SE(u, SE1 = 0.11, SE2 = 0.39, E1 = 1, E2 = 1.2) (GENROU test data): a = sqrt(0.11*1/(0.39*1.2)) = 0.48484...,
#   A = 1.2 - (1 - 1.2)/(a - 1) = 1.2 - 0.2/0.51515... = 0.811764..., B = 0.39*1.2*(a-1)^2/(1-1.2)^2 = 0.468*0.265379.../0.04
#   = 3.10493...; SE(1.0) = B*(1 - A)^2/1 = 3.10493*0.035432... = 0.11 (by construction, SE(E1) = SE1) and SE(1.2) = 0.39.
#   SE(0.5) = 0 (u <= A), SE(-1) = 0, SE(...) with SE1 = 0 -> 0.
# SE_exp(u = 1.2, S_EE_1 = 0.1, S_EE_2 = 0.5, E_1 = 1, E_2 = 1.5): X = log(5)/log(1.5) = 3.969..., 0.1*1.2^X = 0.2062....
# div0protect(1, 0) = 1/1e-60 = 1e60 (Modelica.Constants.small), div0protect(3, 2) = 1.5.
@testset "NonElectrical.Functions" begin
    SE = OpenIPSLComponents.SE
    @test SE(1.0, 0.11, 0.39, 1, 1.2) ≈ 0.11 atol = 1e-12
    @test SE(1.2, 0.11, 0.39, 1, 1.2) ≈ 0.39 atol = 1e-12
    @test SE(0.5, 0.11, 0.39, 1, 1.2) == 0
    @test SE(-1.0, 0.11, 0.39, 1, 1.2) == 0
    @test SE(1.0, 0.0, 0.39, 1, 1.2) == 0
    @test OpenIPSLComponents.SE_exp(1.2, 0.1, 0.5, 1, 1.5) ≈ 0.1 * 1.2^(log(5) / log(1.5)) atol = 1e-12
    @test OpenIPSLComponents.div0protect(1.0, 0.0) ≈ 1e60
    @test OpenIPSLComponents.div0protect(3.0, 2.0) ≈ 1.5

    @named imse = ImSE(; SE1 = 0.11, SE2 = 0.39, E1 = 1, E2 = 1.2)
    @named rig = System(Equation[imse.VE_IN ~ 1.2], t, [], []; systems = [imse])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.imse.VE_OUT] ≈ 0.39 atol = 1e-9
end
