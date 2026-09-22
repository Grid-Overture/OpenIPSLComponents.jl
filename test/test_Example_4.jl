# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Examples.Tutorial.Example_4 (PLAN-05, phase 7): the two experiments compile and their initial point is
# OpenModelica's row 0 of `om_example_4_smib.csv` (DASSL tol 1e-6): the four bus
# voltages and the rotor angle to 1e-6, the machine at synchronous speed, the exciter at the machine's EFD0 and the
# governor at its `P0 = 0.4`.
# `SMIBVarLoad` is checked against the *same* row: it is the same network with the same power flow and the same
# machine, and at t = 0 the PSS2A output is zero (all its paths are washouts), so its operating point is `SMIB`'s.
# OpenModelica 1.25 cannot initialize `SMIBVarLoad` itself (F-52), so this is the OpenModelica anchor the case has.
# The rest of the check is intrinsic: nothing *acts* in [0, 10] s (the load ramp starts at t1 = 10 s and the fault at
# 101 s), so the system stays at its operating point. It is not an exact equilibrium - the power-flow data of
# Example_4 are slightly inconsistent and OpenModelica's own SMIB run drifts by 1.5e-2 rad of rotor angle in the
# first second with no disturbance at all - so what is checked is that the bus voltages stay within 1e-2 pu of their
# initial value and the stabilizer output within its own limit.
const OM_EXAMPLE_4_T0 = (; v = [1.000112058174111, 1.000210374488758, 0.9920778390125496, 0.9961323389784751],
    delta = 0.6004577994897584, EFD = 1.431419708901237, PMECH = 0.4)

@testset "Examples.Tutorial.Example_4" begin
    for (label, ctor) in (("SMIB", Example_4_SMIB), ("SMIBVarLoad", Example_4_SMIBVarLoad))
        @testset "$label" begin
            @named sys0 = ctor()
            sys = mtkcompile(sys0)
            prob = ODEProblem(sys, [], (0.0, 10.0))
            integ = init(prob, Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
            for (k, bus) in enumerate((sys.B01, sys.B02, sys.B03, sys.B04))
                @test integ[bus.v] ≈ OM_EXAMPLE_4_T0.v[k] atol = 1e-6
            end
            @test integ[sys.genunit.gENROE.delta] ≈ OM_EXAMPLE_4_T0.delta atol = 1e-6
            @test integ[sys.genunit.gENROE.w] ≈ 0 atol = 1e-9
            @test integ[sys.genunit.eSST1A1.EFD] ≈ OM_EXAMPLE_4_T0.EFD atol = 1e-6
            @test integ[sys.genunit.eSST1A1.EFD] ≈ integ[sys.genunit.gENROE.EFD0] atol = 1e-9
            @test integ[sys.genunit.iEEEG1_1.PMECH_HP] ≈ OM_EXAMPLE_4_T0.PMECH atol = 1e-9
            if label == "SMIBVarLoad"
                @test integ[sys.genunit.pSS2A.VOTHSG] ≈ 0 atol = 1e-9
                sol = solve(prob, Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
                @test sol.retcode == ReturnCode.Success
                for (k, bus) in enumerate((sys.B01, sys.B02, sys.B03, sys.B04))
                    vs = [sol(tk; idxs = bus.v) for tk in 0:0.1:10]
                    @test maximum(abs.(vs .- OM_EXAMPLE_4_T0.v[k])) < 1e-2
                end
                vst = [sol(tk; idxs = sys.genunit.pSS2A.VOTHSG) for tk in 0:0.1:10]
                @test maximum(abs.(vst)) <= 0.1 + 1e-12
            end
        end
    end
end
