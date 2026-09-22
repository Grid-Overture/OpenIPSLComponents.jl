# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PSSE TwoWindingTransformer (PLAN-02): its OpenIPSL Test instantiates GENSAL (batch 3), so a hand test at t = 0 with the
# parameters of Tests.Branches.PSSE.TwoWindingTransformer plus a magnetizing branch: pin p on a fixed voltage ei = 1
# and ij = 0.3 + 0.1j injected into pin n. The .mo relations, in complex form (CW = 3: T1 = t1 VNOM1/VB1,
# T2 = t2 VNOM2/VB2, t = T1/T2 (cos ANG1 + j sin ANG1), Ym = G + jB, xeq = (r + jx)|T2|^2, r = R, x = X for CZ = 1):
#   ij = -(ii - ei Ym) conj(t)  ->  ii = ei Ym - ij/conj(t);   ej = ei/t + xeq ij.
@testset "PSSE TwoWindingTransformer" begin
    R, X, G, B = 0.001, 0.2, 0.01, 0.02
    t1, VNOM1, VB1, t2, VNOM2, VB2, ANG1 = 0.8085, 20000.0, 14700.0, 1.02, 130000.0, 130000.0, 0.017453292519943
    T1, T2 = t1 * VNOM1 / VB1, t2 * VNOM2 / VB2
    tc = T1 / T2 * cis(ANG1)
    Ym, xeq = complex(G, B), complex(R, X) * abs(T2)^2
    ei, ij = complex(1.0, 0.0), complex(0.3, 0.1)
    ii = ei * Ym - ij / conj(tc)
    ej = ei / tc + xeq * ij
    @named src = FixedVoltageSource(; vr = 1.0, vi = 0.0)
    @named tw = PSSE_TwoWindingTransformer(; S_b = 100e6, CZ = 1, R, X, G, B, S_n = 1e6, ANG1, VB1, VB2, t1, VNOM1, t2, VNOM2, CW = 3)
    @named inj = CurrentInjection(; ir = 0.3, ii = 0.1)
    @named rig = System(Equation[connect(src.p, tw.p), connect(tw.n, inj.p)], t, [], []; systems = [src, tw, inj])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT)
    @test integ[sys.tw.n.ir] ≈ 0.3 atol = 1e-9
    @test integ[sys.tw.n.ii] ≈ 0.1 atol = 1e-9
    @test integ[sys.tw.p.ir] ≈ real(ii) atol = 1e-9
    @test integ[sys.tw.p.ii] ≈ imag(ii) atol = 1e-9
    @test integ[sys.tw.n.vr] ≈ real(ej) atol = 1e-9
    @test integ[sys.tw.n.vi] ≈ imag(ej) atol = 1e-9
    @test integ.ps[sys.tw.T1] ≈ T1 atol = 1e-12
    @test integ.ps[sys.tw.T2] ≈ T2 atol = 1e-12
end
