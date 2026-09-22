# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# FieldCurrent has no upstream Test of its own (OEL instantiates it and Tests.Controls.PSAT.OEL.AVRTypeII_OEL_Test
# exercises it through OEL). Two hand-computed points on the .mo's three equations:
#   gamma_p = xq*p/v, gamma_q = xq*q/v
#   ifield  = sqrt((v + gamma_q)^2 + p^2) + (xd/xq - 1)*(gamma_q*(v + gamma_q) + gamma_p^2)/sqrt((v + gamma_q)^2 + p^2)
# 1. a closed point, xd = xq = 1.5: the second term vanishes and ifield = sqrt((v + gamma_q)^2 + p^2).
#    v = 1, p = 0.8, q = 0.6 -> gamma_q = 1.5*0.6/1 = 0.9, ifield = sqrt(1.9^2 + 0.8^2) = sqrt(4.25) = 2.0615528128088303.
# 2. a numeric point with the reactances of the OEL Test scaled to the system base, xd = 1.9*Z, xq = 1.7*Z with
#    Z = (100e6*370e3^2)/(20e6*400e3^2) = 4.278125: xd = 8.1284375, xq = 7.2728125.
#    v = 1.02, p = 0.16, q = 0.12 -> gamma_p = 7.2728125*0.16/1.02 = 1.1408333333333334,
#    gamma_q = 7.2728125*0.12/1.02 = 0.855625, r = sqrt((1.02 + 0.855625)^2 + 0.16^2) = sqrt(3.5443398056640625)
#    = 1.882640656..., ifield = r + (8.1284375/7.2728125 - 1)*(0.855625*1.875625 + 1.1408333333333334^2)/r.
@testset "FieldCurrent" begin
    # 1
    @named fc1 = FieldCurrent(; xd = 1.5, xq = 1.5)
    @named rig1 = System(Equation[fc1.v ~ 1.0, fc1.p ~ 0.8, fc1.q ~ 0.6], t, [], []; systems = [fc1])
    sys1 = mtkcompile(rig1)
    integ1 = init(ODEProblem(sys1, [], (0.0, 1.0)), Rodas5P())
    @test integ1[sys1.fc1.gamma_q] ≈ 0.9 atol = 1e-12
    @test integ1[sys1.fc1.gamma_p] ≈ 1.2 atol = 1e-12
    @test integ1[sys1.fc1.ifield] ≈ sqrt(4.25) atol = 1e-12

    # 2
    Z = (100e6 * 370e3^2) / (20e6 * 400e3^2)
    xd, xq = 1.9 * Z, 1.7 * Z
    v, p, q = 1.02, 0.16, 0.12
    gp, gq = xq * p / v, xq * q / v
    r = sqrt((v + gq)^2 + p^2)
    want = r + (xd / xq - 1) * (gq * (v + gq) + gp^2) / r
    @named fc2 = FieldCurrent(; xd, xq)
    @named rig2 = System(Equation[fc2.v ~ v, fc2.p ~ p, fc2.q ~ q], t, [], []; systems = [fc2])
    sys2 = mtkcompile(rig2)
    integ2 = init(ODEProblem(sys2, [], (0.0, 1.0)), Rodas5P())
    @test integ2[sys2.fc2.gamma_p] ≈ gp atol = 1e-9
    @test integ2[sys2.fc2.gamma_q] ≈ gq atol = 1e-9
    @test integ2[sys2.fc2.ifield] ≈ want atol = 1e-9
    @test Z ≈ 4.278125 atol = 1e-12   # the Test's Z_MBtoSB
end
