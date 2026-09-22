# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Examples.IEEE14.IEEE_14_Buses (PLAN-06, phase 6): the largest system of the batch (87 unknowns after mtkcompile).
# It compiles and its initial point is OpenModelica's row 0 of om_ieee14.csv to 3.2e-5
# in the fourteen bus voltages and to machine precision in the five rotor angles and the five field voltages.
# Two `u0` entries are needed (F-28), both verified against OpenModelica's own `-d=initialization` report:
#  * `gen1.Syn1.e1q`: `Order5_Type2.mo` comments out its `initial equation der(e1q) = 0`, so without this the
#    initialization is one equation short and ModelingToolkit's least-squares fallback lands 2.5e-2 pu away;
#  * `gen1/gen6/gen8`'s `delta`: OpenModelica leaves those three free (it assumes only their `w`) while baseMachine
#    pins all five at `delta0`, and for the two synchronous condensers (P_0 ~ 0, so the rotor angle is set by the
#    reactive flow alone) `delta0` is 8e-3 rad away from the point the network gives.
const OM_IEEE14_T0 = (;
    v = [1.06001808828, 1.045, 1.01, 0.997818583704, 1.00287710425, 1.06988272554, 1.03605286088, 1.09001804288,
        1.01295935266, 1.01222157701, 1.0356205685, 1.04604289897, 1.03651084285, 0.996950837868],
    delta = (Syn1 = 0.31849946489, Syn3 = 0.0973536303348, Syn2 = -0.34118403424, Syn5 = -0.387173353905,
        Syn4 = -0.340795660016),
    vf = (AVR1 = 1.12265597982, aVR1TypeII1 = 2.71813089407, aVR2TypeII2 = 2.04503025058,
        aVR4TypeII1 = 3.14631110693, aVR3TypeII2 = 2.6222158242))

@testset "Examples.IEEE14.IEEE_14_Buses" begin
    @named sys0 = IEEE_14_Buses()
    sys = mtkcompile(sys0)
    u0 = [sys.gen1.Syn1.e1q => sys.gen1.Syn1.e1q0,
        sys.gen1.Syn1.delta => OM_IEEE14_T0.delta.Syn1,
        sys.gen6.Syn5.delta => OM_IEEE14_T0.delta.Syn5,
        sys.gen8.Syn4.delta => OM_IEEE14_T0.delta.Syn4]
    integ = init(ODEProblem(sys, u0, (0.0, 10.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
    for k in 1:14
        @test integ[getproperty(sys, Symbol("B", k)).v] ≈ OM_IEEE14_T0.v[k] atol = 3.2e-5
    end
    for (g, m, e) in (("gen1", :Syn1, :AVR1), ("gen2", :Syn3, :aVR1TypeII1), ("gen3", :Syn2, :aVR2TypeII2),
            ("gen6", :Syn5, :aVR4TypeII1), ("gen8", :Syn4, :aVR3TypeII2))
        grp = getproperty(sys, Symbol(g))
        mach, exc = getproperty(grp, m), getproperty(grp, e)
        @test integ[mach.delta] ≈ getproperty(OM_IEEE14_T0.delta, m) atol = 1e-9
        @test integ[mach.w] ≈ 1 atol = 1e-9
        @test integ[exc.vf] ≈ getproperty(OM_IEEE14_T0.vf, e) atol = 1e-9
        @test integ[exc.vf] ≈ integ.ps[mach.vf00] atol = 1e-9     # the exciter starts at the machine's vf00
        @test integ[exc.vref] ≈ integ[exc.vref0] atol = 1e-12     # vref0 -> vref: the exciter holds its own reference
    end
    # without the e1q condition the initialization is one equation short (the .mo's commented-out initial equation)
    @test_throws Exception ODEProblem(sys, u0[2:end], (0.0, 10.0); fully_determined = true)
end
