# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Examples.TwoAreas (PLAN-04, phase 6): the two systems compile and their initial point is OpenModelica's row 0 of
# the reference runs (om_two_areas_psse{,_avr}.csv, DASSL tol 1e-6): the eleven bus
# voltages and the four rotor angles to 1e-6, every machine at synchronous speed, and in the AVR case every exciter at
# EFD = EFD0 of its machine. The PF2 record is not the reference: OpenModelica's own row 0 differs from V5..V11 by up to
# 1.4e-3 pu (the record's load-bus voltages are rounded), and MTK reproduces OpenModelica, not the record.
const OM_TWO_AREAS_T0 = Dict(
    "Two_Areas_PSSE" => (
        v = [1.02999316207, 1.00999085076, 1.02998161519, 1.00997722032, 1.00644205047, 0.978113649931,
            0.960997024671, 0.948584389052, 0.971332389437, 0.983429781546, 1.00822876685],
        delta = [1.10604907, 0.917273446, 0.653062823, 0.458717061]),
    "Two_Areas_PSSE_AVR" => (
        v = [1.02999796138, 1.00999652134, 1.02999224488, 1.00998876819, 1.0064473986, 0.97811979444,
            0.961003733093, 0.948593755647, 0.971344113134, 0.983441458931, 1.00823991409],
        delta = [0.99502724, 0.816842779, 0.541099876, 0.359041586]),
)
@testset "Examples.TwoAreas" begin
    for (label, ctor) in (("Two_Areas_PSSE", Two_Areas_PSSE), ("Two_Areas_PSSE_AVR", Two_Areas_PSSE_AVR))
        @testset "$label" begin
            om = OM_TWO_AREAS_T0[label]
            @named sys0 = ctor()
            sys = mtkcompile(sys0)
            prob = ODEProblem(sys, [], (0.0, 1.0))
            integ = init(prob, Rodas5P(); initializealg = INIT)
            for k in 1:11
                bus = getproperty(sys, Symbol("bus", k))
                @test integ[bus.v] ≈ om.v[k] atol = 1e-6
            end
            for k in 1:4
                g = getproperty(sys, Symbol("g", k))
                mach = label == "Two_Areas_PSSE" ? g.gENSAL : (k == 4 ? g.gENSAL : getproperty(g, Symbol("g", k)))
                @test integ[mach.delta] ≈ om.delta[k] atol = 1e-6
                @test integ[mach.w] ≈ 0 atol = 1e-9
                if label == "Two_Areas_PSSE_AVR"
                    exc = k in (1, 3) ? g.sEXS : g.eSDC1A
                    @test integ[exc.EFD] ≈ integ[mach.EFD0] atol = 1e-9
                end
            end
        end
    end
end

# Two_Areas_PSAT (PLAN-06, phase 6): the same network with four 900 MVA Order6 machines and no controls. Its initial
# point is OpenModelica's row 0 of om_two_areas_psat.csv, to 1e-5: OpenModelica's
# initialization is under-determined (F-28) and it fixes `g1..g4.order6_1.w`, `g1/g2.order6_1.delta` and
# `g1/g2.order6_1.e1d` (probe with -d=initialization, 2026-09-16), while baseMachine fixes all four `delta` and `w`
# and Order6's own `initial equation der(e1d) = der(e2d) = 0` closes the rest. The power flow of PF1 is consistent to
# ~5e-6, so the two squarings differ by 5.3e-6 rad in `g3.delta` and 6.8e-7 pu in the bus voltages, which the case's
# thresholds absorb by two orders of magnitude (its worst trajectory error is 3.2e-4 rad).
const OM_TWO_AREAS_PSAT_T0 = (;
    v = [1.03000000981, 1.01000001314, 1.02999985522, 1.0099994768, 1.00686873668, 0.979142056748,
        0.96283101311, 0.948276813462, 0.973864276872, 0.98485706001, 1.00882904177],
    delta = [1.10736786544, 0.920968612734, 0.655386404139, 0.464740080613])

@testset "Examples.TwoAreas.Two_Areas_PSAT" begin
    @named sys0 = Two_Areas_PSAT()
    sys = mtkcompile(sys0)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    for k in 1:11
        @test integ[getproperty(sys, Symbol("bus", k)).v] ≈ OM_TWO_AREAS_PSAT_T0.v[k] atol = 1e-5
    end
    for k in 1:4
        m = getproperty(sys, Symbol("g", k)).order6_1
        @test integ[m.delta] ≈ OM_TWO_AREAS_PSAT_T0.delta[k] atol = 1e-5
        @test integ[m.w] ≈ 1 atol = 1e-9
        @test integ[m.vf] ≈ integ.ps[m.vf00] atol = 1e-9   # vf <- vf0 = vf00, no exciter
    end
end
