# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Examples.SevenBus.Network (PLAN-05, phase 7): the system compiles and its initial point is OpenModelica's row 0 of
# `om_seven_bus.csv` (DASSL tol 1e-6, dense nonlinear solver, F-43): the seven external
# bus voltages and the three internal ones to 1e-6, the rotor angles of the three GENROU to 1e-6, every machine at
# synchronous speed, every ST5B at the machine's EFD0 and every PSS2B at zero output.
const OM_SEVEN_BUS_T0 = (;
    ext = (; FPAND = 1.069547577264965, FSBIS = 1.069537144609174, FSSV = 1.069557041568099,
        FTDPRA = 1.069543718146068, FTILL = 1.069531789657139, FVALDI = 1.069557145506208,
        FVERGE = 1.069556866321562),
    int = [0.9898605135968018, 1.005908594031465, 0.9802610361565969],
    delta = [1.141078937426038, 0.6482247553697128, -3.416806859540631e-05],
    EFD = [2.661359728861061, 1.385554282005325, 1.16867249822097],
    PMECH = [0.8954227905813594, 0.2812083738825473, 9.827191078861486e-08])

@testset "Examples.SevenBus" begin
    @named sys0 = SevenBus_Network()
    sys = mtkcompile(sys0)
    prob = ODEProblem(sys, [], (0.0, 10.0))
    integ = init(prob, Rodas5P(); abstol = 1e-9, reltol = 1e-9, initializealg = INIT)
    for (nm, v) in pairs(OM_SEVEN_BUS_T0.ext)
        @test integ[getproperty(sys, nm).v] ≈ v atol = 1e-6
    end
    for k in 1:3
        @test integ[getproperty(sys, Symbol("internal_bus_gen", k)).v] ≈ OM_SEVEN_BUS_T0.int[k] atol = 1e-6
        g = getproperty(sys, Symbol("GEN", k))
        @test integ[g.gENROU.delta] ≈ OM_SEVEN_BUS_T0.delta[k] atol = 1e-6
        @test integ[g.gENROU.w] ≈ 0 atol = 1e-9
        @test integ[g.sT5B.EFD] ≈ OM_SEVEN_BUS_T0.EFD[k] atol = 1e-6
        @test integ[g.sT5B.EFD] ≈ integ[g.gENROU.EFD0] atol = 1e-9
        @test integ[g.iEESGO.PMECH] ≈ OM_SEVEN_BUS_T0.PMECH[k] atol = 1e-6
        @test integ[g.pSS2B.VOTHSG] ≈ 0 atol = 1e-9
    end
end
