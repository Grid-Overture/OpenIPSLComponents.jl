# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# PortTests/Controls/PSSE/PSS/STBSVC.mo (a Test of this port, not OpenIPSL's: PLAN-12, family B),
# transcribed automatically (2026-09-21); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# The rig of Tests.Banks.PSSE.CSVGN1 (SMIB + GENSAL + CSVGN1 on SHUNT) with the constant zero that Test ties to
# `cSVGN1.VOTHSG` replaced by the supplementary signal. Both `RealExpression`s read a sibling's variable, so each
# block gets `expr = nothing` and its equation is written here (F-22), as in the CSVGN1 Test.
# Both inputs of STBSVC are deviations and therefore both exactly zero at t = 0: the model initializes the lag of
# its second input with the initial value of the first, so two inputs that start apart drive the washout with a
# step it should never see (F-90). Every parameter is a default of the .mo. `STBSVC` is the model, so the Test
# function takes the suffix _Test (PLAN-02 rule). The oracle is the IDA run with a dense non-linear solver: as
# with CSVGN1 on this network, OpenModelica's DASSL does not carry the Test across SMIB's fault (F-32).
@component function STBSVC_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1, SHUNT = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 4402877.0, v_0 = 1.0, S_b, fn)
        cSVGN1 = CSVGN1(; K = 5.0, T1 = 0.01, T2 = 0.0, T3 = 10.0, T4 = 0.0, T5 = 0.05, VMAX = 1.05, VMIN = 0.0, CBASE = 40000000.0, MBASE = 80000000.0, v_0 = 1.0, angle_0 = -0.0050614548307836, P_0 = 0.0, Q_0 = 6009897.0, S_b)
        sTBSVC = STBSVC()
        realExpression = RealExpression(; expr = nothing)    # y = SHUNT.v: the parent's equation (F-22)
        powerDeviation = RealExpression(; expr = nothing)    # y = gENSAL.PELEC - gENSAL.PMECH0: idem
    end
    eqs = Equation[
        gENSAL.PMECH ~ gENSAL.PMECH0,   # connect(gENSAL.PMECH, gENSAL.PMECH0)
        gENSAL.EFD ~ gENSAL.EFD0,   # connect(gENSAL.EFD, gENSAL.EFD0)
        connect(gENSAL.p, GEN1.p),
        connect(cSVGN1.p, SHUNT.p),
        cSVGN1.V ~ realExpression.y,   # connect(cSVGN1.V, realExpression.y)
        sTBSVC.V_S1 ~ gENSAL.SPEED,   # connect(sTBSVC.V_S1, gENSAL.SPEED)
        sTBSVC.V_S2 ~ powerDeviation.y,   # connect(sTBSVC.V_S2, powerDeviation.y)
        sTBSVC.VOTHSG ~ cSVGN1.VOTHSG,   # connect(sTBSVC.VOTHSG, cSVGN1.VOTHSG)
        realExpression.y ~ SHUNT.v,   # realExpression(y = SHUNT.v)
        powerDeviation.y ~ gENSAL.PELEC - gENSAL.PMECH0,   # powerDeviation(y = gENSAL.PELEC - gENSAL.PMECH0)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "PortTests.Controls.PSSE.PSS.STBSVC" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "..", "oracle", "Controls.PSSE.PSS.STBSVC.jl"))
    validate_against_oracle(STBSVC_Test, oracle)
end
