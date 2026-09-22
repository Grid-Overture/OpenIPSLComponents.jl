# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Examples.Tutorial.{Example_1, Example_2} (PLAN-06, phase 6): the two systems compile and their initial point is
# OpenModelica's row 0 of om_example_{1,2}.csv (DASSL, tol 1e-6, default solver).
# The same operating point as Examples.KundurSMIB.SMIB_AVR (the same unit and power flow, Taa = 0.002 instead of 0,
# which does not move t = 0 because id0 enters vf00 through K1 either way): three bus voltages, the machine's rotor
# angle and speed, the AVRtypeIII field voltage and, in Example_2, the PSSTypeII output at zero.
# OpenModelica fixes `G1.machine.w` and `G1.machine.delta` in Example_1 and only `delta` in Example_2 (which declares
# `w(fixed = true)`), both of which baseMachine already carries (F-11), so no `u0` hook is needed.
const OM_TUTORIAL_12_T0 = (; B1 = 0.999999999998, B2 = 0.944299492909, B3 = 0.90081,
    delta = 1.22424746441, vf = 2.42070164208)

@testset "Examples.Tutorial.Example_1_2" begin
    for (ctor, has_pss) in ((Example_1, false), (Example_2, true))
        @named sys0 = ctor()
        sys = mtkcompile(sys0)
        integ = init(ODEProblem(sys, [], (0.0, 10.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
        @test integ[sys.B1.v] ≈ OM_TUTORIAL_12_T0.B1 atol = 1e-6
        @test integ[sys.B2.v] ≈ OM_TUTORIAL_12_T0.B2 atol = 1e-6
        @test integ[sys.B3.v] ≈ OM_TUTORIAL_12_T0.B3 atol = 1e-6
        @test integ[sys.G1.machine.delta] ≈ OM_TUTORIAL_12_T0.delta atol = 1e-6
        @test integ[sys.G1.machine.w] ≈ 1 atol = 1e-9
        @test integ[sys.G1.avr.vf] ≈ OM_TUTORIAL_12_T0.vf atol = 1e-6
        @test integ[sys.G1.machine.vf0] ≈ OM_TUTORIAL_12_T0.vf atol = 1e-6
        has_pss && @test integ[sys.G1.pss.vs] ≈ 0 atol = 1e-9
        @test integ[sys.G1.avr.vs] ≈ 0 atol = 1e-9   # pss_off in Example_1, the stabilizer at rest in Example_2
    end
end
