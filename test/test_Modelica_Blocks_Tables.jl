# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Mini-MSL Blocks.Tables (PLAN-05). CombiTable1Ds(table = [0 0; 1 1; 2 4; 4 16], LinearSegments, LastTwoPoints),
# MSL's own documentation example: u = 1 -> 1, u = 1.5 -> 2.5, u = 2 -> 4, u = -1 -> -1 (extrapolation with the first
# two points), u = 5 -> 22 (extrapolation with the last two: 16 + 1*(16-4)/2 = 22).
# The input is symbolic and inside a system with an Integrator, so the chain of `ifelse` is exercised in a compiled
# model, not only as arithmetic: u = 3t - 1 over [0, 2] sweeps -1 -> 5 through every segment.
@testset "Modelica.Blocks.Tables.CombiTable1Ds" begin
    tbl = [0.0 0.0; 1.0 1.0; 2.0 4.0; 4.0 16.0]
    @named ct = CombiTable1Ds(; table = tbl)
    @named int = Integrator(; k = 1, y_start = 0)
    @named rig = System(Equation[ct.u ~ 3 * t - 1, int.u ~ ct.y[1]], t, [], []; systems = [ct, int])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
    @test sol.retcode == ReturnCode.Success
    at(u) = sol((u + 1) / 3; idxs = sys.ct.y[1])
    @test at(-1.0) ≈ -1.0 atol = 1e-9    # extrapolation below the first point
    @test at(0.0) ≈ 0.0 atol = 1e-9      # node
    @test at(0.5) ≈ 0.5 atol = 1e-9      # mid-segment
    @test at(1.0) ≈ 1.0 atol = 1e-9      # node
    @test at(1.5) ≈ 2.5 atol = 1e-9      # mid-segment
    @test at(2.0) ≈ 4.0 atol = 1e-9      # node
    @test at(3.0) ≈ 10.0 atol = 1e-9     # mid-segment
    @test at(4.0) ≈ 16.0 atol = 1e-9     # node
    @test at(5.0) ≈ 22.0 atol = 1e-9     # extrapolation above the last point
end

# CombiTable1Ds with extrapolation = :HoldLastPoint (PLAN-07, new in batch 7: the VDL tables of REECCU1).
# Same table as above; inside the range nothing changes, outside it the first / last value is held:
# u = -1 -> 0 (not -1), u = 5 -> 16 (not 22).
@testset "Modelica.Blocks.Tables.CombiTable1Ds HoldLastPoint" begin
    tbl = [0.0 0.0; 1.0 1.0; 2.0 4.0; 4.0 16.0]
    @named ct = CombiTable1Ds(; table = tbl, extrapolation = :HoldLastPoint)
    @named int = Integrator(; k = 1, y_start = 0)
    @named rig = System(Equation[ct.u ~ 3 * t - 1, int.u ~ ct.y[1]], t, [], []; systems = [ct, int])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
    @test sol.retcode == ReturnCode.Success
    at(u) = sol((u + 1) / 3; idxs = sys.ct.y[1])
    @test at(-1.0) ≈ 0.0 atol = 1e-9     # held below the first point
    @test at(-0.5) ≈ 0.0 atol = 1e-9
    @test at(0.0) ≈ 0.0 atol = 1e-9      # node
    @test at(1.5) ≈ 2.5 atol = 1e-9      # inside the range: unchanged
    @test at(4.0) ≈ 16.0 atol = 1e-9     # node
    @test at(4.5) ≈ 16.0 atol = 1e-9     # held above the last point
    @test at(5.0) ≈ 16.0 atol = 1e-9
end

# CombiTimeTable (PLAN-07, new in batch 7: the two tables of IrradianceToPower). Same shape as CombiTable1Ds but
# with time as the abscissa, so the block is read along the solution itself. table = [0 0; 1 1; 2 4] over [0, 3]:
# linear inside, and the two extrapolations differ past t = 2 (LastTwoPoints: 4 + (t-2)*3; HoldLastPoint: 4).
# `columns = [2, 3]` on a three-column table and `offset` are checked on a second instance.
@testset "Modelica.Blocks.Sources.CombiTimeTable" begin
    tbl = [0.0 0.0; 1.0 1.0; 2.0 4.0]
    @named ctt = CombiTimeTable(; table = tbl)
    @named cth = CombiTimeTable(; table = tbl, extrapolation = :HoldLastPoint)
    @named ct2 = CombiTimeTable(; table = [0.0 0.0 10.0; 2.0 2.0 20.0], columns = [2, 3], offset = [0.5])
    @named rig = System(Equation[], t, [], []; systems = [ctt, cth, ct2])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 3.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10, saveat = 0.5)
    @test sol.retcode == ReturnCode.Success
    a(v, tk) = sol(tk; idxs = v)
    @test a(sys.ctt.y[1], 0.0) ≈ 0.0 atol = 1e-9
    @test a(sys.ctt.y[1], 0.5) ≈ 0.5 atol = 1e-9      # first segment
    @test a(sys.ctt.y[1], 1.0) ≈ 1.0 atol = 1e-9      # node
    @test a(sys.ctt.y[1], 1.5) ≈ 2.5 atol = 1e-9      # second segment
    @test a(sys.ctt.y[1], 2.0) ≈ 4.0 atol = 1e-9      # last node
    @test a(sys.ctt.y[1], 3.0) ≈ 7.0 atol = 1e-9      # LastTwoPoints: 4 + 1*(4 - 1)/1
    @test a(sys.cth.y[1], 1.5) ≈ 2.5 atol = 1e-9      # inside the range: the same
    @test a(sys.cth.y[1], 3.0) ≈ 4.0 atol = 1e-9      # HoldLastPoint
    @test a(sys.ct2.y[1], 1.0) ≈ 1.5 atol = 1e-9      # column 2 = t, plus offset 0.5
    @test a(sys.ct2.y[2], 1.0) ≈ 15.5 atol = 1e-9     # column 3 = 10 + 5t, plus offset 0.5
end
