# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Controls.PSSE.ES.BaseClasses (PLAN-04, phase 1): the two initialization functions and the rectifier block.
# invFEX inverts FEX: for VE0 = invFEX(K_C, Efd0, Ifd0), VE0*FEX(K_C*Ifd0/VE0) = Efd0 in each of its four branches.
#   FEX(IN) = 1 (IN <= 0), 1 - 0.577 IN (IN <= 0.433), sqrt(0.75 - IN^2) (IN < 0.75), 1.732 (1 - IN) (IN <= 1), 0.
#   (0.2, 2, -1): Ifd0 <= 0 -> VE0 = Efd0 = 2, IN < 0 -> FEX = 1.
#   (0.2, 2, 1): 0.2/(2 + 0.1154) = 0.0945 <= 0.433 -> VE0 = 2.1154, IN = 0.0945, FEX = 1 - 0.577 IN: VE0 - 0.1154 = 2.
#   (1, 1, 1): 1/1.577 = 0.634 > 0.433; r = sqrt(2/0.75) = 1.633, IN = 0.612 in (0.433, 0.75) -> VE0 = r,
#     FEX = sqrt(0.75 - IN^2): sqrt(0.75 r^2 - 1) = sqrt(1 + 1 - 1) = 1.
#   (1, 0.5, 1): 1/1.077 = 0.928; r = sqrt(1.25/0.75) = 1.291, IN = 0.7746 >= 0.75 -> VE0 = (0.5 + 1.732)/1.732
#     = 1.28868, IN = 0.776 <= 1, FEX = 1.732 (1 - IN): 1.732 VE0 - 1.732 = 0.5.
# calculate_dc_exciter_params(V_RMAX, V_RMIN, K_E, E_2 = 5, S_EE_2 = 0.5, Efd0 = 2, SE_Efd0 = 0.02):
#   (0, 0, 0): V_RMAX = S_EE_2*E_2 = 2.5, K_E = 2.5/20 - 0.02 = 0.105, V_RMIN = -2.5.
#   (0, 0, 1): V_RMAX = S_EE_2 + K_E = 1.5, K_E = 1, V_RMIN = -1.5.
#   (7.3, -7.3, 0): V_RMAX = 7.3, K_E = 7.3/20 - 0.02 = 0.345, V_RMIN = -7.3.
#   (7.3, -6, 1): all three pass through.
# RectifierCommutationVoltageDrop(K_C = 0.2): EFD = V_EX*FEX(K_C*XADIFD/V_EX).
#   (V_EX, XADIFD) = (2, 1): IN = 0.1 -> 2*(1 - 0.0577) = 1.8846; (1, 3): IN = 0.6 -> sqrt(0.75 - 0.36) =
#   0.6244997998398398; (1, 4.5): IN = 0.9 -> 1.732*0.1 = 0.1732.
@testset "Controls.PSSE.ES.BaseClasses" begin
    invFEX = OpenIPSLComponents.invFEX
    fex(u) = u <= 0 ? 1.0 : u <= 0.433 ? 1 - 0.577 * u : u < 0.75 ? sqrt(0.75 - u^2) : u <= 1 ? 1.732 * (1 - u) : 0.0
    for (K_C, Efd0, Ifd0) in ((0.2, 2.0, -1.0), (0.2, 2.0, 1.0), (1.0, 1.0, 1.0), (1.0, 0.5, 1.0))
        VE0 = invFEX(K_C, Efd0, Ifd0)
        @test VE0 * fex(K_C * Ifd0 / VE0) ≈ Efd0 atol = 1e-9
    end
    @test invFEX(0.2, 2.0, 1.0) ≈ 2 + 0.577 * 0.2 atol = 1e-12
    @test invFEX(1.0, 1.0, 1.0) ≈ sqrt(2 / 0.75) atol = 1e-12
    @test invFEX(1.0, 0.5, 1.0) ≈ (0.5 + 1.732) / 1.732 atol = 1e-12
    @variables a(t) b(t)
    @test invFEX(0.2, a, b) isa Num          # symbolic arguments, as in the exciters' initialization_eqs

    calc = OpenIPSLComponents.calculate_dc_exciter_params
    @test all(calc(0, 0, 0, 5, 0.5, 2.0, 0.02) .≈ (2.5, -2.5, 0.105))
    @test all(calc(0, 0, 1, 5, 0.5, 2.0, 0.02) .≈ (1.5, -1.5, 1))
    @test all(calc(7.3, -7.3, 0, 5, 0.5, 2.0, 0.02) .≈ (7.3, -7.3, 0.345))
    @test all(calc(7.3, -6, 1, 5, 0.5, 2.0, 0.02) .≈ (7.3, -6, 1))
    @test calc(0, 0, 0, 5, 0.5, a, b)[3] isa Num

    @named r1 = RectifierCommutationVoltageDrop(; K_C = 0.2)
    @named r2 = RectifierCommutationVoltageDrop(; K_C = 0.2)
    @named r3 = RectifierCommutationVoltageDrop(; K_C = 0.2)
    @named rig = System(Equation[r1.V_EX ~ 2, r1.XADIFD ~ 1, r2.V_EX ~ 1, r2.XADIFD ~ 3, r3.V_EX ~ 1, r3.XADIFD ~ 4.5],
        t, [], []; systems = [r1, r2, r3])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.r1.EFD] ≈ 2 * (1 - 0.0577) atol = 1e-9
    @test integ[sys.r2.EFD] ≈ 0.6244997998398398 atol = 1e-9
    @test integ[sys.r3.EFD] ≈ 0.1732 atol = 1e-9
end
