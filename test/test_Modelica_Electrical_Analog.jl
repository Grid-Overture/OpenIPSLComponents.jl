# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Mini-MSL Modelica.Electrical.Analog (PLAN-07, batch 7): the analog subset VSD.AC2DCandDC2AC needs.
# `Pin` is the port's second acausal connector (v potential, i flow) and `OnePort` the partial base the two-pin
# components extend; the tests are the closed-form RC and RL responses, an ohmic drop driven by `SignalCurrent`,
# and the ideal switch's two modes with its crossing event (F-61).
# Arithmetic in each @testset's comment; 1e-9 on algebraic values, 1e-7 on integrated ones.

# RC: SignalVoltage(v = V) - Resistor(R) - Capacitor(C, v(0) = 0) - Ground.
# v_C(t) = V*(1 - exp(-t/(R*C))), i(t) = (V/R)*exp(-t/(R*C)).  V = 10, R = 100, C = 1e-3 -> tau = 0.1 s:
# v_C(0.1) = 10*(1 - e^-1) = 6.321205588285577,  v_C(0.3) = 10*(1 - e^-3) = 9.502129316321360,
# i(0)     = 0.1,          i(0.1) = 0.1*e^-1 = 0.036787944117144235.
@testset "Modelica.Electrical.Analog RC" begin
    @named src = SignalVoltage()
    @named res = Resistor(; R = 100.0)
    @named cap = Capacitor(; C = 1e-3, v_start = 0.0, v_fixed = true)
    @named gnd = Ground()
    @named rig = System(Equation[
            connect(src.p, res.p),
            connect(res.n, cap.p),
            connect(cap.n, src.n),
            connect(gnd.p, cap.n),
            src.v ~ 10.0,
        ], t, [], []; systems = [src, res, cap, gnd])
    sys = mtkcompile(rig)
    @test length(unknowns(sys)) == 1          # one state: the capacitor voltage
    sol = solve(ODEProblem(sys, [], (0.0, 0.3)), Rodas5P(); abstol = 1e-12, reltol = 1e-12)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.0; idxs = sys.cap.v) ≈ 0.0 atol = 1e-9
    @test sol(0.1; idxs = sys.cap.v) ≈ 6.321205588285577 atol = 1e-7
    @test sol(0.3; idxs = sys.cap.v) ≈ 9.502129316321360 atol = 1e-7
    @test sol(0.0; idxs = sys.res.i) ≈ 0.1 atol = 1e-9
    @test sol(0.1; idxs = sys.res.i) ≈ 0.036787944117144235 atol = 1e-9
    # OnePort's own three equations, on the resistor: v = p.v - n.v, 0 = p.i + n.i, i = p.i
    @test sol(0.1; idxs = sys.res.v) ≈ 100 * 0.036787944117144235 atol = 1e-7
    @test sol(0.1; idxs = sys.res.p.i) + sol(0.1; idxs = sys.res.n.i) ≈ 0.0 atol = 1e-12
end

# RL: SignalVoltage(v = V) - Resistor(R) - Inductor(L, i(0) = 0) - Ground.
# i(t) = (V/R)*(1 - exp(-t*R/L)).  V = 10, R = 100, L = 10 -> tau = L/R = 0.1 s:
# i(0.1) = 0.1*(1 - e^-1) = 0.06321205588285577,  i(0.3) = 0.1*(1 - e^-3) = 0.09502129316321360.
# The inductor's start value is a guess, so it is handed in as the problem's u0 (rule 6.2).
@testset "Modelica.Electrical.Analog RL" begin
    @named src = SignalVoltage()
    @named res = Resistor(; R = 100.0)
    @named ind = Inductor(; L = 10.0, i_start = 0.0)
    @named gnd = Ground()
    @named rig = System(Equation[
            connect(src.p, res.p),
            connect(res.n, ind.p),
            connect(ind.n, src.n),
            connect(gnd.p, ind.n),
            src.v ~ 10.0,
        ], t, [], []; systems = [src, res, ind, gnd])
    sys = mtkcompile(rig)
    @test length(unknowns(sys)) == 1          # one state: the inductor current
    sol = solve(ODEProblem(sys, [sys.ind.i => 0.0], (0.0, 0.3)), Rodas5P(); abstol = 1e-12, reltol = 1e-12)
    @test sol.retcode == ReturnCode.Success
    @test sol(0.0; idxs = sys.ind.i) ≈ 0.0 atol = 1e-9
    @test sol(0.1; idxs = sys.ind.i) ≈ 0.06321205588285577 atol = 1e-8
    @test sol(0.3; idxs = sys.ind.i) ≈ 0.09502129316321360 atol = 1e-8
    @test sol(0.1; idxs = sys.ind.v) ≈ 10.0 - 100 * 0.06321205588285577 atol = 1e-6
