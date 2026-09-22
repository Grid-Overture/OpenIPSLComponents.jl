# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Electrical.Wind.GE.Type_3.Turbine (PLAN-08, batch 8): Multi_Powers, Cp_function, Wind_Power_Model, Rotor_Model,
# Turbine_Model. None has an upstream Test of its own; GE_WT is exercised by Tests.Wind.GE.WT_Test against its
# oracle (37 variables). The numbers below are the GE data of GE_WT.mo and what its `initial algorithm` produces
# (`ge_wt_init`, F-72): genbc_k_speed = 1.2, wndtge_kp = 0.0010704731599680574, theta = 0.4700000000000003,
# lambda = 56.6 1.2/14 = 4.851428571428571, Vw = 14, wndtge_ang0 = -1/(1.11 1.2) = -0.7507507507507507.

# Multi_Powers(u1 = 2) = [1, 2, 4, 8, 16]. Cp_function: cp = theta_vec' K lambda_vec with the 5x5 GE matrix:
#   cp(8, 0) = -0.41909 + 0.21808 8 - 0.012406 64 - 0.00013365 512 + 0.000011524 4096 = 0.510339504,
#   cp(4.851429, 0) = 0.33804052766938475, cp(4.851428571428571, 0.47) = 0.3404396303512561.
# Wind_Power_Model(KI = 56.6, wndtge_kp = 0.0010704731599680574) at Vw = 14, omega = 1.2, Theta = 0.47:
#   Lambda = 56.6 1.2/14 = 4.8514, Pm = wndtge_kp cp Vw^3 = pmech = 1 by construction of wndtge_kp.
@testset "Wind.GE.Type_3.Turbine Multi_Powers, Cp_function, Wind_Power_Model" begin
    @named mp = Multi_Powers()
    @named cp8 = Cp_function()
    @named cp4 = Cp_function()
    @named cp47 = Cp_function()
    @named wpm = Wind_Power_Model(; KI = 56.6, wndtge_kp = 0.0010704731599680574)
    @named rig = System(Equation[mp.u1 ~ 2, cp8.Lambda ~ 8, cp8.Theta ~ 0, cp4.Lambda ~ 4.851429, cp4.Theta ~ 0,
            cp47.Lambda ~ 56.6 * 1.2 / 14, cp47.Theta ~ 0.47, wpm.Wind_Speed ~ 14, wpm.omega ~ 1.2, wpm.Theta ~ 0.47],
        t, [], []; systems = [mp, cp8, cp4, cp47, wpm])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test [integ[sys.mp.y[i]] for i in 1:5] ≈ [1, 2, 4, 8, 16] atol = 1e-12
    @test integ[sys.cp8.y] ≈ 0.510339504 atol = 1e-9
    @test integ[sys.cp4.y] ≈ 0.33804052766938475 atol = 1e-9
    @test integ[sys.cp47.y] ≈ 0.3404396303512561 atol = 1e-9
    @test integ[sys.wpm.cp_function1.Lambda] ≈ 56.6 * 1.2 / 14 atol = 1e-9
    @test integ[sys.wpm.Pm] ≈ 1.0 atol = 1e-9
end

