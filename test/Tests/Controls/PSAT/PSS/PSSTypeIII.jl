# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Controls/PSAT/PSS/PSSTypeIII.mo (a Test of this port, not OpenIPSL's: PLAN-12, family B),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.MachineTestBase. Omitted: graphical annotations, displayPF.
# Same network, machine and exciter as the PSSTypeI Test. `PSSTypeIII.Vref` is the stabilizer output alone (the
# model has no vref0 input and no internal `add`), so the Test sums the exciter's own vref0 outside with a
# Modelica.Blocks.Math.Add; wiring it straight to `vref` would collapse the machine. The nine parameters are this
# port's (the .mo declares none). `PSSTypeIII` is the model, so the Test function takes the suffix _Test.
@component function PSSTypeIII_Test(; name, S_b = 100e6, fn = 50)
    @named base = MachineTestBase(; S_b, fn)
    @unpack bus1 = base
    systems = @named begin
        generator = Order4(; angle_0 = 0.0, ra = 0.001, x1d = 0.302, M = 10.0, D = 0.0, P_0 = 16035269.869201, Q_0 = 11859436.505981, Sn = 20000000.0, v_0 = 1.0, V_b = 400000.0, Vn = 370000.0, S_b, fn)
        exciter_Type_II = AVRTypeII(; vrmin = -5.0, vrmax = 5.0, Ta = 0.1, Te = 1.0, Tr = 0.001, Ae = 0.0006, Be = 0.9, Kf = 0.45, Tf = 1.0, Ka = 400.0, Ke = 0.01)
        pSSTypeIII = PSSTypeIII(; Kw = 5.0, Tw = 10.0, T1 = 0.05, T2 = 0.02, T3 = 3.0, T4 = 5.4, Tc = 0.1, vsmax = 0.1, vsmin = -0.1)
        add = Add(; )
    end
    eqs = Equation[
        generator.pm0 ~ generator.pm,   # connect(generator.pm0, generator.pm)
        generator.vf ~ exciter_Type_II.vf,   # connect(generator.vf, exciter_Type_II.vf)
        exciter_Type_II.vf0 ~ generator.vf0,   # connect(exciter_Type_II.vf0, generator.vf0)
        exciter_Type_II.v ~ generator.v,   # connect(exciter_Type_II.v, generator.v)
        connect(bus1.p, generator.p),
        pSSTypeIII.vs1 ~ generator.w,   # connect(pSSTypeIII.vs1, generator.w)
        exciter_Type_II.vref0 ~ add.u1,   # connect(exciter_Type_II.vref0, add.u1)
        pSSTypeIII.Vref ~ add.u2,   # connect(pSSTypeIII.Vref, add.u2)
        add.y ~ exciter_Type_II.vref,   # connect(add.y, exciter_Type_II.vref)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Controls.PSAT.PSS.PSSTypeIII" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSAT.PSS.PSSTypeIII.jl"))
    validate_against_oracle(PSSTypeIII_Test, oracle;
        # F-28/F-54: MachineTestBase's initialization is three equations short and OpenModelica fixes
        # generator.w, generator.delta and generator.e1q, leaving e1d to absorb the mismatch, while Order4.jl
        # carries delta, w and *e1d* (F-11) and closes the same system on the other root (the bus voltages at
        # 1.0 pu instead of 0.898). The Test restores OpenModelica's point by overriding e1d with its own row 0,
        # exactly as the upstream Tests.Controls.PSAT.OEL.AVRTypeII_OEL_Test on this same base does
        u0 = sys -> [sys.generator.e1d => 0.03259640330186531])
end
