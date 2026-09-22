# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Banks/PSSE/CSVGN1.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: OpenIPSL.Tests.BaseClasses.SMIB. Omitted: graphical annotations, displayPF.
# `CSVGN1` is the model (PLAN-02: a Test named as its model gets the suffix _Test). `realExpression(y = SHUNT.v)`
# is a sibling's variable, so the block gets `expr = nothing` and the equation is written here (F-22). CSVGN1 has no
# `fn` (only `outer SysData.S_b`), so the transcriber's `fn` was removed. The oracle is the IDA run: OpenModelica's
# DASSL does not carry this Test across SMIB's fault at the Test's tolerance (F-32). Rodas5P does, at the same
# tolerance and with the default threshold (F-36).
@component function CSVGN1_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1, SHUNT = base
    systems = @named begin
        gENSAL = GENSAL(; Tpd0 = 5.0, Tppd0 = 0.07, Tppq0 = 0.09, H = 4.28, D = 0.0, Xd = 1.84, Xq = 1.75, Xpd = 0.41, Xppd = 0.2, Xl = 0.12, S10 = 0.11, S12 = 0.39, angle_0 = 0.070492225331847, Xppq = 0.2, R_a = 0.0, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = 4402877.0, v_0 = 1.0, S_b, fn)
        cSVGN1 = CSVGN1(; K = 5.0, T1 = 0.01, T2 = 0.0, T3 = 10.0, T4 = 0.0, T5 = 0.05, VMAX = 1.05, VMIN = 0.0, CBASE = 40000000.0, MBASE = 80000000.0, v_0 = 1.0, angle_0 = -0.0050614548307836, P_0 = 0.0, Q_0 = 6009897.0, S_b)
        const_ = Constant(; k = 0)
        realExpression = RealExpression(; expr = nothing)   # y = SHUNT.v: written below as the parent's equation (F-22)
    end
    eqs = Equation[
        gENSAL.PMECH ~ gENSAL.PMECH0,   # connect(gENSAL.PMECH, gENSAL.PMECH0)
        gENSAL.EFD ~ gENSAL.EFD0,   # connect(gENSAL.EFD, gENSAL.EFD0)
        connect(gENSAL.p, GEN1.p),
        connect(cSVGN1.p, SHUNT.p),
        cSVGN1.V ~ realExpression.y,   # connect(cSVGN1.V, realExpression.y)
        const_.y ~ cSVGN1.VOTHSG,   # connect(const.y, cSVGN1.VOTHSG)
        realExpression.y ~ SHUNT.v,   # realExpression(y = SHUNT.v)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Banks.PSSE.CSVGN1" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Banks.PSSE.CSVGN1.jl"))
    validate_against_oracle(CSVGN1_Test, oracle)
end
