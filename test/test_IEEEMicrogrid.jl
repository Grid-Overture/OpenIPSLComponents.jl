# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Examples.Microgrids.IEEEMicrogrid (PLAN-07, batch 7).
# **This case has no OpenModelica reference** (F-63: OM cannot initialize it) and **cannot be simulated to its
# 20 s horizon** (F-65: the two ideal switches chatter, median step 5e-10 s). What is validated here is therefore
# the operating point and the first instants, which is what the case can still say about the models it assembles.
#
# What the numbers below mean:
#  * the `.mo`'s `PF_results` record is **not** this case's `t = 0`. The two `CIM5` motors are started with
#    `Sup = true`, whose own `initial equation` fixes the slip at `1 - eps`, i.e. standstill, while the record
#    describes the microgrid with them running. All eight bus voltages therefore sit about 2% *above* the record,
#    uniformly (0.0202 to 0.0221 pu), because at standstill the motors draw far less than their rated power.
#    The test checks that uniformity -- the eight buses within 0.3% of each other and all within 3% of the record --
#    rather than equality with the record, which would be wrong.
#  * the initialization is under-determined by two (the free `Inductor.i` of each converter, `fixed = false` in the
#    `.mo`): the two identical VSD chains come out with different link currents (0.2136 and 0.4147), which is the
#    signature of that freedom and is why no `u0` is supplied -- supplying one over-determines the system and the
#    initialization returns `InitialFailure` (F-65).
@testset "Examples.Microgrids.IEEEMicrogrid" begin
    @named mg = IEEEMicrogrid(; mods = (; Diesel = (; dEGOV = (; pade = 8))))
    sys = mtkcompile(mg)
    @test length(unknowns(sys)) == 95
    integ = init(ODEProblem(sys, [], (0.0, 20.0)), Rodas5P(); initializealg = INIT)
    @test integ.sol.retcode != ReturnCode.InitialFailure
    R = IEEEMicrogrid_PF_results

    # the two motors are at standstill, which is CIM5(Sup = true)'s own initial equation
    @test integ[sys.Motor1.s] ≈ 1.0 atol = 1e-12
    @test integ[sys.Motor2.s] ≈ 1.0 atol = 1e-12
    # and they are accelerating: the slip falls from the first instant
    @test initial_derivative(integ, sys, sys.Motor1.s) < 0.0
    @test initial_derivative(integ, sys, sys.Motor2.s) < 0.0
    # F-35 does not bite: the initialization finds a non-zero flux by itself, so the 1e-3 escape is not needed
    @test abs(integ[sys.Motor1.Epr]) > 1e-3
    @test abs(integ[sys.Motor2.Epr]) > 1e-3

    # the eight buses: a tightly coupled 400 V microgrid, so they are within 0.3% of each other, and the whole
    # network sits ~2% above the record for the reason in the header
    vs = [integ[getproperty(sys, b).v] for b in (:Bus1, :Bus2, :Bus3, :Bus4, :Bus5, :Bus6, :Bus7, :BusGrid)]
    @test maximum(vs) - minimum(vs) < 3e-3
    for v in vs
        @test 0.0 < v - R.voltages.V1 < 3e-2
    end

    # the diesel unit delivers the record's power to within 7% (the same standstill offset)
    @test integ[sys.Diesel.P] ≈ R.machines.PDT rtol = 0.07
    @test integ[sys.Diesel.Q] ≈ R.machines.QDT rtol = 0.07
    # the two inverter interfaces inject the record's power on their own bases, to within 3%
    @test integ[sys.PV.RenewableGenerator.Pgen] ≈ R.machines.PPV / 80e3 rtol = 0.03
    @test integ[sys.BESS.RenewableGenerator.Pgen] ≈ R.machines.PBESS / 50e3 rtol = 0.03

    # the two DC links start at Vc0 = 2*sqrt(2)*(3*sqrt(3)/(2*pi))*V_b with V_b = 400, both switches closed
    vc0 = 2 * sqrt(2) * (3 * sqrt(3) / (2 * pi)) * 400.0
    @test integ[sys.aC2DCandDC2AC.Capacitor.v] ≈ vc0 rtol = 1e-3
    @test integ[sys.aC2DCandDC2AC1.Capacitor.v] ≈ vc0 rtol = 1e-3
    @test integ[sys.aC2DCandDC2AC.switch.off] ≈ 0.0 atol = 1e-12
    @test integ[sys.aC2DCandDC2AC1.switch.off] ≈ 0.0 atol = 1e-12
    # the V/Hz controllers start at m0 and the speed ramp starts at 0.1*1.9*pi*fn
    @test integ[sys.voltsHertzController.m] ≈ 0.095 atol = 1e-9
    @test integ[sys.voltsHertzController1.m] ≈ 0.095 atol = 1e-9
    @test integ[sys.Sync_Speed.y] ≈ 0.1 * 1.9 * pi * 60 atol = 1e-9
    # the two identical VSD chains come out with different link currents: the two free `Inductor.i` (see the header)
    @test integ[sys.aC2DCandDC2AC.Inductor.i] != integ[sys.aC2DCandDC2AC1.Inductor.i]
end
