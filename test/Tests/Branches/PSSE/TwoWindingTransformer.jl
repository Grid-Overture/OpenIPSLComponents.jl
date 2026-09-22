# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Tests/Branches/PSSE/TwoWindingTransformer.mo, transcribed automatically (2026-09-14); reviewed by hand.
# extends: BaseClasses.SMIB, Modelica.Icons.Example (ignored). Omitted: graphical annotations, displayPF.
# The machine instance is called `gENROE` in the .mo but its class is GENSAL (sic). `V_b = 14700` reaches GENSAL
# through pfComponent, where it is inert. The Julia function is PSSE_TwoWindingTransformer_Test: the Test is named
# as its model (PLAN-02) and `TwoWindingTransformer` is already the PSAT transformer.
@component function PSSE_TwoWindingTransformer_Test(; name, S_b = 100e6, fn = 50)
    @named base = SMIB(; S_b, fn)
    @unpack GEN1 = base
    systems = @named begin
        gENROE = GENSAL(; Tpd0 = 5.0, D = 0.0, Xppd = 0.2, Xl = 0.12, Xppq = 0.2, Tppd0 = 0.05, Tppq0 = 0.1, H = 4.0, Xd = 1.41, Xq = 1.35, Xpd = 0.3, S10 = 0.1, S12 = 0.5, R_a = 0.002, angle_0 = 4.747869, M_b = 100000000.0, P_0 = 40000000.0, Q_0 = -16460280.0, v_0 = 1.0, V_b = 14700.0, S_b, fn)
        twoWindingTransformer = PSSE_TwoWindingTransformer(; CZ = 1, R = 0.001, X = 0.2, G = 0.0, B = 0.0, S_n = 1000000.0, ANG1 = 0.017453292519943, VB1 = 14700.0, VB2 = 130000.0, t1 = 0.8085, VNOM1 = 20000.0, t2 = 1.02, VNOM2 = 130000.0, CW = 3, S_b, fn)
    end
    eqs = Equation[
        gENROE.PMECH ~ gENROE.PMECH0,   # connect(gENROE.PMECH, gENROE.PMECH0)
        gENROE.EFD ~ gENROE.EFD0,   # connect(gENROE.EFD, gENROE.EFD0)
        connect(twoWindingTransformer.n, GEN1.p),
        connect(gENROE.p, twoWindingTransformer.p),
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end

@testset "Tests.Branches.PSSE.TwoWindingTransformer" begin
    oracle = include(joinpath(@__DIR__, "..", "..", "..", "oracle", "Branches.PSSE.TwoWindingTransformer.jl"))
    validate_against_oracle(PSSE_TwoWindingTransformer_Test, oracle)
end
