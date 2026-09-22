# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Controls.PSSE.ES.ESURRY (PLAN-04, phase 4): its OpenIPSL Test does not initialize in OpenModelica 1.25 (F-37), so
# the model is checked by hand with the Test's own parameters and given ports: EFD0 = 2, ECOMP = 1, XADIFD = 2,
# VOTHSG = VOEL = VUEL = 0 (the Test feeds VOEL/VUEL with `Constant(k = 0)` named plusInf/minusInf, sic).
# Initialization chain (T_1 = 0.5, T_C = 0.42, T_B = 0.7, T_D = 0.06, T_E = 1.2, K_10 = 97, K_16 = 1.7786, K_D = 0.1,
# K_E = 0.35, E_1 = 1, E_2 = 6, S_EE_1 = 0.02, S_EE_2 = 0.25, V_RMAX = 12, V_RMIN = -7.5, K_C = 0.124, K_F = 0.7115,
# T_F = 2, T_A = 0.574, T_R = 0.035):
#   Ifd0 = 2; K_C Ifd0/(Efd0 + 0.577 K_C Ifd0) = 0.248/2.1431 = 0.1157 <= 0.433 -> VE0 = 2 + 0.577*0.248 = 2.143096
#   SE(VE0; 0.02, 0.25, 1, 6): a = sqrt(0.02/1.5) = 0.115470, A = 6 - (1 - 6)/(a - 1) = 0.347296,
#     B = 1.5 (a - 1)^2/25 = 0.046944, SE = B (VE0 - A)^2/VE0 = 0.070640
#   VFE0 = VE0 (SE + K_E) + Ifd0 K_D = 2.143096*0.420640 + 0.2 = 1.101474; VR0 = VFE0; I_REF = K_16 VFE0 = 1.959082
#   V_REF = (VR0 - (I_REF - K_16 VFE0))/K_10 + ECOMP0 = VFE0/97 + 1 = 1.011355
#   (the numbers are recomputed below with the package's own invFEX and SE)
# At t = 0 the seven states are at rest (simpleLag, simpleLag1, the two lead-lags, the exciter integrator with
# I_C = VFE0 within +-(12, -7.5), the washout with y = 0), so every derivative of the rig is < 1e-9. A step of ECOMP from 1
# to 0.95 at 0.5 s raises the error, so EFD(1.5) > EFD0.
@testset "Controls.PSSE.ES.ESURRY" begin
    p = (; T_1 = 0.5, T_C = 0.42, T_B = 0.7, T_D = 0.06, T_E = 1.2, K_10 = 97, K_16 = 1.7786, K_D = 0.1, K_E = 0.35, E_1 = 1,
        E_2 = 6, S_EE_1 = 0.02, S_EE_2 = 0.25, V_RMAX = 12, V_RMIN = -7.5, K_C = 0.1240, K_F = 0.7115, T_F = 2, T_A = 0.574,
        T_R = 0.035)
    VE0 = OpenIPSLComponents.invFEX(p.K_C, 2.0, 2.0)
    @test VE0 ≈ 2 + 0.577 * 0.248 atol = 1e-12
    VFE0 = VE0 * (OpenIPSLComponents.SE(VE0, p.S_EE_1, p.S_EE_2, p.E_1, p.E_2) + p.K_E) + 2.0 * p.K_D
    I_REF = p.K_16 * VFE0
    VREF = VFE0 / p.K_10 + 1
    @named ess = ESURRY(; p...)
    @named step = Step(; height = -0.05, startTime = 0.5)
    eqs = Equation[ess.EFD0 ~ 2, ess.ECOMP ~ 1 + step.y, ess.XADIFD ~ 2, ess.VOTHSG ~ 0, ess.VOEL ~ 0, ess.VUEL ~ 0]
    @named rig = System(eqs, t, [], []; systems = [ess, step])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 1.5))
    integ = init(prob, Rodas5P(); initializealg = INIT)
    @test integ.ps[sys.ess.Ifd0] ≈ 2 atol = 1e-9
    @test integ.ps[sys.ess.VE0] ≈ VE0 atol = 1e-9
    @test integ.ps[sys.ess.VFE0] ≈ VFE0 atol = 1e-9
    @test integ.ps[sys.ess.VR0] ≈ VFE0 atol = 1e-9
    @test integ.ps[sys.ess.I_REF] ≈ I_REF atol = 1e-9
    @test integ.ps[sys.ess.V_REF] ≈ VREF atol = 1e-9
    @test integ[sys.ess.EFD] ≈ 2 atol = 1e-9
    du = similar(integ.u)   # every state of the rig belongs to the exciter: all derivatives vanish at t = 0
    integ.f(du, integ.u, integ.p, integ.t)
    @test maximum(abs.(du)) < 1e-9
    sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8, initializealg = INIT)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.4; idxs = sys.ess.EFD) ≈ 2 atol = 1e-6
    @test sol(1.5; idxs = sys.ess.EFD) > 2.05
end
