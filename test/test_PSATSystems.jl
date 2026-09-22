# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Examples.PSATSystems.{TwoArea.FourthOrder_AVRII, ThreeArea.SixthOrder_AVRIII} (PLAN-06, phase 6): the two
# three-level `extend` chains (BaseNetwork -> BaseOrder4/6 -> the system with its exciters) compile and their initial
# point is OpenModelica's row 0 of om_psat_{two,three}_area_*.csv to machine precision
# (1.7e-13), which is what a *consistent* power flow looks like: both systems are load-free networks of
# zero-resistance branches where one machine supplies exactly what the other absorbs, so nothing has to be
# distributed over free start values (contrast F-57's IEEE9, whose data are inconsistent at 3e-4).
# PLAN-06's "riesgo principal" for these two - a collapsed-voltage root in a network with no resistance and no load
# (F-31, F-52) - did not materialise: `INIT`'s exact Newton lands on the operating point from baseMachine's guesses.
const OM_PSAT_TWOAREA_T0 = (;
    v = [1.050000000000001, 1.081000000000003, 1.062667304459463, 1.053578452483393, 1.074275673281291,
        1.050663631973298, 1.051353345398545, 1.052069088980458, 1.052810809629965, 1.054371960922222,
        1.055191276593353, 1.056036339429908, 1.056907087672516, 1.057803457891091, 1.058725385007069,
        1.0596728023161, 1.060645641511158, 1.061643832706075, 1.063715983799017, 1.064789796246165,
        1.06588866584107, 1.06701251516795, 1.068161265380693, 1.069334836228766, 1.070533146083384,
        1.071756111963933, 1.07300364956461, 1.075572096238573, 1.076892830317008, 1.07823778618048,
        1.079606873303732],
    order3_delta = -0.1710811873547725, order4_delta = 0.340396826605504, vf = 1.045301276070898)
const OM_PSAT_THREEAREA_T0 = (;
    v = [1.050000000000002, 1.015057429355699, 0.9896624083848823, 0.970235752948435, 0.9728643632181566,
        1.003902495371693, 1.016766021446794, 1.050000000000001, 0.9739199389663503, 1.012743708384428,
        1.030228949679639, 1.050000000000001, 0.9785098870784329, 0.9925226981354475],
    order2_delta = -0.02985175807862597, order3_2_delta = 0.8374360492372837, Syn2_delta = 0.9033148315407364,
    Exc1_vf = 1.09185376598082, Exc2_vf = 1.095878696492499)

@testset "Examples.PSATSystems.TwoArea.FourthOrder_AVRII" begin
    @named sys0 = TwoArea_FourthOrder_AVRII()
    sys = mtkcompile(sys0)
    integ = init(ODEProblem(sys, [], (0.0, 20.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
    for k in 1:31
        @test integ[getproperty(sys, Symbol("B", k)).v] ≈ OM_PSAT_TWOAREA_T0.v[k] atol = 1e-9
    end
    @test integ[sys.order3.delta] ≈ OM_PSAT_TWOAREA_T0.order3_delta atol = 1e-9
    @test integ[sys.order4.delta] ≈ OM_PSAT_TWOAREA_T0.order4_delta atol = 1e-9
    @test integ[sys.order3.w] ≈ 1 atol = 1e-9
    @test integ[sys.order4.w] ≈ 1 atol = 1e-9
    @test integ[sys.aVRTypeII.vf] ≈ OM_PSAT_TWOAREA_T0.vf atol = 1e-9
    @test integ[sys.aVRTypeII.vf] ≈ integ.ps[sys.order4.vf00] atol = 1e-9
    @test integ[sys.order3.vf] ≈ integ.ps[sys.order3.vf00] atol = 1e-9   # vf <- vf0 in the base
end

@testset "Examples.PSATSystems.ThreeArea.SixthOrder_AVRIII" begin
    @named sys0 = ThreeArea_SixthOrder_AVRIII()
    sys = mtkcompile(sys0)
    integ = init(ODEProblem(sys, [], (0.0, 20.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
    for k in 1:14
        @test integ[getproperty(sys, Symbol("B", 100k)).v] ≈ OM_PSAT_THREEAREA_T0.v[k] atol = 1e-9
    end
    @test integ[sys.order2.delta] ≈ OM_PSAT_THREEAREA_T0.order2_delta atol = 1e-9
    @test integ[sys.order3_2.delta] ≈ OM_PSAT_THREEAREA_T0.order3_2_delta atol = 1e-9
    @test integ[sys.Syn2.delta] ≈ OM_PSAT_THREEAREA_T0.Syn2_delta atol = 1e-9
    for m in (sys.order2, sys.order3_2, sys.Syn2)
        @test integ[m.w] ≈ 1 atol = 1e-9
    end
    @test integ[sys.Exc1.vf] ≈ OM_PSAT_THREEAREA_T0.Exc1_vf atol = 1e-9
    @test integ[sys.Exc2.vf] ≈ OM_PSAT_THREEAREA_T0.Exc2_vf atol = 1e-9
    @test integ[sys.Exc1.vf] ≈ integ.ps[sys.Syn2.vf00] atol = 1e-9
    @test integ[sys.Exc2.vf] ≈ integ.ps[sys.order3_2.vf00] atol = 1e-9
    @test integ[sys.Exc1.vs] ≈ 0 atol = 1e-12    # vs_1, vs_2 ground both stabilizer inputs
    @test integ[sys.Exc2.vs] ≈ 0 atol = 1e-12
end
