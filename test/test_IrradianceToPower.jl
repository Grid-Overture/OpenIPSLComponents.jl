# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Renewables.PSSE.AddOnBlocks.IrradianceToPower (PLAN-07, batch 7). Its only upstream Test,
# `Renewable.PSSE.PVPlantSolarIrradiance`, is N (WhiteNoiseInjection + Blocks.Noise.GlobalSeed over 86 400 s), so
# this file is the whole validation of the block and of the `Irr2Pow` branch of `PV`.
#
# Ppv = (Ypv/M_b)*fpv*(G/Gtstc)*(1 + ap*(T - Tcstc)), with the two inputs interpolated from their tables.
# Ypv = 1000, M_b = 100e6, fpv = 0.9, Gtstc = 1000, ap = -0.48, Tcstc = 25;
# SolarRadiationTable = [0 0; 1 500; 2 1000], SolarArrayTemperatureTable = [0 25; 1 30; 2 20].
#   t = 0.0 : G = 0,    T = 25   -> Ppv = 1e-5*0.9*0    *(1 - 0.48*0)  = 0
#   t = 0.5 : G = 250,  T = 27.5 -> Ppv = 1e-5*0.9*0.25 *(1 - 0.48*2.5)  = 9e-6*0.25*(-0.2)   = -4.5e-7
#   t = 1.0 : G = 500,  T = 30   -> Ppv = 1e-5*0.9*0.5  *(1 - 0.48*5)    = 9e-6*0.5*(-1.4)    = -6.3e-6
#   t = 1.5 : G = 750,  T = 25   -> Ppv = 1e-5*0.9*0.75 *(1 - 0.48*0)    = 9e-6*0.75          =  6.75e-6
#   t = 2.0 : G = 1000, T = 20   -> Ppv = 1e-5*0.9*1    *(1 - 0.48*(-5)) = 9e-6*3.4           =  3.06e-5
# (`ap = -0.48` with temperatures in the tens makes the factor go negative: that is the .mo's own default, which
# is meant for `ap` in %/K; replicated, not fixed.)
@testset "Renewables.PSSE.AddOnBlocks.IrradianceToPower" begin
    @named i2p = IrradianceToPower(; M_b = 100e6, Ypv = 1000.0, Tcstc = 25.0, fpv = 0.9, ap = -0.48,
        Gtstc = 1000.0, SolarRadiationTable = [0.0 0.0; 1.0 500.0; 2.0 1000.0],
        SolarArrayTemperatureTable = [0.0 25.0; 1.0 30.0; 2.0 20.0])
    @named rig = System(Equation[], t, [], []; systems = [i2p])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 2.0)), Rodas5P(); abstol = 1e-12, reltol = 1e-12, saveat = 0.5)
    @test sol.retcode == ReturnCode.Success
    g = 1e-5 * 0.9
    @test sol(0.0; idxs = sys.i2p.Ppv) ≈ 0.0 atol = 1e-12
    @test sol(0.5; idxs = sys.i2p.Ppv) ≈ g * 0.25 * (1 - 0.48 * 2.5) atol = 1e-12
    @test sol(1.0; idxs = sys.i2p.Ppv) ≈ g * 0.5 * (1 - 0.48 * 5.0) atol = 1e-12
    @test sol(1.5; idxs = sys.i2p.Ppv) ≈ g * 0.75 atol = 1e-12
    @test sol(2.0; idxs = sys.i2p.Ppv) ≈ g * 1.0 * (1 - 0.48 * (-5.0)) atol = 1e-12
end

# The `Irr2Pow` branch of the `PV` template: with `Irr2Pow = true` and `QFunctionality = 0` the plant grows the
# input `i2p` and the block `gain2` that carries it to `RenewableController.Pref`, and `gain` (the p_0 path)
# disappears. On a minimal network at the power-flow point, `RenewableController.Pref` must equal the value the
# irradiance block computes at t = 0, not `p_0`.
# Tables chosen so that Ppv(0) = 1e-5*0.9*(800/1000)*(1 - 0.48*(30 - 25)) = 9e-6*0.8*(-1.4) = -1.008e-5.
@testset "Renewables.PSSE.PV with Irr2Pow" begin
    P_0, Q_0, v_0, angle_0, M_b = 1.5e6, -5.6658e6, 1.0, 0.02574992, 100e6
    @named src = FixedVoltageSource(; vr = v_0 * cos(angle_0), vi = v_0 * sin(angle_0))
    @named i2p = IrradianceToPower(; M_b, Ypv = 1000.0, Tcstc = 25.0, fpv = 0.9, ap = -0.48, Gtstc = 1000.0,
        SolarRadiationTable = [0.0 800.0; 1.0 800.0], SolarArrayTemperatureTable = [0.0 30.0; 1.0 30.0])
    @named pv = PV(; S_b = 100e6, M_b, P_0, Q_0, v_0, angle_0, QFunctionality = 0, PFunctionality = 0,
        Irr2Pow = true,
        mods = (; RenewableGenerator = (; redeclare = REGCA1),
            RenewableController = (; redeclare = REECB1, vref0 = 1.0)))
    @named rig = System(Equation[connect(src.p, pv.pwPin), pv.i2p ~ i2p.Ppv], t, [], []; systems = [src, pv, i2p])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    ppv = 1e-5 * 0.9 * 0.8 * (1 - 0.48 * 5.0)
    @test integ[sys.i2p.Ppv] ≈ ppv atol = 1e-12
    @test integ[sys.pv.RenewableController.Pref] ≈ ppv atol = 1e-12    # not p_0 = 0.015
    @test integ[sys.pv.gain2.y] ≈ ppv atol = 1e-12
    # the reactive path is unchanged: gain1 still carries q_0 to Qext
    @test integ[sys.pv.RenewableController.Qext] ≈ Q_0 / M_b atol = 1e-12
end
