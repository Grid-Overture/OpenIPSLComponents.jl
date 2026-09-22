# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Bus fed by a fixed source at 0.95 pu, 0.1 rad: v = 0.95, angle = 0.1, and the bus draws no current.
@testset "Bus" begin
    @named src = FixedVoltageSource(; vr = 0.95 * cos(0.1), vi = 0.95 * sin(0.1))
    @named B = Bus(; v_0 = 1.0, angle_0 = 0.0)
    @named rig = System(Equation[connect(src.p, B.p)], t, [], []; systems = [src, B])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 1.0))
    integ = init(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)   # runs the DAE initialization
    @test integ[sys.B.v] ≈ 0.95 atol = 1e-9
    @test integ[sys.B.angle] ≈ 0.1 atol = 1e-9
    @test integ[sys.B.p.ir] ≈ 0 atol = 1e-9
    @test integ[sys.B.p.ii] ≈ 0 atol = 1e-9
    @test integ[sys.src.p.ir] ≈ 0 atol = 1e-9
end
