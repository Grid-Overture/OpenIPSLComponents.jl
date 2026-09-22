# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Examples.N44.Base_Case (PLAN-10, phase 2): the Nordic 44 base case, the scale case of the port (F-87). No class
# of the batch has an upstream Test, so the eighteen generator classes are exercised by this file and by the
# validation case in this port (rule 6).
# Part 1: one instance of each of the five families on an ideal source at its power-flow voltage compiles and sits
# at the operating point the record gives it -- P and Q at the pin are `PF_results.machines.P<bus>_1`/`Q<bus>_1`
# over S_b = 1000 MVA, the machine is at synchronous speed and the governor delivers the mechanical power.
# The injected power at a `PwPin` is `-(vr*ir + vi*ii)` and `-(vi*ir - vr*ii)`: the pin current flows into the
# component.
# Part 2: the whole system at t = 0 against OpenModelica's row 0 of `om_n44.csv`
# (DASSL tol 1e-6, `--daeMode --tearingMethod=noTearing`, F-85) -- the 44 bus voltages, the rotor angle and speed
# of the 80 machines, the 80 field voltages, the 80 mechanical powers and the 53 stabilizer outputs, 417 values to
# 1e-6. Building it costs a few minutes: it is the largest system the package has (1595 unknowns).

# (class, machine, exciter, governor, pin, bus) of one unit per family; the record supplies V/A and P/Q of unit 1.
# The pin is `pwPin` in the two GENROU families and `p` in the three GENSAL ones, as the .mo names it.
const N44_FAMILIES = [
    (Gen1_bus_3000, :gENROU, :iEEET2, :iEESGO, :pwPin, "3000"),
    (Gen2_bus_3245, :gENSAL, :sCRX, :hYGOV, :p, "3245"),
    (Gen3_bus_3115, :gENSAL, :sCRX, :hYGOV, :p, "3115"),
    (Gen4_bus_3300, :gENROU, :sCRX, :iEESGO, :pwPin, "3300"),
    (Gen5_bus_6500, :gENSAL, :sEXS, :hYGOV, :p, "6500"),
]

@testset "Examples.N44 generator families" begin
    V, M = N44_PF_results.voltages, N44_PF_results.machines
    for (ctor, mach, exc, gov, pinname, bus) in N44_FAMILIES
        v0 = getproperty(V, Symbol("V", bus))
        a0 = getproperty(V, Symbol("A", bus))
        P0 = getproperty(M, Symbol("P", bus, "_1"))
        Q0 = getproperty(M, Symbol("Q", bus, "_1"))
        @named g = ctor(; V_b = 420e3, v_0 = v0, angle_0 = a0, P_0 = P0, Q_0 = Q0, S_b = 1000e6, fn = 50)
        @named src = FixedVoltageSource(; vr = v0 * cos(a0), vi = v0 * sin(a0))
        pin = getproperty(g, pinname)
        @named rig = System([connect(pin, src.p)], t, [], []; systems = [g, src])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
        p = getproperty(sys.g, pinname)
        @test integ[-(p.vr * p.ir + p.vi * p.ii)] ≈ P0 / 1000e6 atol = 1e-9
        @test integ[-(p.vi * p.ir - p.vr * p.ii)] ≈ Q0 / 1000e6 atol = 1e-9
        @test integ[getproperty(sys.g, mach).w] ≈ 0 atol = 1e-12
        @test integ[getproperty(sys.g, gov).PMECH] ≈ integ[getproperty(sys.g, mach).PMECH0] atol = 1e-9
        @test integ[getproperty(sys.g, exc).EFD] ≈ integ[getproperty(sys.g, mach).EFD0] atol = 1e-9
    end
end

