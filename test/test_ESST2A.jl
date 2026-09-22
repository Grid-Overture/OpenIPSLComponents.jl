# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Controls.PSSE.ES.ESST2A (PLAN-04, phase 5): no OpenIPSL Test instantiates it, so the rig fixes the pins and the
# ports by hand. A FixedVoltageSource on `Bus` (vr = 1, vi = 0) and a CurrentInjection on `Gen_terminal`
# (ir = 0.5, ii = -0.2) give V_T = 1 + 0j, I_T = 0.5 - 0.2j through the pass-through connect; EFD0 = 2.5, ECOMP = 1,
# XADIFD = 2, VOTHSG = VOEL = 0, VUEL = -1 (below the error signal, so the HV gate passes it).
# With the defaults K_P = 0.7, K_I = 1, K_C = 0.03, K_E = 1, K_A = 240:
#   VE  = |0.7 (1 + 0j) + j 1 (0.5 - 0.2j)| = |0.9 + 0.5j| = sqrt(1.06) = 1.0295630140987
#   Ifd0 = 2, IN0 = 0.03 * 2 / VE0 = 0.0582773 <= 0.433 -> VB0 = VE0 (1 - 0.577 IN0) = 0.9949432...
#   VA0 = EFD0 * K_E / VB0 = 2.5127055..., V_REF = ECOMP0 + VA0/K_A = 1.0104696...
# At t = 0 every state is at rest: TransducerDelay (state = ECOMP0, input ECOMP), imDerivativeLag (InitialOutput
# y = 0 -> x = u), simpleLagLim (state = VA0, K_A u = K_A (V_REF - ECOMP) = VA0), integratorLimVar
# (u = product.y - K_E EFD = VA0 VB0 - EFD0 = 0), so the four derivatives are < 1e-9.
# With K_P = K_I = 0 the bypass gives VE = 1, VB0 = 1 (swith_vb passes vB_default), VA0 = 2.5.
# A step of ECOMP from 1 to 0.95 at 0.5 s raises the error V_REF - ECOMP, so EFD(1) > EFD0.
@testset "Controls.PSSE.ES.ESST2A" begin
    VE0 = sqrt(1.06)
    IN0 = 0.03 * 2 / VE0
    VB0 = VE0 * (1 - 0.577 * IN0)
    VA0 = 2.5 / VB0
    VREF = 1 + VA0 / 240
    @named ess = ESST2A()
    @named ess0 = ESST2A(; K_P = 0, K_I = 0)
    @named src = FixedVoltageSource(; vr = 1, vi = 0)
    @named inj = CurrentInjection(; ir = 0.5, ii = -0.2)
    @named src0 = FixedVoltageSource(; vr = 1, vi = 0)
    @named inj0 = CurrentInjection(; ir = 0.5, ii = -0.2)
    @named step = Step(; height = -0.05, startTime = 0.5)
    eqs = Equation[connect(inj.p, ess.Gen_terminal), connect(ess.Bus, src.p),
        ess.EFD0 ~ 2.5, ess.ECOMP ~ 1 + step.y, ess.XADIFD ~ 2, ess.VOTHSG ~ 0, ess.VOEL ~ 0, ess.VUEL ~ -1,
        connect(inj0.p, ess0.Gen_terminal), connect(ess0.Bus, src0.p),
        ess0.EFD0 ~ 2.5, ess0.ECOMP ~ 1, ess0.XADIFD ~ 2, ess0.VOTHSG ~ 0, ess0.VOEL ~ 0, ess0.VUEL ~ -1]
    @named rig = System(eqs, t, [], []; systems = [ess, ess0, src, inj, src0, inj0, step])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 1.0))
    integ = init(prob, Rodas5P(); initializealg = INIT)
    @test integ[sys.ess.VE] ≈ VE0 atol = 1e-9
    @test integ.ps[sys.ess.VB0] ≈ VB0 atol = 1e-9
    @test integ.ps[sys.ess.VA0] ≈ VA0 atol = 1e-9
    @test integ.ps[sys.ess.V_REF] ≈ VREF atol = 1e-9
    @test integ[sys.ess.EFD] ≈ 2.5 atol = 1e-9
    for x in (sys.ess.TransducerDelay.state, sys.ess.imDerivativeLag.x, sys.ess.simpleLagLim.state, sys.ess.integratorLimVar.w)
        @test abs(initial_derivative(integ, sys, x)) < 1e-9
    end
    @test integ[sys.ess0.VE] ≈ 1 atol = 1e-12
    @test integ.ps[sys.ess0.VB0] ≈ 1 atol = 1e-12
    @test integ.ps[sys.ess0.VA0] ≈ 2.5 atol = 1e-9
    sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8, initializealg = INIT)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.4; idxs = sys.ess.EFD) ≈ 2.5 atol = 1e-6
    @test sol(1.0; idxs = sys.ess.EFD) > 2.6
end
