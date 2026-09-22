# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Controls/PSAT/PSS/PSSTypeI.mo (a Test of this port, not OpenIPSL's: PLAN-12, family B),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.MachineTestBase. Omitted: graphical annotations, displayPF.
# The network, the machine and the exciter are those of Tests.Controls.PSAT.OEL.AVRTypeII_OEL_Test, with the OEL
# replaced by the stabilizer and without that Test's modifiers, so the base opens pwLinewithOpening1 at 2 s. The
# .mo declares no defaults for PSSTypeI, so the seven parameters are this port's. `PSSTypeI` is the model, so the
# Test function takes the suffix _Test (PLAN-02 rule). The declared operating point of MachineTestBase is not an
# exact power flow (bus1.v starts at 0.898 pu), exactly as in the upstream Test this one is built on.
@component function PSSTypeI_Test(; name, S_b = 100e6, fn = 50)
    @named base = MachineTestBase(; S_b, fn)
    @unpack bus1 = base
    systems = @named begin
        generator = Order4(; angle_0 = 0.0, ra = 0.001, x1d = 0.302, M = 10.0, D = 0.0, P_0 = 16035269.869201, Q_0 = 11859436.505981, Sn = 20000000.0, v_0 = 1.0, V_b = 400000.0, Vn = 370000.0, S_b, fn)
        exciter_Type_II = AVRTypeII(; vrmin = -5.0, vrmax = 5.0, Ta = 0.1, Te = 1.0, Tr = 0.001, Ae = 0.0006, Be = 0.9, Kf = 0.45, Tf = 1.0, Ka = 400.0, Ke = 0.01)
        pSSTypeI = PSSTypeI(; Kw = 5.0, Kp = 0.0, Kv = 0.0, vsmax = 0.1, vsmin = -0.1, Tw = 10.0, Tc = 0.1)
    end
    eqs = Equation[
        generator.pm0 ~ generator.pm,   # connect(generator.pm0, generator.pm)
        generator.vf ~ exciter_Type_II.vf,   # connect(generator.vf, exciter_Type_II.vf)
        exciter_Type_II.vf0 ~ generator.vf0,   # connect(exciter_Type_II.vf0, generator.vf0)
        exciter_Type_II.v ~ generator.v,   # connect(exciter_Type_II.v, generator.v)
        connect(bus1.p, generator.p),
        pSSTypeI.w ~ generator.w,   # connect(pSSTypeI.w, generator.w)
        pSSTypeI.Pg ~ generator.P,   # connect(pSSTypeI.Pg, generator.P)
        pSSTypeI.Vg ~ generator.v,   # connect(pSSTypeI.Vg, generator.v)
        exciter_Type_II.vref0 ~ pSSTypeI.vref0,   # connect(exciter_Type_II.vref0, pSSTypeI.vref0)
        pSSTypeI.Vref ~ exciter_Type_II.vref,   # connect(pSSTypeI.Vref, exciter_Type_II.vref)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Controls.PSAT.PSS.PSSTypeI" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSAT.PSS.PSSTypeI.jl"))
    validate_against_oracle(PSSTypeI_Test, oracle;
        # F-28/F-54: MachineTestBase's initialization is three equations short and OpenModelica fixes
        # generator.w, generator.delta and generator.e1q, leaving e1d to absorb the mismatch, while Order4.jl
        # carries delta, w and *e1d* (F-11) and closes the same system on the other root (the bus voltages at
        # 1.0 pu instead of 0.898). The Test restores OpenModelica's point by overriding e1d with its own row 0,
        # exactly as the upstream Tests.Controls.PSAT.OEL.AVRTypeII_OEL_Test on this same base does
        u0 = sys -> [sys.generator.e1d => 0.03259640330175217])
end