const OM_N44_T0 = [
    "G1_bus3000.gENROU.delta" => 0.3580498623570956, "G1_bus3000.gENROU.w" => 0.0,
    "G1_bus3115.gENSAL.delta" => 0.2835771988164482, "G1_bus3115.gENSAL.w" => 0.0,
    "G1_bus3245.gENSAL.delta" => 0.03146518921992925, "G1_bus3245.gENSAL.w" => 0.0,
    "G1_bus3249.gENSAL.delta" => 0.397461945117729, "G1_bus3249.gENSAL.w" => 0.0,
    "G1_bus3300.gENROU.delta" => 0.8453867149416439, "G1_bus3300.gENROU.w" => 0.0,
    "G1_bus3359.gENROU.delta" => 0.5854051266348724, "G1_bus3359.gENROU.w" => 0.0,
    "G1_bus5100.gENSAL.delta" => 0.35715023788161, "G1_bus5100.gENSAL.w" => 0.0,
    "G1_bus5300.gENSAL.delta" => 1.179743132558845, "G1_bus5300.gENSAL.w" => 0.0,
    "G1_bus5400.gENSAL.delta" => 0.5055618869190793, "G1_bus5400.gENSAL.w" => 0.0,
    "G1_bus5500.gENSAL.delta" => 0.3708041509641907, "G1_bus5500.gENSAL.w" => 0.0,
    "G1_bus5600.gENSAL.delta" => 0.2910971601136731, "G1_bus5600.gENSAL.w" => 0.0,
    "G1_bus6000.gENSAL.delta" => 0.9446429944217494, "G1_bus6000.gENSAL.w" => 0.0,
    "G1_bus6100.gENSAL.delta" => 1.223204642109407, "G1_bus6100.gENSAL.w" => 0.0,
    "G1_bus6500.gENSAL.delta" => -0.1669197842226958, "G1_bus6500.gENSAL.w" => 0.0,
    "G1_bus6700.gENSAL.delta" => 0.2074650836843509, "G1_bus6700.gENSAL.w" => 0.0,
    "G1_bus7000.gENROU.delta" => 0.9794954257455399, "G1_bus7000.gENROU.w" => 0.0,
    "G1_bus7100.gENSAL.delta" => 0.3285874790925102, "G1_bus7100.gENSAL.w" => 0.0,
    "G1_bus8500.gENROU.delta" => 0.1153053681682867, "G1_bus8500.gENROU.w" => 0.0,
    "G2_add_bus5100.gENSAL.delta" => 0.35715023788161, "G2_add_bus5100.gENSAL.w" => 0.0,
    "G2_add_bus5500.gENSAL.delta" => 0.3708041509641907, "G2_add_bus5500.gENSAL.w" => 0.0,
    "G2_add_bus6000.gENSAL.delta" => 0.9446429944217494, "G2_add_bus6000.gENSAL.w" => 0.0,
    "G2_bus3000.gENROU.delta" => 0.3580498623570956, "G2_bus3000.gENROU.w" => 0.0,
    "G2_bus3115.gENSAL.delta" => 0.2835771988164482, "G2_bus3115.gENSAL.w" => 0.0,
    "G2_bus3249.gENSAL.delta" => 0.397461945117729, "G2_bus3249.gENSAL.w" => 0.0,
    "G2_bus3300.gENROU.delta" => 0.8453867149416439, "G2_bus3300.gENROU.w" => 0.0,
    "G2_bus3359.gENROU.delta" => 0.5854051266348724, "G2_bus3359.gENROU.w" => 0.0,
    "G2_bus5300.gENSAL.delta" => 1.179743132558845, "G2_bus5300.gENSAL.w" => 0.0,
    "G2_bus5400.gENSAL.delta" => 0.5055618869190793, "G2_bus5400.gENSAL.w" => 0.0,
    "G2_bus5600.gENSAL.delta" => 0.2910971601136731, "G2_bus5600.gENSAL.w" => 0.0,
    "G2_bus6100.gENSAL.delta" => 1.223204642109407, "G2_bus6100.gENSAL.w" => 0.0,
    "G2_bus6500.gENSAL.delta" => -0.1669197842226958, "G2_bus6500.gENSAL.w" => 0.0,
    "G2_bus6700.gENSAL.delta" => 0.2074650836843509, "G2_bus6700.gENSAL.w" => 0.0,
    "G2_bus7000.gENROU.delta" => 0.9794954257455399, "G2_bus7000.gENROU.w" => 0.0,
    "G2_bus7100.gENSAL.delta" => 0.3285874790925102, "G2_bus7100.gENSAL.w" => 0.0,
    "G2_bus8500.gENROU.delta" => 0.1153053681682867, "G2_bus8500.gENROU.w" => 0.0,
    "G3_add_bus5300.gENSAL.delta" => 1.179743132558845, "G3_add_bus5300.gENSAL.w" => 0.0,
    "G3_add_bus5600.gENSAL.delta" => 0.2910971601136731, "G3_add_bus5600.gENSAL.w" => 0.0,
    "G3_add_bus6000.gENSAL.delta" => 0.9446429944217494, "G3_add_bus6000.gENSAL.w" => 0.0,
    "G3_add_bus6700.gENSAL.delta" => 0.2074650836843509, "G3_add_bus6700.gENSAL.w" => 0.0,
    "G3_bus3000.gENROU.delta" => 0.3580498623570956, "G3_bus3000.gENROU.w" => 0.0,
    "G3_bus3115.gENSAL.delta" => 0.2835771988164482, "G3_bus3115.gENSAL.w" => 0.0,
    "G3_bus3249.gENSAL.delta" => 0.397461945117729, "G3_bus3249.gENSAL.w" => 0.0,
    "G3_bus3300.gENROU.delta" => 0.8453867149416439, "G3_bus3300.gENROU.w" => 0.0,
    "G3_bus3359.gENROU.delta" => 0.5854051266348724, "G3_bus3359.gENROU.w" => 0.0,
    "G3_bus6100.gENSAL.delta" => 1.223204642109407, "G3_bus6100.gENSAL.w" => 0.0,
    "G3_bus6500.gENSAL.delta" => -0.1669197842226958, "G3_bus6500.gENSAL.w" => 0.0,
    "G3_bus7000.gENROU.delta" => 0.9794954257455399, "G3_bus7000.gENROU.w" => 0.0,
    "G3_bus7100.gENSAL.delta" => 0.3285874790925102, "G3_bus7100.gENSAL.w" => 0.0,
    "G3_bus8500.gENROU.delta" => 0.1153053681682867, "G3_bus8500.gENROU.w" => 0.0,
    "G4_add_bus3115.gENSAL.delta" => 0.2835771988164482, "G4_add_bus3115.gENSAL.w" => 0.0,
    "G4_add_bus3300.gENROU.delta" => 0.8453867149416439, "G4_add_bus3300.gENROU.w" => 0.0,
    "G4_add_bus5300.gENSAL.delta" => 1.179743132558845, "G4_add_bus5300.gENSAL.w" => 0.0,
    "G4_add_bus5600.gENSAL.delta" => 0.2910971601136731, "G4_add_bus5600.gENSAL.w" => 0.0,
    "G4_add_bus6000.gENSAL.delta" => 0.9446429944217494, "G4_add_bus6000.gENSAL.w" => 0.0,
    "G4_add_bus6700.gENSAL.delta" => 0.2074650836843509, "G4_add_bus6700.gENSAL.w" => 0.0,
    "G4_bus3249.gENSAL.delta" => 0.397461945117729, "G4_bus3249.gENSAL.w" => 0.0,
    "G4_bus3359.gENROU.delta" => 0.5854051266348724, "G4_bus3359.gENROU.w" => 0.0,
    "G4_bus6100.gENSAL.delta" => 1.223204642109407, "G4_bus6100.gENSAL.w" => 0.0,
    "G4_bus6500.gENSAL.delta" => -0.1669197842226958, "G4_bus6500.gENSAL.w" => 0.0,
    "G4_bus7000.gENROU.delta" => 0.9794954257455399, "G4_bus7000.gENROU.w" => 0.0,
    "G4_bus8500.gENROU.delta" => 0.1153053681682867, "G4_bus8500.gENROU.w" => 0.0,
    "G5_add_bus3115.gENSAL.delta" => 0.2835771988164482, "G5_add_bus3115.gENSAL.w" => 0.0,
    "G5_add_bus3300.gENROU.delta" => 0.8453867149416439, "G5_add_bus3300.gENROU.w" => 0.0,
    "G5_add_bus5300.gENSAL.delta" => 1.179743132558845, "G5_add_bus5300.gENSAL.w" => 0.0,
    "G5_bus3249.gENSAL.delta" => 0.397461945117729, "G5_bus3249.gENSAL.w" => 0.0,
    "G5_bus3359.gENROU.delta" => 0.5854051266348724, "G5_bus3359.gENROU.w" => 0.0,
    "G5_bus6100.gENSAL.delta" => 1.223204642109407, "G5_bus6100.gENSAL.w" => 0.0,
    "G5_bus7000.gENROU.delta" => 0.9794954257455399, "G5_bus7000.gENROU.w" => 0.0,
    "G5_bus8500.gENROU.delta" => 0.1153053681682867, "G5_bus8500.gENROU.w" => 0.0,
    "G6_add_bus3300.gENROU.delta" => 0.8453867149416439, "G6_add_bus3300.gENROU.w" => 0.0,
    "G6_add_bus5300.gENSAL.delta" => 1.179743132558845, "G6_add_bus5300.gENSAL.w" => 0.0,
    "G6_bus3249.gENSAL.delta" => 0.397461945117729, "G6_bus3249.gENSAL.w" => 0.0,
    "G6_bus3359.gENROU.delta" => 0.5854051266348724, "G6_bus3359.gENROU.w" => 0.0,
    "G6_bus7000.gENROU.delta" => 0.9794954257455399, "G6_bus7000.gENROU.w" => 0.0,
    "G6_bus8500.gENROU.delta" => 0.1153053681682867, "G6_bus8500.gENROU.w" => 0.0,
    "G7_bus3249.gENSAL.delta" => 0.397461945117729, "G7_bus3249.gENSAL.w" => 0.0,
    "G7_bus7000.gENROU.delta" => 0.9794954257455399, "G7_bus7000.gENROU.w" => 0.0,
    "G8_add_bus3249.gENSAL.delta" => 0.397461945117729, "G8_add_bus3249.gENSAL.w" => 0.0,
    "G8_bus7000.gENROU.delta" => 0.9794954257455399, "G8_bus7000.gENROU.w" => 0.0,
    "G9_bus7000.gENROU.delta" => 0.9794954257455399, "G9_bus7000.gENROU.w" => 0.0,
    "G1_bus3000.iEESGO.PMECH" => 0.2855638476923077, "G1_bus3000.sTAB2A.VOTHSG" => 0.0,
    "G1_bus3115.hYGOV.PMECH" => 0.2930991990909119, "G1_bus3115.sCRX.EFD" => 1.065787520421433,
    "G1_bus3115.sTAB2A.VOTHSG" => 6.833903161361044e-37, "G1_bus3245.hYGOV.PMECH" => 0.2108105305263181,
    "G1_bus3245.sCRX.EFD" => 1.090157220868647, "G1_bus3249.hYGOV.PMECH" => 0.3291477774502609,
    "G1_bus3249.sCRX.EFD" => 1.155593802434013, "G1_bus3300.iEESGO.PMECH" => 0.6440440781818182,
    "G1_bus3300.sCRX.EFD" => 1.961072477373684, "G1_bus3300.sTAB2A.VOTHSG" => 0.0,
    "G1_bus3359.iEESGO.PMECH" => 0.5177399814814815, "G1_bus3359.sCRX.EFD" => 1.941196433226657,
    "G1_bus3359.sTAB2A.VOTHSG" => 0.0, "G1_bus5100.hYGOV.PMECH" => 0.2931291708333306,
    "G1_bus5100.sEXS.EFD" => 1.635877658271898, "G1_bus5300.hYGOV.PMECH" => 0.6110854591666618,
    "G1_bus5300.sCRX.EFD" => 1.520119877274811, "G1_bus5300.sTAB2A.VOTHSG" => -7.225445206674838e-46,
    "G1_bus5400.hYGOV.PMECH" => 0.2720342889795891, "G1_bus5400.sEXS.EFD" => 1.371720154712221,
    "G1_bus5500.hYGOV.PMECH" => 0.200873476551722, "G1_bus5500.sEXS.EFD" => 1.076428480518547,
    "G1_bus5600.hYGOV.PMECH" => 0.1582512133333352, "G1_bus5600.sCRX.EFD" => 1.373636236207568,
    "G1_bus6000.hYGOV.PMECH" => 0.6321235205882303, "G1_bus6000.sEXS.EFD" => 1.379309517074801,
    "G1_bus6100.hYGOV.PMECH" => 0.5071136967741894, "G1_bus6100.sCRX.EFD" => 1.404976303503247,
    "G1_bus6100.sTAB2A.VOTHSG" => 0.0, "G1_bus6500.hYGOV.PMECH" => 0.1871677881818161,
    "G1_bus6500.sEXS.EFD" => 1.408690822969461, "G1_bus6700.hYGOV.PMECH" => 0.4314578249999963,
    "G1_bus6700.sCRX.EFD" => 1.405338622277506, "G1_bus6700.sTAB2A.VOTHSG" => 0.0,
    "G1_bus7000.iEESGO.PMECH" => 0.5519629342723005, "G1_bus7000.sTAB2A.VOTHSG" => 0.0,
    "G1_bus7100.hYGOV.PMECH" => 0.450046996999996, "G1_bus7100.sCRX.EFD" => 1.72671126075657,
    "G1_bus7100.sTAB2A.VOTHSG" => 5.473822126268817e-48, "G1_bus8500.iEESGO.PMECH" => 0.1316528792307692,
    "G1_bus8500.sCRX.EFD" => 1.500012483221284, "G1_bus8500.sTAB2A.VOTHSG" => 0.0,
    "G2_add_bus5100.hYGOV.PMECH" => 0.2931291708333306, "G2_add_bus5100.sEXS.EFD" => 1.635877658271898,
    "G2_add_bus5500.hYGOV.PMECH" => 0.200873476551722, "G2_add_bus5500.sEXS.EFD" => 1.076428480518547,
    "G2_add_bus6000.hYGOV.PMECH" => 0.6321235205882303, "G2_add_bus6000.sEXS.EFD" => 1.379309517074801,
    "G2_bus3000.iEESGO.PMECH" => 0.2855638476923077, "G2_bus3000.sTAB2A.VOTHSG" => 0.0,
    "G2_bus3115.hYGOV.PMECH" => 0.2930991990909119, "G2_bus3115.sCRX.EFD" => 1.065787520421433,
    "G2_bus3115.sTAB2A.VOTHSG" => 0.0, "G2_bus3249.hYGOV.PMECH" => 0.3291477774502609,
    "G2_bus3249.sCRX.EFD" => 1.155593802434013, "G2_bus3300.iEESGO.PMECH" => 0.6440440781818182,
    "G2_bus3300.sCRX.EFD" => 1.961072477373684, "G2_bus3300.sTAB2A.VOTHSG" => 0.0,
    "G2_bus3359.iEESGO.PMECH" => 0.5177399814814815, "G2_bus3359.sCRX.EFD" => 1.941196433226657,
    "G2_bus3359.sTAB2A.VOTHSG" => 0.0, "G2_bus5300.hYGOV.PMECH" => 0.6110854591666618,
    "G2_bus5300.sCRX.EFD" => 1.520119877274811, "G2_bus5300.sTAB2A.VOTHSG" => 0.0,
    "G2_bus5400.hYGOV.PMECH" => 0.2720342889795891, "G2_bus5400.sEXS.EFD" => 1.371720154712221,
    "G2_bus5600.hYGOV.PMECH" => 0.1582512133333352, "G2_bus5600.sCRX.EFD" => 1.373636236207568,
    "G2_bus6100.hYGOV.PMECH" => 0.5071136967741894, "G2_bus6100.sCRX.EFD" => 1.404976303503247,
    "G2_bus6100.sTAB2A.VOTHSG" => 0.0, "G2_bus6500.hYGOV.PMECH" => 0.1871677881818161,
    "G2_bus6500.sEXS.EFD" => 1.408690822969461, "G2_bus6700.hYGOV.PMECH" => 0.4314578249999963,
    "G2_bus6700.sCRX.EFD" => 1.405338622277506, "G2_bus6700.sTAB2A.VOTHSG" => 0.0,
    "G2_bus7000.iEESGO.PMECH" => 0.5519629342723005, "G2_bus7000.sTAB2A.VOTHSG" => 0.0,
    "G2_bus7100.hYGOV.PMECH" => 0.450046996999996, "G2_bus7100.sCRX.EFD" => 1.72671126075657,
    "G2_bus7100.sTAB2A.VOTHSG" => 5.473822126268817e-48, "G2_bus8500.iEESGO.PMECH" => 0.1316528792307692,
    "G2_bus8500.sCRX.EFD" => 1.500012483221284, "G2_bus8500.sTAB2A.VOTHSG" => 0.0,
    "G3_add_bus5300.hYGOV.PMECH" => 0.6110854591666618, "G3_add_bus5300.sCRX.EFD" => 1.520119877274811,
    "G3_add_bus5300.sTAB2A.VOTHSG" => 0.0, "G3_add_bus5600.hYGOV.PMECH" => 0.1582512133333352,
    "G3_add_bus5600.sCRX.EFD" => 1.373636236207568, "G3_add_bus6000.hYGOV.PMECH" => 0.6321235205882303,
    "G3_add_bus6000.sEXS.EFD" => 1.379309517074801, "G3_add_bus6700.hYGOV.PMECH" => 0.4314578249999963,
    "G3_add_bus6700.sCRX.EFD" => 1.405338622277506, "G3_add_bus6700.sTAB2A.VOTHSG" => 0.0,
    "G3_bus3000.iEESGO.PMECH" => 0.2855638476923077, "G3_bus3000.sTAB2A.VOTHSG" => 0.0,
    "G3_bus3115.hYGOV.PMECH" => 0.2930991990909119, "G3_bus3115.sCRX.EFD" => 1.065787520421433,
    "G3_bus3115.sTAB2A.VOTHSG" => 2.465039865547053e-32, "G3_bus3249.hYGOV.PMECH" => 0.3291477774502609,
    "G3_bus3249.sCRX.EFD" => 1.155593802434013, "G3_bus3300.iEESGO.PMECH" => 0.6440440781818182,
    "G3_bus3300.sCRX.EFD" => 1.961072477373684, "G3_bus3300.sTAB2A.VOTHSG" => 0.0,
    "G3_bus3359.iEESGO.PMECH" => 0.5177399814814815, "G3_bus3359.sCRX.EFD" => 1.941196433226657,
    "G3_bus3359.sTAB2A.VOTHSG" => 0.0, "G3_bus6100.hYGOV.PMECH" => 0.5071136967741894,
    "G3_bus6100.sCRX.EFD" => 1.404976303503247, "G3_bus6100.sTAB2A.VOTHSG" => 0.0,
    "G3_bus6500.hYGOV.PMECH" => 0.1871677881818161, "G3_bus6500.sEXS.EFD" => 1.408690822969461,
    "G3_bus7000.iEESGO.PMECH" => 0.5519629342723005, "G3_bus7000.sTAB2A.VOTHSG" => 0.0,
    "G3_bus7100.hYGOV.PMECH" => 0.450046996999996, "G3_bus7100.sCRX.EFD" => 1.72671126075657,
    "G3_bus7100.sTAB2A.VOTHSG" => 5.473822126268817e-48, "G3_bus8500.iEESGO.PMECH" => 0.1316528792307692,
    "G3_bus8500.sCRX.EFD" => 1.500012483221284, "G3_bus8500.sTAB2A.VOTHSG" => 0.0,
    "G4_add_bus3115.hYGOV.PMECH" => 0.2930991990909119, "G4_add_bus3115.sCRX.EFD" => 1.065787520421433,
    "G4_add_bus3115.sTAB2A.VOTHSG" => 0.0, "G4_add_bus3300.iEESGO.PMECH" => 0.6440440781818182,
    "G4_add_bus3300.sCRX.EFD" => 1.961072477373684, "G4_add_bus3300.sTAB2A.VOTHSG" => 0.0,
    "G4_add_bus5300.hYGOV.PMECH" => 0.6110854591666618, "G4_add_bus5300.sCRX.EFD" => 1.520119877274811,
    "G4_add_bus5300.sTAB2A.VOTHSG" => 0.0, "G4_add_bus5600.hYGOV.PMECH" => 0.1582512133333352,
    "G4_add_bus5600.sCRX.EFD" => 1.373636236207568, "G4_add_bus6000.hYGOV.PMECH" => 0.6321235205882303,
    "G4_add_bus6000.sEXS.EFD" => 1.379309517074801, "G4_add_bus6700.hYGOV.PMECH" => 0.4314578249999963,
    "G4_add_bus6700.sCRX.EFD" => 1.405338622277506, "G4_add_bus6700.sTAB2A.VOTHSG" => 0.0,
    "G4_bus3249.hYGOV.PMECH" => 0.3291477774502609, "G4_bus3249.sCRX.EFD" => 1.155593802434013,
    "G4_bus3359.iEESGO.PMECH" => 0.5177399814814815, "G4_bus3359.sCRX.EFD" => 1.941196433226657,
    "G4_bus3359.sTAB2A.VOTHSG" => 0.0, "G4_bus6100.hYGOV.PMECH" => 0.5071136967741894,
    "G4_bus6100.sCRX.EFD" => 1.404976303503247, "G4_bus6100.sTAB2A.VOTHSG" => 0.0,
    "G4_bus6500.hYGOV.PMECH" => 0.1871677881818161, "G4_bus6500.sEXS.EFD" => 1.408690822969461,
    "G4_bus7000.iEESGO.PMECH" => 0.5519629342723005, "G4_bus7000.sTAB2A.VOTHSG" => 0.0,
    "G4_bus8500.iEESGO.PMECH" => 0.1316528792307692, "G4_bus8500.sCRX.EFD" => 1.500012483221284,
    "G4_bus8500.sTAB2A.VOTHSG" => 0.0, "G5_add_bus3115.hYGOV.PMECH" => 0.2930991990909119,
    "G5_add_bus3115.sCRX.EFD" => 1.065787520421433, "G5_add_bus3115.sTAB2A.VOTHSG" => 0.0,
    "G5_add_bus3300.iEESGO.PMECH" => 0.6440440781818182, "G5_add_bus3300.sCRX.EFD" => 1.961072477373684,
    "G5_add_bus3300.sTAB2A.VOTHSG" => 0.0, "G5_add_bus5300.hYGOV.PMECH" => 0.6110854591666618,
    "G5_add_bus5300.sCRX.EFD" => 1.520119877274811, "G5_add_bus5300.sTAB2A.VOTHSG" => 0.0,
    "G5_bus3249.hYGOV.PMECH" => 0.3291477774502609, "G5_bus3249.sCRX.EFD" => 1.155593802434013,
    "G5_bus3359.iEESGO.PMECH" => 0.5177399814814815, "G5_bus3359.sCRX.EFD" => 1.941196433226657,
    "G5_bus3359.sTAB2A.VOTHSG" => 0.0, "G5_bus6100.hYGOV.PMECH" => 0.5071136967741894,
    "G5_bus6100.sCRX.EFD" => 1.404976303503247, "G5_bus6100.sTAB2A.VOTHSG" => 0.0,
    "G5_bus7000.iEESGO.PMECH" => 0.5519629342723005, "G5_bus7000.sTAB2A.VOTHSG" => 0.0,
    "G5_bus8500.iEESGO.PMECH" => 0.1316528792307692, "G5_bus8500.sCRX.EFD" => 1.500012483221284,
    "G5_bus8500.sTAB2A.VOTHSG" => 0.0, "G6_add_bus3300.iEESGO.PMECH" => 0.6440440781818182,
    "G6_add_bus3300.sCRX.EFD" => 1.961072477373684, "G6_add_bus3300.sTAB2A.VOTHSG" => 0.0,
    "G6_add_bus5300.hYGOV.PMECH" => 0.6110854591666618, "G6_add_bus5300.sCRX.EFD" => 1.520119877274811,
    "G6_add_bus5300.sTAB2A.VOTHSG" => 0.0, "G6_bus3249.hYGOV.PMECH" => 0.3291477774502609,
    "G6_bus3249.sCRX.EFD" => 1.155593802434013, "G6_bus3359.iEESGO.PMECH" => 0.5177399814814815,
    "G6_bus3359.sCRX.EFD" => 1.941196433226657, "G6_bus3359.sTAB2A.VOTHSG" => 0.0,
    "G6_bus7000.iEESGO.PMECH" => 0.5519629342723005, "G6_bus7000.sTAB2A.VOTHSG" => 0.0,
    "G6_bus8500.iEESGO.PMECH" => 0.1316528792307692, "G6_bus8500.sCRX.EFD" => 1.500012483221284,
    "G6_bus8500.sTAB2A.VOTHSG" => 0.0, "G7_bus3249.hYGOV.PMECH" => 0.3291477774502609,
    "G7_bus3249.sCRX.EFD" => 1.155593802434013, "G7_bus7000.iEESGO.PMECH" => 0.5519629342723005,
    "G7_bus7000.sTAB2A.VOTHSG" => 0.0, "G8_add_bus3249.hYGOV.PMECH" => 0.3291477774502609,
    "G8_add_bus3249.sCRX.EFD" => 1.155593802434013, "G8_bus7000.iEESGO.PMECH" => 0.5519629342723005,
    "G8_bus7000.sTAB2A.VOTHSG" => 0.0, "G9_bus7000.iEESGO.PMECH" => 0.5519629342723005,
    "G9_bus7000.sTAB2A.VOTHSG" => 0.0, "bus_3000.v" => 0.9999999126293205, "bus_3020.v" => 0.995898407325996,
    "bus_3100.v" => 1.03795255487805, "bus_3115.v" => 0.9999999280086971, "bus_3200.v" => 1.032228582029149,
    "bus_3244.v" => 0.995714619240619, "bus_3245.v" => 0.9999999124756667, "bus_3249.v" => 0.9999999632592104,
    "bus_3300.v" => 0.9999999215496713, "bus_3359.v" => 0.9999998632752102, "bus_3360.v" => 1.001123687900391,
    "bus_3701.v" => 1.008832999809755, "bus_5100.v" => 0.9999994271246399, "bus_5101.v" => 0.9920434411998078,
    "bus_5102.v" => 0.9951996741576932, "bus_5103.v" => 0.9925748342518396, "bus_5300.v" => 0.9999996850954396,
    "bus_5301.v" => 0.9942801831715216, "bus_5304.v" => 0.9919056025485995, "bus_5305.v" => 1.000542035582019,
    "bus_5400.v" => 1.006998564029117, "bus_5401.v" => 1.009458842206898, "bus_5402.v" => 1.003230891120203,
    "bus_5500.v" => 1.003999000475353, "bus_5501.v" => 1.0087819058239, "bus_5600.v" => 1.009999228638515,
    "bus_5601.v" => 1.007135556834811, "bus_5602.v" => 1.034140896051697, "bus_5603.v" => 1.035639556900277,
    "bus_5610.v" => 1.03770212908961, "bus_5620.v" => 1.007601974801708, "bus_6000.v" => 1.004998445924455,
    "bus_6001.v" => 1.00168770777907, "bus_6100.v" => 0.9999996924801752, "bus_6500.v" => 0.9999998924344922,
    "bus_6700.v" => 1.019999529201063, "bus_6701.v" => 1.009081778198963, "bus_7000.v" => 0.9999999903652979,
    "bus_7010.v" => 1.003242420503899, "bus_7020.v" => 0.9976051038746508, "bus_7100.v" => 0.9999999768642839,
    "bus_8500.v" => 1.019999905850399, "bus_8600.v" => 1.02024447686321, "bus_8700.v" => 1.019999905850399,
    "G1_bus3000.iEEET2.EFD" => 1.580011467534384, "G1_bus7000.iEEET2.EFD" => 1.738367594679636,
    "G2_bus3000.iEEET2.EFD" => 1.580011467534384, "G2_bus7000.iEEET2.EFD" => 1.738367594679636,
    "G3_bus3000.iEEET2.EFD" => 1.580011467534384, "G3_bus7000.iEEET2.EFD" => 1.738367594679636,
    "G4_bus7000.iEEET2.EFD" => 1.738367594679636, "G5_bus7000.iEEET2.EFD" => 1.738367594679636,
    "G6_bus7000.iEEET2.EFD" => 1.738367594679636, "G7_bus7000.iEEET2.EFD" => 1.738367594679636,
    "G8_bus7000.iEEET2.EFD" => 1.738367594679636, "G9_bus7000.iEEET2.EFD" => 1.738367594679636,
]
# 417 values

@testset "Examples.N44.Base_Case.Nordic44_Base_Case" begin
    @named sys0 = Nordic44_Base_Case()
    sys = mtkcompile(sys0)
    @test length(unknowns(sys)) == 1595
    integ = init(ODEProblem(sys, [], (0.0, 10.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-9)
    worst, worst_name = 0.0, ""
    for (col, ref) in OM_N44_T0
        v = sys
        for part in split(col, ".")
            v = getproperty(v, Symbol(part))
        end
        d = abs(integ[v] - ref)
        d > worst && ((worst, worst_name) = (d, col))
    end
    @test worst <= 1e-6
    worst > 1e-6 && @info "N44 t = 0: worst |MTK - OM| = $worst on $worst_name"
end
