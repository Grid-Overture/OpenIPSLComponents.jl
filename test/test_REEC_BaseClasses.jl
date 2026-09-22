# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Renewables.PSSE.ElectricalController base classes (PLAN-07, batch 7): the three current-limit logics and the
# state-of-charge logic. None of them has an upstream Test of its own; the controllers that instantiate them are
# validated by the three `Renewable.PSSE` Tests. Arithmetic in each comment, 1e-9 on algebraic values.

# CurrentLimitLogicREECA, the odd one (`sqrt` of currents, not of squares of currents -- OpenIPSL 3.1.0 as written):
#   Ipre  = sqrt(Imax) - sqrt(abs(Iqcmd))   [pqflag = false]   or   sqrt(Imax) - sqrt(abs(Ipcmd))   [true]
#   Ipost = if Ipre < 0 then 0 else sqrt(Ipre)
#   Iqmax = min(VDL1, Imax) / min(Ipost, VDL1);   Ipmax = min(Ipost, VDL2) / min(VDL2, Imax);   Ipmin = 0
# With Imax = 1.7, Iqcmd = 0.25, Ipcmd = 0.81, VDL1 = 1.25, VDL2 = 1.15:
#   sqrt(1.7) = 1.3038404810405297
#   pqflag = false: Ipre = 1.3038404810405297 - 0.5 = 0.8038404810405297, Ipost = 0.8965715712...,
#                   Iqmax = min(1.25, 1.7) = 1.25,  Ipmax = min(0.8965.., 1.15) = 0.8965..
#   pqflag = true:  Ipre = 1.3038404810405297 - 0.9 = 0.4038404810405297, Ipost = 0.6354844459...,
#                   Iqmax = min(0.6354.., 1.25) = 0.6354..,  Ipmax = min(1.15, 1.7) = 1.15
# A negative `Ipre` branch as well: Imax = 0.01 (sqrt = 0.1) with Iqcmd = 0.25 (sqrt = 0.5) gives Ipre = -0.4 < 0
# and Ipost = 0, so Ipmax = min(0, VDL2) = 0.
@testset "Renewables.PSSE.ElectricalController CurrentLimitLogicREECA" begin
    s5 = sqrt(1.7)
    for (pq, iqmax, ipmax) in ((false, 1.25, sqrt(s5 - 0.5)), (true, sqrt(s5 - 0.9), 1.15))
        ccl = CurrentLimitLogicREECA(; name = :ccl, start_ii = 0.0, start_ir = 0.0, Imax = 1.7, pqflag = pq)
        @named rig = System(Equation[ccl.Iqcmd ~ 0.25, ccl.Ipcmd ~ 0.81,
            ccl.VDL1_out ~ 1.25, ccl.VDL2_out ~ 1.15, ccl.pqflag ~ (pq ? 1.0 : 0.0)], t, [], []; systems = [ccl])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
        @test integ[sys.ccl.Ipre] ≈ s5 - (pq ? 0.9 : 0.5) atol = 1e-9
        @test integ[sys.ccl.Ipost] ≈ sqrt(s5 - (pq ? 0.9 : 0.5)) atol = 1e-9
        @test integ[sys.ccl.Iqmax] ≈ iqmax atol = 1e-9
        @test integ[sys.ccl.Iqmin] ≈ -iqmax atol = 1e-9
        @test integ[sys.ccl.Ipmax] ≈ ipmax atol = 1e-9
        @test integ[sys.ccl.Ipmin] ≈ 0.0 atol = 1e-12       # 0, not -Ipmax (that is REECC)
    end
    # Ipre < 0 -> Ipost = 0
    ccl = CurrentLimitLogicREECA(; name = :ccl, start_ii = 0.0, start_ir = 0.0, Imax = 0.01, pqflag = false)
    @named rig = System(Equation[ccl.Iqcmd ~ 0.25, ccl.Ipcmd ~ 0.81,
        ccl.VDL1_out ~ 1.25, ccl.VDL2_out ~ 1.15, ccl.pqflag ~ 0.0], t, [], []; systems = [ccl])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.ccl.Ipre] ≈ 0.1 - 0.5 atol = 1e-9
    @test integ[sys.ccl.Ipost] ≈ 0.0 atol = 1e-12
    @test integ[sys.ccl.Ipmax] ≈ 0.0 atol = 1e-12
end

