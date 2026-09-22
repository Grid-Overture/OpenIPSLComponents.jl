# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Machines/PSSE/CIM6.mo (a Test of this port, not OpenIPSL's: PLAN-12, family G),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The SMIB base and the machine of Tests.Machines.PSSE.GENSAL, as in the harness probe, with the motor on the
# LOAD bus beside the base's own constantLoad and the operating point that bus declares. `Sup = false` puts the
# motor in the steady-state branch of its own initial equation and `Ctrl = false` disables the controllable
# synchronous speed; the `true` sides are covered by test_CIM6.jl. The electrical parameters are the defaults of
# the .mo; the load-torque coefficients are not, because the defaults give TL = 4 pu at rated speed and no
# operating point exists near w = 1 (F-90), so the Test uses the usual quadratic characteristic A = 1,
# B = C0 = D = 0 with T_nom = 0.6, sized to the 10 MW the motor is declared to draw on its 15 MVA base.
# `CIM6` is the model, so the Test function takes the suffix _Test (PLAN-02 rule).
@component function CIM6_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1, LOAD = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 5416582.0, v_0 = 1.0, S_b, fn)
        cIM6 = CIM6(; Sup = false, Ctrl = false, M_b = 15000000.0, V_b = 400000.0, P_0 = 10000000.0, Q_0 = 5000000.0, v_0 = 0.9919935, angle_0 = -0.5762684, Mtype = 1, Ra = 0.0, Xa = 0.0759, Xm = 3.1241, R1 = 0.0085, X1 = 0.0759, R2 = 0.0, X2 = 0.0, E1 = 1.0, SE1 = 0.06, E2 = 1.2, SE2 = 0.6, H = 0.4, T_nom = 0.6, A = 1.0, B = 0.0, C0 = 0.0, D = 0.0, E = 2.0, S_b, fn)
    end
    eqs = Equation[
        gENSAL.PMECH ~ gENSAL.PMECH0,   # connect(gENSAL.PMECH, gENSAL.PMECH0)
        gENSAL.EFD ~ gENSAL.EFD0,   # connect(gENSAL.EFD, gENSAL.EFD0)
        connect(gENSAL.p, GEN1.p),
        connect(cIM6.p, LOAD.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Machines.PSSE.CIM6" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Machines.PSSE.CIM6.jl"))
    validate_against_oracle(CIM6_Test, oracle)
end
