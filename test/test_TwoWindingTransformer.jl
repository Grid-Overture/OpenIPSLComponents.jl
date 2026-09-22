# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Transformer between two fixed sources, m = 1 and V_b = Vn, S_b = Sn (so r = rT, x = xT):
#   (r + jx)*(p.ir + j p.ii) = vs - vr   and   (r + jx)*(n.ir + j n.ii) = vr - vs.
# With r = 0.005, x = 0.1, vs = 1, vr = 0.95 - 0.05j: ip = (0.05 + 0.05j)/(0.005 + 0.1j), in = -ip.
# The base change is checked on a second instance with Vn = 2 V_b: Zn/Zb = 4, so x = 4 xT.
@testset "TwoWindingTransformer" begin
    rT, xT = 0.005, 0.1
    vs = 1.0 + 0.0im
    vr = 0.95 - 0.05im
    ip_expected = (vs - vr) / complex(rT, xT)
    @test ip_expected ≈ 0.52369077306733 - 0.47381546134663im rtol = 1e-12

    @named src_s = FixedVoltageSource(; vr = real(vs), vi = imag(vs))
    @named src_r = FixedVoltageSource(; vr = real(vr), vi = imag(vr))
    @named T = TwoWindingTransformer(; V_b = 16500, Vn = 16500, rT = rT, xT = xT)
    @named rig = System(Equation[connect(src_s.p, T.p), connect(src_r.p, T.n)], t, [], [];
        systems = [src_s, src_r, T])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 1.0))
    integ = init(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)   # runs the DAE initialization
    @test integ.ps[sys.T.r] ≈ rT
    @test integ.ps[sys.T.x] ≈ xT
    @test integ[sys.T.p.ir] ≈ real(ip_expected) atol = 1e-9
    @test integ[sys.T.p.ii] ≈ imag(ip_expected) atol = 1e-9
    @test integ[sys.T.n.ir] ≈ -real(ip_expected) atol = 1e-9
    @test integ[sys.T.n.ii] ≈ -imag(ip_expected) atol = 1e-9

    @named T2 = TwoWindingTransformer(; V_b = 16500, Vn = 33000, rT = rT, xT = xT)
    @test ModelingToolkit.getdefault(T2.x) ≈ 4 * xT
    @test ModelingToolkit.getdefault(T2.r) ≈ 4 * rT
end
