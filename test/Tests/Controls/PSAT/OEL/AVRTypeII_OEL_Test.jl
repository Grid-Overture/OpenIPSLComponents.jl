# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Controls/PSAT/OEL/AVRTypeII_OEL_Test.mo, transcribed automatically (2026-09-16); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.MachineTestBase with component modifiers, which travel in `mods`
# (PLAN-00 "punto delicado" 3): pwLoadPQ2 gets a 3.2 var step from 1 to 21 s and forcePQ, pwLinewithOpening1's
# opening moves to t1 = t2 = 100 s (outside the 50 s horizon) and pwLoadPQ1 drops forcePQ.
# `oXL(xd = generator.xd, xq = generator.xq, Sn = generator.Sn, Vn = generator.Vn)` is transcribed with the literal
# values Order4's own defaults and the Test's modifiers give (1.9, 1.7, 20e6, 370e3).
# Omitted: graphical annotations, displayPF.
# The oracle shows the limiter at rest: ifield stays between 2.04 and 2.10 against if_lim = 3.07, limIntegrator.y is 0
# for the whole run, and the trajectory is the AVRTypeII taking the terminal from 0.898 to 1.000 pu (the Test's power
# flow is not the AVR's equilibrium).
@component function AVRTypeII_OEL_Test(; name, S_b = 100e6, fn = 50)
    @named base = MachineTestBase(; S_b, fn,
        mods = (; pwLoadPQ2 = (; t_start_1 = 1, t_end_1 = 21, dQ1 = 3.2, forcePQ = true),
            pwLinewithOpening1 = (; t1 = 100, t2 = 100),
            pwLoadPQ1 = (; forcePQ = false)))
    @unpack bus1 = base
    systems = @named begin
        generator = Order4(; angle_0 = 0.0, ra = 0.001, x1d = 0.302, M = 10.0, D = 0.0, P_0 = 16035269.869201,
            Q_0 = 11859436.505981, Sn = 20000000.0, v_0 = 1.0, V_b = 400000.0, Vn = 370000.0, S_b, fn)
        exciter_Type_II = AVRTypeII(; vrmin = -5.0, vrmax = 5.0, Ta = 0.1, Te = 1.0, Tr = 0.001, Ae = 0.0006,
            Be = 0.9, Kf = 0.45, Tf = 1.0, Ka = 400.0, Ke = 0.01)
        oXL = OEL(; vOEL_max = 0.05, T0 = 5.0, xd = 1.9, xq = 1.7, Sn = 20000000.0, Vn = 370000.0, if_lim = 3.07, S_b)
    end
    eqs = Equation[
        generator.pm ~ generator.pm0,             # connect(generator.pm0, generator.pm)
        generator.vf ~ exciter_Type_II.vf,        # connect(generator.vf, exciter_Type_II.vf)
        exciter_Type_II.vf0 ~ generator.vf0,      # connect(exciter_Type_II.vf0, generator.vf0)
        oXL.v_ref0 ~ exciter_Type_II.vref0,       # connect(exciter_Type_II.vref0, oXL.v_ref0)
        oXL.v ~ generator.v,                      # connect(oXL.v, generator.v)
        oXL.p ~ generator.P,                      # connect(generator.P, oXL.p)
        oXL.q ~ generator.Q,                      # connect(generator.Q, oXL.q)
        exciter_Type_II.v ~ generator.v,          # connect(exciter_Type_II.v, generator.v)
        exciter_Type_II.vref ~ oXL.v_ref,         # connect(oXL.v_ref, exciter_Type_II.vref)
        connect(bus1.p, generator.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Controls.PSAT.OEL.AVRTypeII_OEL_Test" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle",
        "Controls.PSAT.OEL.AVRTypeII_OEL_Test.jl"))
    validate_against_oracle(AVRTypeII_OEL_Test, oracle;
        # F-28: the Test's initialization is three equations short (9 states, 6 initial equations) and OpenModelica
        # reports `Assuming fixed start value for the following 3 variables: generator.w, generator.delta,
        # generator.e1q` (probe with -d=initialization, 2026-09-16), leaving e1d to absorb the mismatch. Order4.jl
        # instead carries delta, w and *e1d* as initial_conditions (F-11), which closes the same system on
        # the other root: v = 1.000 pu (the declared power flow) instead of OpenModelica's 0.898. The Test restores
        # OpenModelica's point by overriding e1d with its row 0, as LoadTestExpRecovery does with xq (F-54)
        u0 = sys -> [sys.generator.e1d => 0.03259640330186475])
end
