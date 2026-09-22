# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Voltage-dependent load at 0.95 pu, 0.1 rad with v_0 = 1, P_0 = 0.5 S_b, Q_0 = 0.2 S_b, alphap = alphaq = 2:
#   a = 0.95, P = 0.5*0.95^2 = 0.45125, Q = 0.2*0.95^2 = 0.1805 (pu, absorbed),
#   and from P = vr ir + vi ii, Q = vi ir - vr ii:  ir + j ii = conj((P + jQ)/V).
@testset "VoltageDependent" begin
    S_b = 100e6
    V = 0.95 * cis(0.1)
    P_expected = 0.5 * 0.95^2
    Q_expected = 0.2 * 0.95^2
    I_expected = conj(complex(P_expected, Q_expected) / V)

    @named src = FixedVoltageSource(; vr = real(V), vi = imag(V))
    @named load = VoltageDependent(; V_b = 230000, P_0 = 0.5 * S_b, Q_0 = 0.2 * S_b, v_0 = 1.0, angle_0 = 0.0, Sn = S_b)
    @named rig = System(Equation[connect(src.p, load.p)], t, [], []; systems = [src, load])
    sys = mtkcompile(rig)
    prob = ODEProblem(sys, [], (0.0, 1.0))
    integ = init(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)   # runs the DAE initialization
    @test integ[sys.load.v] ≈ 0.95 atol = 1e-9
    @test integ[sys.load.anglev] ≈ 0.1 atol = 1e-9
    @test integ[sys.load.P] ≈ P_expected atol = 1e-9
    @test integ[sys.load.Q] ≈ Q_expected atol = 1e-9
    @test integ[sys.load.p.ir] ≈ real(I_expected) atol = 1e-9
    @test integ[sys.load.p.ii] ≈ imag(I_expected) atol = 1e-9
end