end

# SignalCurrent on a resistor: SignalCurrent(i = I) - Resistor(R) - Ground. Purely algebraic.
# MSL's sign convention: `i` is the current flowing through the source from its p to its n, so it leaves at n and
# returns through the external circuit into p. With `isrc.p` wired to `res.p` and `isrc.n` to `res.n` (grounded),
# `res.p.i = -isrc.i`, i.e. the resistor carries -I. I = 0.25, R = 40 -> res.i = -0.25 and res.v = -10.
@testset "Modelica.Electrical.Analog SignalCurrent" begin
    @named isrc = SignalCurrent()
    @named res = Resistor(; R = 40.0)
    @named gnd = Ground()
    @named rig = System(Equation[
            connect(isrc.p, res.p),
            connect(res.n, isrc.n),
            connect(gnd.p, isrc.n),
            isrc.i ~ 0.25,
        ], t, [], []; systems = [isrc, res, gnd])
    sys = mtkcompile(rig)
    integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
    @test integ[sys.res.i] ≈ -0.25 atol = 1e-9
    @test integ[sys.res.v] ≈ -10.0 atol = 1e-9
    @test integ[sys.isrc.v] ≈ -10.0 atol = 1e-9
    @test integ[sys.isrc.i] ≈ 0.25 atol = 1e-9        # the source's own variable keeps the driven value
end

# IdealOpeningSwitch, the two modes and the crossing event (F-61).
# SignalVoltage(v = Vs(t)) - Resistor(R = 1) - switch - Ground, with the switch's own drop as the condition.
# Vs = 10 - 40*t over [0, 0.5]: the source reverses at t = 0.25 s.
#   closed (off = 0): the loop is R + Ron, i = Vs/(R + Ron) ~ Vs/1.00001, switch.v = Ron*i.
#   open   (off = 1): i = Goff*switch.v with switch.v = Vs - R*i, so i = Goff*Vs/(1 + Goff*R) ~ 1e-5*Vs.
# At t = 0.1: Vs = 6, i = 6/1.00001 = 5.99994000059999...; at t = 0.4: Vs = -6, i = -6e-5/(1 + 1e-5) = -5.99994e-5.
@testset "Modelica.Electrical.Analog IdealOpeningSwitch" begin
    @named src = SignalVoltage()
    @named res = Resistor(; R = 1.0)
    @named gnd = Ground()
    sw = IdealOpeningSwitch(; name = :sw, Ron = 1e-5, Goff = 1e-5)
    @named rig = System(Equation[
            connect(src.p, res.p),
            connect(res.n, sw.p),
            connect(sw.n, src.n),
            connect(gnd.p, sw.n),
            sw.control ~ sw.v,          # the switch's own drop drives its event (see IdealOpeningSwitch.jl)
            src.v ~ 10.0 - 40.0 * t,
        ], t, [], []; systems = [src, res, gnd, sw])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 0.5)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
    @test sol.retcode == ReturnCode.Success
    # closed before the reversal, open after it: the event is located at the source's zero crossing to 1e-3.
    # `off` is read by interpolation, not from `sol[...]`: it is a discrete parameter and its saved series is
    # indexed by the solver's own steps, of which a system with no differential state takes very few (F-13).
    @test sol(0.1; idxs = sys.sw.off) ≈ 0.0 atol = 1e-12
    @test sol(0.249; idxs = sys.sw.off) ≈ 0.0 atol = 1e-12
    @test sol(0.251; idxs = sys.sw.off) ≈ 1.0 atol = 1e-12
    @test sol(0.4; idxs = sys.sw.off) ≈ 1.0 atol = 1e-12
    # the two branches, to the closed form
    @test sol(0.1; idxs = sys.res.i) ≈ 6.0 / 1.00001 atol = 1e-9
    @test sol(0.1; idxs = sys.sw.v) ≈ 1e-5 * 6.0 / 1.00001 atol = 1e-9
    @test sol(0.4; idxs = sys.res.i) ≈ -6e-5 / (1 + 1e-5) atol = 1e-9
    @test sol(0.4; idxs = sys.sw.v) ≈ -6.0 / (1 + 1e-5) atol = 1e-9
end
