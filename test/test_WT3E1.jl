# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# WT3E1 (batch 12) has a Test of this port's own on the WT4G1 network (Tests/Wind/PSSE/WT3G/WT3E1.jl), and that
# Test takes one value of each flag: VARFLG = 1 (reactive power control) and VLRFLG = 1 (terminal voltage control).
# The other values select branches of the model's two parameter `if`s, which Modelica evaluates at translation
# time and the port decides in Julia (F-22), so each one is a different compiled model and no single Test can
# reach them. They are checked here on the control alone, driven by constant inputs.
#
#   VLRFLG != 0  ->  WEQCMD = K7.y   (the LimIntegrator of the terminal-voltage loop)
#   VLRFLG == 0  ->  WEQCMD = Vcl.y  (the voltage-closed-loop feedback, bypassing K7)
#   VARFLG ==  1 ->  Qord.u = reactivePowerControl.Q_ord
#   VARFLG == -1 ->  Qord.u = pf_Controller1.Q_REF_PF
#   otherwise    ->  Qord.u = Qref = q0   (constant Q)
#
# With the inputs held at the model's own declared point (PELEC = p0, VTERM = v0, Qelec = q0, ITERM = 0) and the
# two initial-value inputs at the generator's, every state starts at its own y_start, so the branch that is active
# is visible at t = 0 in `Qord.u` and in `WEQCMD` with no dynamics in the way:
#   Qord.u with VARFLG = 0 is exactly q0; with VARFLG = -1 it is tan(PFA_ref)*K0.y = tan(atan2(q0, p0))*p0 = q0
#   as well (the power-factor regulator is at its own reference), so the two are told apart by the block each one
#   goes through, and `pf_Controller1.Q_REF_PF` must exist and carry q0 in the -1 case.
#   WEQCMD with VLRFLG = 0 is Vcl.y = K6.y - VTERM, and K6 starts at k60 = v0, so it is exactly 0.
@testset "WT3E1 flags" begin
    v0, p0, q0 = 0.9999999, 0.015, -0.056658
    eqcmd0, ipcmd0 = -0.1, 0.02      # stand-ins for WT3G1's two parameter-valued outputs
    function drive(; VARFLG, VLRFLG)
        @named c = WT3E1(; VARFLG, VLRFLG, Vref = 1.0, v0, p0, q0)
        eqs = Equation[c.PELEC ~ p0, c.VTERM ~ v0, c.Qelec ~ q0, c.ITERM ~ 0.0,
            c.WEQCMD0 ~ eqcmd0, c.WIPCMD0 ~ ipcmd0]
        @named rig = System(eqs, t, [], []; systems = [c])
        sys = mtkcompile(rig)
        init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); initializealg = INIT), sys
    end

    # VLRFLG = 1 (the Test's own branch): WEQCMD is K7's output, which starts at k70 = WEQCMD0
    i1, s1 = drive(; VARFLG = 1, VLRFLG = 1)
    @test isapprox(i1[s1.c.WEQCMD], eqcmd0; atol = 1e-9)
    @test isapprox(i1[s1.c.K7.y], eqcmd0; atol = 1e-9)

    # VLRFLG = 0: WEQCMD bypasses K7 and is Vcl.y = K6.y - VTERM, with K6 starting at k60 = v0
    i2, s2 = drive(; VARFLG = 1, VLRFLG = 0)
    @test isapprox(i2[s2.c.WEQCMD], 0.0; atol = 1e-9)
    @test isapprox(i2[s2.c.K6.y], v0; atol = 1e-9)

    # VARFLG = -1: the power-factor regulator feeds the Mvar order, and at the declared point it asks for q0
    i3, s3 = drive(; VARFLG = -1, VLRFLG = 1)
    @test isapprox(i3[s3.c.pf_Controller1.Q_REF_PF], q0; atol = 1e-9)
    @test isapprox(i3[s3.c.Qord.u], q0; atol = 1e-9)

    # VARFLG = 0 (anything but +/-1): the Mvar order is the constant Qref = q0
    i4, s4 = drive(; VARFLG = 0, VLRFLG = 1)
    @test isapprox(i4[s4.c.Qord.u], q0; atol = 1e-12)

    # the shaft-speed characteristic, the model's own `Speed` function, at the points that define it (PMN = 0.1,
    # Pmin = 0.74 and the defaults wPmin = 0.69, wP20 = 0.78, wP40 = 0.98, wP60 = 1.12, wP100 = 1.2). Below PMN it
    # is flat at wmin - 1 and above Pmin flat at w100 - 1, and the three interior nodes are the declared speeds -
    # except the first, because the .mo's second branch reads `x > Pmin and x <= 0.2` where every other branch
    # reads a lower bound of its own segment: with Pmin = 0.74 that condition is empty, the segment from PMN to
    # 0.2 is dead, and any power in it falls through to the last branch and comes out at w100 instead (F-94).
    # That is reproduced, not fixed, so sp(0.2) is 0.2 and not wP20 - 1 = -0.22.
    sp(x) = WT3E1_Speed(x, 0.1, 0.69, 0.78, 0.98, 1.12, 1.2, 0.74)
    @test sp(0.05) ≈ 0.69 - 1 atol = 1e-12       # x <= PMN: flat at wmin
    @test sp(0.2) ≈ 1.2 - 1 atol = 1e-12         # the dead segment: w100, not wP20
    @test sp(0.15) ≈ 1.2 - 1 atol = 1e-12        # idem, in the middle of it
    @test sp(0.4) ≈ 0.98 - 1 atol = 1e-12        # node wP40
    @test sp(0.6) ≈ 1.12 - 1 atol = 1e-12        # node wP60
    @test sp(0.3) ≈ (0.98 - 0.78) / 0.2 * 0.1 + 0.78 - 1 atol = 1e-12   # halfway up the 0.2-0.4 ramp
    @test sp(0.9) ≈ 1.2 - 1 atol = 1e-12         # x > Pmin: flat at w100
end
