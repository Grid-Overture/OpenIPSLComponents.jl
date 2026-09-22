# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Examples.IEEE9.IEEE_9_Buses_Statcom (PLAN-06, phase 6): the system compiles and its initial point is
# OpenModelica's row 0 of om_ieee9_statcom.csv to 3.1e-4 in the bus voltages and to
# machine precision in the three rotor angles and the three field voltages.
# The 3.1e-4 is not a translation error but the two tools squaring an under-determined initialization differently on
# power-flow data that are self-consistent only to ~3e-4 pu: OpenModelica drops `der(e1q) = 0` and `der(vm) = 0` for
# gen1 and pins that machine and the STATCOM exactly on their declared values, ModelingToolkit keeps both and fixes
# `e1d` (F-11), which spreads the mismatch over the nine buses. Measured and justified in F-57; `delta`, `w` and
# `AVR.vf` are unaffected because they are fixed conditions or follow from `vf00`.
const OM_IEEE9_STATCOM_T0 = (;
    v = [1.03997449982, 1.025, 1.02482672586, 1.02574838235, 0.995600930868, 1.01259038973, 1.025769375,
        1.01589591852, 1.03225666981],
    delta = [1.06636899134, 0.94486307005, 0.0625826201216],
    vf = [1.78932331433, 1.40299430441, 1.08214804627],
    Q_statcom = 0.00128731872134)

@testset "Examples.IEEE9.IEEE_9_Buses_Statcom" begin
    @named sys0 = IEEE_9_Buses_Statcom()
    sys = mtkcompile(sys0)
    integ = init(ODEProblem(sys, [], (0.0, 20.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
    for k in 1:9
        @test integ[getproperty(sys, Symbol("B", k)).v] ≈ OM_IEEE9_STATCOM_T0.v[k] atol = 3.1e-4
    end
    for k in 1:3
        g = getproperty(sys, Symbol("gen", k))
        @test integ[g.gen.delta] ≈ OM_IEEE9_STATCOM_T0.delta[k] atol = 1e-9
        @test integ[g.gen.w] ≈ 1 atol = 1e-9
        @test integ[g.AVR.vf] ≈ OM_IEEE9_STATCOM_T0.vf[k] atol = 1e-9
        @test integ[g.AVR.vf] ≈ integ.ps[g.gen.vf00] atol = 1e-9     # the exciter starts at the machine's vf00
        @test integ[g.AVR.vref] ≈ integ[g.AVR.vref0] atol = 1e-12    # refdisturb = false: the step never reaches vref
    end
    # the STATCOM rests at its power-flow injection, its limiter well inside [-0.8, 1.2]
    @test integ[sys.sTATCOM3_1.Q] ≈ OM_IEEE9_STATCOM_T0.Q_statcom atol = 1e-6
    @test integ[sys.sTATCOM3_1.i_SH] ≈ integ.ps[sys.sTATCOM3_1.i0] atol = 1e-6
    @test integ[sys.sTATCOM3_1.v_POD] ≈ 0 atol = 1e-12
end
