# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Examples.KundurSMIB.{SMIB, SMIB_AVR, SMIB_AVR_PSS} (PLAN-06, phase 6): the three systems compile and their initial
# point is OpenModelica's row 0 of om_kundur_smib{,_avr,_avr_pss}.csv (DASSL, tol 1e-6,
# default solver). The three bus voltages, the rotor angle and speed of the Order6 machine, the AVRtypeIII field
# voltage in the two variants that have one and the PSSTypeII output in the third.
# OpenModelica's initialization of `SMIB` fixes `G1.machine.w` and `G1.machine.delta` and nothing else (probe with
# -d=initialization, 2026-09-16), which is what baseMachine carries as `initial_conditions` (F-11), so no `u0` hook
# is needed; the AVR variants declare `machine(delta(fixed = true))`, `w(fixed = true)` and are fully determined.
const OM_KUNDUR_T0 = (; B1 = 0.999999999998, B2 = 0.944299492909, B3 = 0.90081,
    delta = 1.22424746441, vf = 2.42070164208)

@testset "Examples.KundurSMIB" begin
    for (ctor, has_avr, has_pss) in ((KundurSMIB_SMIB, false, false), (KundurSMIB_SMIB_AVR, true, false),
            (KundurSMIB_SMIB_AVR_PSS, true, true))
        @named sys0 = ctor()
        sys = mtkcompile(sys0)
        integ = init(ODEProblem(sys, [], (0.0, 10.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
        @test integ[sys.B1.v] ≈ OM_KUNDUR_T0.B1 atol = 1e-6
        @test integ[sys.B2.v] ≈ OM_KUNDUR_T0.B2 atol = 1e-6
        @test integ[sys.B3.v] ≈ OM_KUNDUR_T0.B3 atol = 1e-6
        @test integ[sys.G1.machine.delta] ≈ OM_KUNDUR_T0.delta atol = 1e-6
        @test integ[sys.G1.machine.w] ≈ 1 atol = 1e-9
        # Taa = 0 in this group, so vf0 = V_MBtoSB*(K1*id0 + e1q0) with no Taa/T1d0 correction
        @test integ[sys.G1.machine.vf0] ≈ OM_KUNDUR_T0.vf atol = 1e-6
        has_avr && @test integ[sys.G1.avr.vf] ≈ OM_KUNDUR_T0.vf atol = 1e-6
        has_pss && @test integ[sys.G1.pss.vs] ≈ 0 atol = 1e-9
        has_pss && @test integ[sys.G1.avr.vs] ≈ 0 atol = 1e-9
    end
end
