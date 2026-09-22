# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Interfaces and pfComponent (PLAN-02).
# PwPin_p/PwPin_n are PwPin: the same four variables. pfComponent: parameters with their defaults or the given values.
# Generator: with pwPin at vr = 1, vi = 0 (FixedVoltageSource) and an imposed pin current ir = 0.5, ii = -0.2 (into
# the generator, PwPin sign convention), -P = (1*0.5 + 0*(-0.2))*S_b -> P = -5e7 W; -Q = (0*0.5 - 1*(-0.2))*S_b ->
# Q = -2e7 var (S_b = 1e8).
@testset "Interfaces" begin
    @named pp = PwPin_p()
    @named pn = PwPin_n()
    @test sort(string.(ModelingToolkit.getname.(unknowns(pp)))) == ["ii", "ir", "vi", "vr"]
    @test sort(string.(ModelingToolkit.getname.(unknowns(pn)))) == ["ii", "ir", "vi", "vr"]

    @named pf = pfComponent(; S_b = 50e6, P_0 = 2)
    @test ModelingToolkit.getdefault(pf.S_b) == 50e6
    @test ModelingToolkit.getdefault(pf.P_0) == 2.0
    @test ModelingToolkit.getdefault(pf.V_b) == 400e3
    @test ModelingToolkit.getdefault(pf.fn) == 50.0

    @named g = Generator(; S_b = 1e8)
    @named src = FixedVoltageSource(; vr = 1.0, vi = 0.0)
    @named rig = System(Equation[connect(g.pwPin, src.p), g.pwPin.ir ~ 0.5, g.pwPin.ii ~ -0.2], t, [], [];
        systems = [g, src])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.g.P] ≈ -5e7 atol = 1e-9 * 1e8
    @test integ[sys.g.Q] ≈ -2e7 atol = 1e-9 * 1e8
    @test integ[sys.src.p.ir] ≈ -0.5 atol = 1e-9
end