# Rotor_Model with the GE data (H = 4.33, Hg = 0.62, wbase = 2 pi 60/3, Dtg = 1.5, Ktg = 1.11, the four states at 0,
# wndtge_spd0 = 1.2, wndtge_ang0 = -Pm/(Ktg spd0)) and Pm = Pe = 1: omega_gen = omega_turb = 1.2, the shaft torque
# Ktg (ang0 + theta_g - theta_t) = -Pm/spd0 balances Pm/omega_turb on the turbine and Pe/omega_gen on the generator:
# the four integrator derivatives are 0. With Pe = 0.9 the generator mass accelerates: der(integrator2.y) =
# (1/(2 Hg)) (-(0.9/1.2) + 1/1.2) = 0.1/(1.2 1.24) = 0.06720430107526882 and the turbine mass does not (its
# balance does not see Pe).
@testset "Wind.GE.Type_3.Turbine Rotor_Model" begin
    ang0 = -1.0 / (1.11 * 1.2)
    @named rot = Rotor_Model(; H = 4.33, Hg = 0.62, wbase = 2 * pi * 60 / 3, Dtg = 1.5, Ktg = 1.11, wt_x6_0 = 0, wt_x7_0 = 0,
        wt_x8_0 = 0, wt_x9_0 = 0, wndtge_ang0 = ang0, wndtge_spd0 = 1.2)
    @named rig = System(Equation[rot.Pm ~ 1, rot.Pe ~ 1], t, [], []; systems = [rot])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ[sys.rot.omega_gen] ≈ 1.2 atol = 1e-12
    @test integ[sys.rot.omega_turb] ≈ 1.2 atol = 1e-12
    for s in (sys.rot.integrator1.y, sys.rot.integrator2.y, sys.rot.integrator3.y, sys.rot.integrator4.y)
        @test abs(initial_derivative(integ, sys, s)) < 1e-9
    end
    @named rot2 = Rotor_Model(; H = 4.33, Hg = 0.62, wbase = 2 * pi * 60 / 3, Dtg = 1.5, Ktg = 1.11, wt_x6_0 = 0, wt_x7_0 = 0,
        wt_x8_0 = 0, wt_x9_0 = 0, wndtge_ang0 = ang0, wndtge_spd0 = 1.2)
    @named rig2 = System(Equation[rot2.Pm ~ 1, rot2.Pe ~ 0.9], t, [], []; systems = [rot2])
    sys2 = mtkcompile(rig2)
    integ2 = init(ODEProblem(sys2, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test initial_derivative(integ2, sys2, sys2.rot2.integrator2.y) ≈ 0.1 / (1.2 * 2 * 0.62) atol = 1e-9
    @test abs(initial_derivative(integ2, sys2, sys2.rot2.integrator1.y)) < 1e-9
end

# Turbine_Model with the GE data and the wt_x*_0 of `ge_wt_init` (the oracle's row 0: theta = 0.47, Pord = 0.9,
# omega = 1.2), fed with Pelec = 0.9 (= pmech WT_base/GEN_base, the electrical power that balances the rotor) and
# Wind_Speed = 14: Pord = limIntegrator2.y WT_base/GEN_base = 1 0.9 = 0.9, omega_gen = 1.2, the speed reference
# add1.u1 = 1.2 (Change_Base.y = 1 >= 0.75), thlim1 = pwlim2 = 1, and every integrator at rest (the pitch loop error
# add2 = omega_gen - integrator1.y = 0, the compensation add4 = 1 - limIntegrator2.y = 0, the torque loop add8 =
# omega_gen (Kptrq 0 + wt_x2_0) - limIntegrator2.y = 1.2 0.8333 - 1 = 0).
@testset "Wind.GE.Type_3.Turbine Turbine_Model" begin
    ini = OpenIPSLComponents.ge_wt_init(1.03, 0.00735136412, 162e6, -37049223.1185345, 180e6, 0.8, 56.6, 25.0, 3.0, 0.6,
        1.11, 0.0, 0.47123889803, 1.0, 1.0, 1, 0.0, 0.0, 0.0, 0.0)
    @test ini.theta ≈ 0.4700000000000003 atol = 1e-15
    @test ini.wndtge_spd0 ≈ 1.2 atol = 1e-15
    @test ini.Vw ≈ 14.0 atol = 1e-12
    @test ini.lambda ≈ 56.6 * 1.2 / 14 atol = 1e-12
    @test ini.wt_x2_0 ≈ 1 / 1.2 atol = 1e-15
    @test ini.wndtge_ang0 ≈ -1 / (1.11 * 1.2) atol = 1e-15
    @named tm = Turbine_Model(; GEN_base = 180e6, WT_base = 162e6, Kpp = 150.0, Kip = 25.0, pirat = 10.0, pimax = 0.47123889803,
        pimin = 0.0, pwrat = 0.45, pwmax = 1.12, pwmin = 0.1, Kic = 30.0, Kpc = 3.0, Tp = 0.3, Tpc = 0.05, Kptrq = 3.0,
        Kitrq = 0.6, Dtg = 1.5, H = 4.33, Hg = 0.62, Ktg = 1.11, KI = 56.6, wndtge_kp = ini.wndtge_kp,
        wt_x0_0 = ini.wt_x0_0, wt_x1_0 = ini.wt_x1_0, wt_x2_0 = ini.wt_x2_0, wt_x3_0 = ini.wt_x3_0, wt_x4_0 = ini.wt_x4_0,
        wt_x5_0 = ini.wt_x5_0, wt_x6_0 = ini.wt_x6_0, wt_x7_0 = ini.wt_x7_0, wt_x8_0 = ini.wt_x8_0, wt_x9_0 = ini.wt_x9_0,
        wbase = 2 * pi * 60 / 3, wndtge_ang0 = ini.wndtge_ang0, wndtge_spd0 = ini.wndtge_spd0)
    @named rig = System(Equation[tm.Pelec ~ 0.9, tm.Wind_Speed ~ 14], t, [], []; systems = [tm])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ[sys.tm.Pord] ≈ 0.9 atol = 1e-9
    @test integ[sys.tm.rotor_Model1.omega_gen] ≈ 1.2 atol = 1e-9
    @test integ[sys.tm.wind_Power_Model1.Pm] ≈ 1.0 atol = 1e-9
    @test integ[sys.tm.limIntegrator1.y] ≈ 0.4700000000000003 atol = 1e-12
    @test integ[sys.tm.add1.u1] ≈ 1.2 atol = 1e-12
    @test integ[sys.tm.thlim1] ≈ 1 atol = 1e-12
    @test integ[sys.tm.pwlim2] ≈ 1 atol = 1e-12
    for s in (sys.tm.integrator1.y, sys.tm.integrator2.y, sys.tm.integrator3.y, sys.tm.integrator4.y,
              sys.tm.limIntegrator1.y, sys.tm.limIntegrator2.y, sys.tm.rotor_Model1.integrator1.y, sys.tm.rotor_Model1.integrator2.y)
        @test abs(initial_derivative(integ, sys, s)) < 1e-9
    end
end