# CurrentLimitLogicREECB: Ipmax = Imax / sqrt(Imax^2 - Iqcmd^2), Iqmax = sqrt(Imax^2 - Ipcmd^2) / Imax, Ipmin = 0.
# Imax = 1.82, Iqcmd = 0.25, Ipcmd = 0.81:
#   sqrt(1.82^2 - 0.25^2) = sqrt(3.3124 - 0.0625) = sqrt(3.2499) = 1.8027479026...
#   sqrt(1.82^2 - 0.81^2) = sqrt(3.3124 - 0.6561) = sqrt(2.6563) = 1.6298159405...
@testset "Renewables.PSSE.ElectricalController CurrentLimitLogicREECB" begin
    for (pq, ipmax, iqmax) in ((false, sqrt(1.82^2 - 0.25^2), 1.82), (true, 1.82, sqrt(1.82^2 - 0.81^2)))
        ccl = CurrentLimitLogicREECB(; name = :ccl, start_ii = 0.0, start_ir = 0.0, Imax = 1.82, pqflag = pq)
        @named rig = System(Equation[ccl.Iqcmd ~ 0.25, ccl.Ipcmd ~ 0.81, ccl.Pqflag ~ (pq ? 1.0 : 0.0)],
            t, [], []; systems = [ccl])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
        @test integ[sys.ccl.Ipmax] ≈ ipmax atol = 1e-9
        @test integ[sys.ccl.Iqmax] ≈ iqmax atol = 1e-9
        @test integ[sys.ccl.Iqmin] ≈ -iqmax atol = 1e-9
        @test integ[sys.ccl.Ipmin] ≈ 0.0 atol = 1e-12
    end
end

# CurrentLimitLogicREECC: the same squares, but bounded by the VDL outputs and with `Ipmin = -Ipmax`.
# Imax = 1.11, VDL1 = 0.75, VDL2 = 1.11, Iqcmd = 0.25, Ipcmd = 0.81:
#   sqrt(1.11^2 - 0.25^2) = sqrt(1.2321 - 0.0625) = sqrt(1.1696) = 1.0814804668...
#   sqrt(1.11^2 - 0.81^2) = sqrt(1.2321 - 0.6561) = sqrt(0.576)  = 0.7589466384...
#   pqflag = false: Iqmax = min(0.75, 1.11) = 0.75;   Ipmax = min(1.11, 1.08148..) = 1.08148..
#   pqflag = true:  Iqmax = min(0.75, 0.75894..) = 0.75;  Ipmax = min(1.11, 1.11) = 1.11
@testset "Renewables.PSSE.ElectricalController CurrentLimitLogicREECC" begin
    for (pq, iqmax, ipmax) in ((false, 0.75, sqrt(1.11^2 - 0.25^2)), (true, 0.75, 1.11))
        ccl = CurrentLimitLogicREECC(; name = :ccl, start_ii = 0.0, start_ir = 0.0, Imax = 1.11, pqflag = pq)
        @named rig = System(Equation[ccl.Iqcmd ~ 0.25, ccl.Ipcmd ~ 0.81,
            ccl.VDL1_out ~ 0.75, ccl.VDL2_out ~ 1.11, ccl.pqflag ~ (pq ? 1.0 : 0.0)], t, [], []; systems = [ccl])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
        @test integ[sys.ccl.Iqmax] ≈ iqmax atol = 1e-9
        @test integ[sys.ccl.Iqmin] ≈ -iqmax atol = 1e-9
        @test integ[sys.ccl.Ipmax] ≈ ipmax atol = 1e-9
        @test integ[sys.ccl.Ipmin] ≈ -ipmax atol = 1e-9     # -Ipmax, unlike REECA/REECB
    end
end

# StateOfChargeLogic: ipmax_SOC = 0 below SOCmin, ipmin_SOC = 0 above SOCmax, both 1 in between.
# SOCmin = 0.2, SOCmax = 0.8 -> SOC = 0.1 -> (0, 1);  SOC = 0.5 -> (1, 1);  SOC = 0.9 -> (1, 0).
# The two knees are inclusive on the .mo's side (`<=`, `>=`): SOC = 0.2 -> (0, 1), SOC = 0.8 -> (1, 0).
@testset "Renewables.PSSE.ElectricalController StateOfChargeLogic" begin
    for (soc, mx, mn) in ((0.1, 0.0, 1.0), (0.2, 0.0, 1.0), (0.5, 1.0, 1.0), (0.8, 1.0, 0.0), (0.9, 1.0, 0.0))
        @named sl = StateOfChargeLogic(; SOCmin = 0.2, SOCmax = 0.8)
        @named rig = System(Equation[sl.SOC ~ soc], t, [], []; systems = [sl])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
        @test integ[sys.sl.ipmax_SOC] ≈ mx atol = 1e-12
        @test integ[sys.sl.ipmin_SOC] ≈ mn atol = 1e-12
    end
end
