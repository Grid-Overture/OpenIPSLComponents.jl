# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Pi line between two fixed sources. From the complex pi-model equations,
#   is = (vs - vr)/Z + vs*Y  and  ir = (vr - vs)/Z + vr*Y,   Z = R + jX, Y = G + jB.
# With Z = 0.02 + 0.1j, Y = 0.01 + 0.05j, vs = 1, vr = 0.95 - 0.05j:
#   (vs - vr)/Z = (0.05 + 0.05j)/(0.02 + 0.1j) = (0.006 - 0.004j)/0.0104 = 0.576923... - 0.384615...j
#   is = 0.586923076923077 - 0.334615384615385j,  ir = -0.564923076923077 + 0.431615384615385j
@testset "PwLine" begin
    R, X, G, B = 0.02, 0.1, 0.01, 0.05
    vs = 1.0 + 0.0im
    vr = 0.95 - 0.05im
    Z = complex(R, X)
    Y = complex(G, B)
    is_expected = (vs - vr) / Z + vs * Y
    ir_expected = (vr - vs) / Z + vr * Y
    @test is_expected ≈ 0.586923076923077 - 0.334615384615385im
    @test ir_expected ≈ -0.564923076923077 + 0.431615384615385im

    @named src_s = FixedVoltageSource(; vr = real(vs), vi = imag(vs))
    @named src_r = FixedVoltageSource(; vr = real(vr), vi = imag(vr))
    @named line = PwLine(; R = R, X = X, G = G, B = B)
    @named rig = System(Equation[connect(src_s.p, line.p), connect(src_r.p, line.n)], t, [], [];
        systems = [src_s, src_r, line])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 1.0))
    integ = init(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)   # runs the DAE initialization
    @test integ[sys.line.p.ir] ≈ real(is_expected) atol = 1e-9
    @test integ[sys.line.p.ii] ≈ imag(is_expected) atol = 1e-9
    @test integ[sys.line.n.ir] ≈ real(ir_expected) atol = 1e-9
    @test integ[sys.line.n.ii] ≈ imag(ir_expected) atol = 1e-9
end
