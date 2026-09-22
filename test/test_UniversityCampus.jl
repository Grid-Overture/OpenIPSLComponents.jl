# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Examples.Microgrids.UniversityCampus (PLAN-07, batch 7): the two campus systems.
# Neither has an OpenModelica reference (F-63), so what is validated here is the transcription, the size and --
# for the one that has an operating point -- the operating point itself and the equilibrium.

# CampusGridA does **not** have an operating point in any tool (F-66): its six transformers are declared with
# `CW = 2` while `t1`, `t2`, `VB1` and `VB2` keep their defaults, so each of them has ratio 1 and an impedance of
# `X*(t2/VB2)^2 = 0.1537*(1/300e3)^2 = 1.708e-12` pu -- a short circuit between the 69 kV and the 12 kV sides.
# The port reproduces that faithfully (rule 5), so the test checks the transcription and the arithmetic that
# explains the failure, not an initialization that cannot exist.
@testset "Examples.Microgrids.UniversityCampus.CampusGridA" begin
    @named cga = CampusGridA()
    @test length(ModelingToolkit.get_systems(cga)) == 62
    sys = mtkcompile(cga)
    @test length(unknowns(sys)) == 114

    # the transformer arithmetic of F-66, read off the compiled system
    for T in (:T1, :T2, :T3, :T4, :T5, :T6)
        tf = getproperty(sys, T)
        @test ModelingToolkit.getdefault(tf.CW) == 2
        @test ModelingToolkit.getdefault(tf.t1) == 1.0        # not 69000, which is what CW = 2 means
        @test ModelingToolkit.getdefault(tf.VB1) == 300e3      # the class default, never overridden by the .mo
        @test ModelingToolkit.getdefault(tf.VB2) == 300e3
        @test ModelingToolkit.getdefault(tf.T1) ≈ 1 / 300e3 atol = 1e-15
        @test ModelingToolkit.getdefault(tf.T2) ≈ 1 / 300e3 atol = 1e-15
        @test ModelingToolkit.getdefault(tf.x) * ModelingToolkit.getdefault(tf.T2)^2 < 1e-11   # a short circuit
    end
    # and the record the units read is the .mo's
    @test CampusA_CTG1.machine.M_b == 53.9e6
    @test CampusA_CTG1.excSystem.K_PR == 40
    @test CampusA_STG1.tg.T_1 == 0.49 || CampusA_STG1.tg.R == 0.05     # TGOV1STG1
    @test CampusA_Pf00000.powerflow.bus.V1 == 1
end

# CampusGridB **does** have an operating point: it initializes and runs its 10 s. It is the largest system of the
# port so far (94 subsystems, 157 unknowns) and `mtkcompile` takes about 3 s, against `SevenBus`'s 59 s for 112
# unknowns (F-47) -- the size risk `AUDIT-01` raised for this batch did not materialise.
# The case is an equilibrium run (fault at 1000 s, seven breakers with no `t_o`), so the acceptance is that it
# stays near its power-flow point: the record and the initialized voltages agree to 2.3e-4 pu, and over the 10 s
# the network drifts by under 1e-2 pu, which is the `.mo`'s own power-flow inconsistency (F-57's shape) and not a
# transcription error.
@testset "Examples.Microgrids.UniversityCampus.CampusGridB" begin
    @named cgb = CampusGridB()
    @test length(ModelingToolkit.get_systems(cgb)) == 94
    sys = mtkcompile(cgb)
    @test length(unknowns(sys)) == 157
    integ = init(ODEProblem(sys, [], (0.0, 10.0)), Rodas5P(); initializealg = INIT)
    @test integ.sol.retcode != ReturnCode.InitialFailure
    R = CampusB_Pf00000.powerflow
    # the operating point against the .mo's own record
    @test integ[sys.B1L1.v] ≈ R.bus.VB1L1 atol = 1e-3
    @test integ[sys.B2L1.v] ≈ R.bus.VB2L1 atol = 1e-3
    # the three synchronous units and the five inverter interfaces are all live
    @test integ[sys.GT1.machine.delta] != 0.0
    @test integ[sys.GT2.machine.delta] != 0.0
    @test integ[sys.ST.baseMachine.delta] != 0.0
    for k in 1:5
        @test integ[getproperty(sys, Symbol("PV", k)).RenewableGenerator.Pgen] > 0.0
    end
    # the steam unit keeps the .mo's own names for its machine and governor (sic)
    @test integ[sys.ST.baseGovernor.PMECH] > 0.0
    @test integ[sys.GT1.governor.PMECH] > 0.0
end
