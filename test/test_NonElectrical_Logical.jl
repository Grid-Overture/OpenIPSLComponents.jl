# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# NonElectrical.Logical (PLAN-01).
# HV_GATE(1.2, 0.7) = 1.2, LV_GATE(1.2, 0.7) = 0.7.
# NegCurLogic(RC_rfd = 0.5, nstartvalue = 1): Vd = 2, XadIfd = 0.3 -> Efd = Vd = 2; XadIfd = -0.4 -> Crowbar_V =
#   -0.5*(-0.4) = 0.2 -> Efd = 0.2. With RC_rfd = 0: Crowbar_V = 0.
# Switch_VOEL(n = 1): y1 = u = 0.3, y2 = inf (1e60); n = 2: y1 = 0, y2 = 0.3. Switch_VUEL(n = 1): y2 = -1e60.
@testset "NonElectrical.Logical" begin
    @named hv = HV_GATE()
    @named lv = LV_GATE()
    @named ncl = NegCurLogic(; RC_rfd = 0.5, nstartvalue = 1)
    @named ncl2 = NegCurLogic(; RC_rfd = 0.5, nstartvalue = 1)
    @named ncl0 = NegCurLogic(; RC_rfd = 0, nstartvalue = 1)
    @named sv1 = Switch_VOEL(; n = 1)
    @named sv2 = Switch_VOEL(; n = 2)
    @named su1 = Switch_VUEL(; n = 1)
    @named rig = System(Equation[hv.u1 ~ 1.2, hv.u2 ~ 0.7, lv.u1 ~ 1.2, lv.u2 ~ 0.7,
            ncl.Vd ~ 2, ncl.XadIfd ~ 0.3, ncl2.Vd ~ 2, ncl2.XadIfd ~ -0.4, ncl0.Vd ~ 2, ncl0.XadIfd ~ -0.4,
            sv1.u ~ 0.3, sv2.u ~ 0.3, su1.u ~ 0.3], t, [], []; systems = [hv, lv, ncl, ncl2, ncl0, sv1, sv2, su1])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.hv.y] ≈ 1.2 atol = 1e-9
    @test integ[sys.lv.y] ≈ 0.7 atol = 1e-9
    @test integ[sys.ncl.Efd] ≈ 2 atol = 1e-9
    @test integ[sys.ncl2.Efd] ≈ 0.2 atol = 1e-9
    @test integ[sys.ncl0.Efd] ≈ 0 atol = 1e-9
    @test integ[sys.sv1.y1] ≈ 0.3 atol = 1e-9
    @test integ[sys.sv1.y2] ≈ 1e60
    @test integ[sys.sv2.y1] ≈ 0 atol = 1e-9
    @test integ[sys.sv2.y2] ≈ 0.3 atol = 1e-9
    @test integ[sys.su1.y2] ≈ -1e60
end
