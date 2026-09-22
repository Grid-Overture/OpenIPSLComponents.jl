# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Electrical.Wind.PSSE.Submodels (PLAN-08, batch 8): Wind_LVPL, LVACL, HVRCL, CCL. None has an upstream Test of its
# own; WT4G1 (which instantiates the first three) is exercised by Tests.Wind.PSSE.WT4G.WT4G1 against its oracle and
# WT4E1 (CCL) by test_WT4E1.jl.

# Wind_LVPL(VLVPL1 = 0.4, VLVPL2 = 0.9, GLVPL = 1.11), K = 1.11/0.5 = 2.22: Vt = 0.3 -> 0; 0.65 -> 2.22 0.25 = 0.555;
# 0.95 -> 1e6 (sic, not GLVPL). LVACL (thresholds 0.4 / 0.8 hard-coded) with Ip_LVPL = 1: Vt = 0.3 -> 0; 0.39 -> 0;
# 0.41 -> 1.25 0.41 = 0.5125 (the discontinuity at 0.4, sic); 0.6 -> 0.75; 0.8 -> 1; 0.9 -> 1. HVRCL(VHVRCR = 1.2,
# CurHVRCR = 2) with Iq = 0.3: Vt = 1.0 -> 0.3; 1.3 -> 2 (the constant itself, sic). HVRCL's relation is a discrete
# that starts at 0 and is updated at the crossings of Vt (F-78): a constant Vt = 1.3 gives 0.3 at t = 0 and 2 after
# the first step (the discrete fallback), and a Vt ramping from 1 to 1.4 over 1 s switches at t = 0.5 exactly.
@testset "Wind.PSSE.Submodels Wind_LVPL, LVACL, HVRCL" begin
    for (vt, lvpl, lvacl, hvrcl) in ((0.3, 0.0, 0.0, 0.3), (0.39, 0.0, 0.0, 0.3), (0.41, 2.22 * 0.01, 0.5125, 0.3),
                                     (0.65, 0.555, 0.8125, 0.3), (0.8, 2.22 * 0.4, 1.0, 0.3), (0.95, 1e6, 1.0, 0.3), (1.3, 1e6, 1.0, 2.0))
        @named lv = Wind_LVPL(; VLVPL1 = 0.4, VLVPL2 = 0.9, GLVPL = 1.11)
        @named la = LVACL()
        @named hv = HVRCL(; VHVRCR = 1.2, CurHVRCR = 2)
        @variables x(t) = 0.0   # a continuous state, so that HVRCL's continuous event has something to root on
        @named rig = System(Equation[lv.Vt ~ vt, la.Vt ~ vt, la.Ip_LVPL ~ 1, hv.Vt ~ vt, hv.Iq ~ 0.3, D_nounits(x) ~ 1], t, [x], []; systems = [lv, la, hv])
        sys = mtkcompile(rig)
        sol = solve(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
        @test sol(0.0; idxs = sys.lv.LVPL) ≈ lvpl atol = 1e-9
        @test sol(0.0; idxs = sys.la.Ip_LVACL) ≈ lvacl atol = 1e-9
        @test sol(0.0; idxs = sys.hv.Iq_HVRCL) ≈ 0.3 atol = 1e-9    # hv starts at 0 whatever Vt is
        @test sol(1.0; idxs = sys.hv.Iq_HVRCL) ≈ hvrcl atol = 1e-9  # ... and follows Vt from the first step on
    end
    @named hv = HVRCL(; VHVRCR = 1.2, CurHVRCR = 2)
    @variables x(t) = 0.0
    @named rig = System(Equation[hv.Vt ~ 1 + 0.4 * t, hv.Iq ~ 0.3, D_nounits(x) ~ 1], t, [x], []; systems = [hv])
    sys = mtkcompile(rig)
    sol = solve(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P(); saveat = 0.1)
    @test sol(0.49; idxs = sys.hv.Iq_HVRCL) ≈ 0.3 atol = 1e-9
    @test sol(0.51; idxs = sys.hv.Iq_HVRCL) ≈ 2.0 atol = 1e-9
    @test count(tk -> abs(tk - 0.5) < 1e-6, sol.t) >= 1   # the crossing was located, not stepped over
end

# CCL(Qmax = 0.48, ImaxTD = 1.7, Iphl = 1.11, Iqhl = 1.11) with Vt = 0.9: Iqmax = (0.48 - 1.6)(0.9 - 1) + 0.48 = 0.592,
# min5 = min(Iqhl, Iqmax) = 0.592. (IpCMD, IqCMD) = (1.65, 1.6): Available_remain1 = sqrt(2.89 - 2.7225) =
# 0.4092676385936225, Available_remain2 = sqrt(2.89 - 2.56) = 0.5744562646538022.
#   pqflag = true (P priority): IPmax = min(Iphl, ImaxTD) = 1.11, IQmax = min(A1, min5) = 0.4092676385936225, IQmin =
#   -IQmax; pqflag = false (Q priority, the WT4E1 Test): IQmax = min(min5, ImaxTD) = 0.592, IQmin = -0.592, IPmax =
#   min(A2, Iphl) = 0.5744562646538022. Both branches of blocks exist in both cases (min1..min5, gain, gain1).
@testset "Wind.PSSE.Submodels CCL" begin
    for (flag, iqmin, iqmax, ipmax) in ((true, -0.4092676385936225, 0.4092676385936225, 1.11),
                                        (false, -0.592, 0.592, 0.5744562646538022))
        @named ccl = CCL(; Qmax = 0.48, pqflag = flag, ImaxTD = 1.7, Iphl = 1.11, Iqhl = 1.11)
        @named rig = System(Equation[ccl.IpCMD ~ 1.65, ccl.IqCMD ~ 1.6, ccl.Vt ~ 0.9], t, [], []; systems = [ccl])
        sys = mtkcompile(rig)
        integ = init(ODEProblem(sys, [], (0.0, 1.0)), Rodas5P())
        @test integ[sys.ccl.IQmin] ≈ iqmin atol = 1e-9
        @test integ[sys.ccl.IQmax] ≈ iqmax atol = 1e-9
        @test integ[sys.ccl.IPmax] ≈ ipmax atol = 1e-9
        @test integ[sys.ccl.Iqmax] ≈ 0.592 atol = 1e-12
        @test integ[sys.ccl.Available_remain1] ≈ 0.4092676385936225 atol = 1e-12
        @test integ[sys.ccl.Available_remain2] ≈ 0.5744562646538022 atol = 1e-12
        @test integ[sys.ccl.min1.y] ≈ 0.5744562646538022 atol = 1e-12
        @test integ[sys.ccl.min3.y] ≈ 1.11 atol = 1e-12
    end
end
