# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/MonoTri/Line_MT.mo (extends Branches/BaseClasses/baseLine.mo)
# Hybrid transmission line: pin `p` on the positive-sequence side (pu of S_b), pins `A`, `B`, `C` on the
# three-phase side (pu of the phase base). The sibling of Transformer_MT: same four pins, same eight equations,
# same `parameter` evaluation of the 32 coefficients, but the model of the branch is a pi line given by its 3x3
# series and shunt-half matrices instead of a transformer connection. `S` and `f` come from `baseLine` and no
# equation reads them. Omitted: graphical annotations.
# `ModelType` selects one of the two `LineFcn` functions: in the .mo that is the local `function Model`, whose
# condition is a parameter expression OpenModelica evaluates at translation time, so it is a Julia `if` here
# (F-50). The three 1x18 rows `Yser`, `Ysht`, `Y012` and the 32 coefficients `Aux[1, k]` are `parameter`
# expressions: evaluated once in the constructor and entering the eight equations as NUMBERS (F-22 point 1), which
# is why the eighteen Gser*/Bser*/Bsht* and the six G_*/B_* are plain numeric keyword arguments and not
# `@parameters`. `Ysht` carries **literal zeros** in its conductances, not the `zero = eps` of `baseLine` that the
# three `Line_?Ph` use (sic). Defaults are the .mo ones.
# With the shipped defaults `ModelType = 1` is unusable: `Y012 = 0` and every `Bsht = 0` make the matrix
# `Yabcnrt + Yshtk` that MT_FiniteImpedance inverts first the null matrix, so all 32 coefficients are NaN
# (F-97, MT_FiniteImpedance.jl header, test_MT_LineFcn.jl case c). Reproduced, not guarded against.

@component function Line_MT(; name, S_b = 100e6, fn = 50, ModelType = 0,
        Gseraa = 0, Bseraa = -10, Gserab = 0, Bserab = 0, Gserac = 0, Bserac = 0,
        Gserbb = 0, Bserbb = -10, Gserbc = 0, Bserbc = 0, Gsercc = 0, Bsercc = -10,
        Bshtaa = 0, Bshtab = 0, Bshtac = 0, Bshtbb = 0, Bshtbc = 0, Bshtcc = 0,
        G_0 = 0, B_0 = 0, G_1 = 0, B_1 = 0, G_2 = 0, B_2 = 0)
    @named base = baseLine(; S_b, fn)
    Gseraa, Bseraa, Gserab, Bserab, Gserac, Bserac = float.((Gseraa, Bseraa, Gserab, Bserab, Gserac, Bserac))
    Gserbb, Bserbb, Gserbc, Bserbc, Gsercc, Bsercc = float.((Gserbb, Bserbb, Gserbc, Bserbc, Gsercc, Bsercc))
    Bshtaa, Bshtab, Bshtac, Bshtbb, Bshtbc, Bshtcc = float.((Bshtaa, Bshtab, Bshtac, Bshtbb, Bshtbc, Bshtcc))
    G_0, B_0, G_1, B_1, G_2, B_2 = float.((G_0, B_0, G_1, B_1, G_2, B_2))   # F-21
    Yser = [Gseraa, Bseraa, Gserab, Bserab, Gserac, Bserac,
            Gserab, Bserab, Gserbb, Bserbb, Gserbc, Bserbc,
            Gserac, Bserac, Gserbc, Bserbc, Gsercc, Bsercc]
    Ysht = [0.0, Bshtaa, 0.0, Bshtab, 0.0, Bshtac,
            0.0, Bshtab, 0.0, Bshtbb, 0.0, Bshtbc,
            0.0, Bshtac, 0.0, Bshtbc, 0.0, Bshtcc]
    Y012 = [G_0, B_0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, G_1, B_1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, G_2, B_2]
    # function Model(ModelType, Yser, Ysht, Y012)
    Aux = ModelType == 0 ? MT_InfiniteImpedances(Yser, Ysht) :
          ModelType == 1 ? MT_FiniteImpedance(Yser, Ysht, Y012) :
          error("Line_MT: ModelType must be 0 or 1, got $ModelType")
    Ar, Ai, MB1r, MB1i, MB2r, MB2i, MB3r, MB3i = Aux[1], Aux[2], Aux[3], Aux[4], Aux[5], Aux[6], Aux[7], Aux[8]
    C1r, C1i, C2r, C2i, C3r, C3i = Aux[9], Aux[10], Aux[11], Aux[12], Aux[13], Aux[14]
    D11r, D11i, D12r, D12i, D13r, D13i = Aux[15], Aux[16], Aux[17], Aux[18], Aux[19], Aux[20]
    D21r, D21i, D22r, D22i, D23r, D23i = Aux[21], Aux[22], Aux[23], Aux[24], Aux[25], Aux[26]
    D31r, D31i, D32r, D32i, D33r, D33i = Aux[27], Aux[28], Aux[29], Aux[30], Aux[31], Aux[32]
    systems = @named begin
        p = PwPin()
        A = PwPin()
        B = PwPin()
        C = PwPin()
    end
    eqs = Equation[
        p.ir ~ Ar * p.vr - Ai * p.vi + MB1r * A.vr - MB1i * A.vi + MB2r * B.vr - MB2i * B.vi + MB3r * C.vr - MB3i * C.vi,
        p.ii ~ Ar * p.vi + Ai * p.vr + MB1r * A.vi + MB1i * A.vr + MB2r * B.vi + MB2i * B.vr + MB3r * C.vi + MB3i * C.vr,
        A.ir ~ C1r * p.vr - C1i * p.vi + D11r * A.vr - D11i * A.vi + D12r * B.vr - D12i * B.vi + D13r * C.vr - D13i * C.vi,
        A.ii ~ C1r * p.vi + C1i * p.vr + D11r * A.vi + D11i * A.vr + D12r * B.vi + D12i * B.vr + D13r * C.vi + D13i * C.vr,
        B.ir ~ C2r * p.vr - C2i * p.vi + D21r * A.vr - D21i * A.vi + D22r * B.vr - D22i * B.vi + D23r * C.vr - D23i * C.vi,
        B.ii ~ C2r * p.vi + C2i * p.vr + D21r * A.vi + D21i * A.vr + D22r * B.vi + D22i * B.vr + D23r * C.vi + D23i * C.vr,
        C.ir ~ C3r * p.vr - C3i * p.vi + D31r * A.vr - D31i * A.vi + D32r * B.vr - D32i * B.vi + D33r * C.vr - D33i * C.vi,
        C.ii ~ C3r * p.vi + C3i * p.vr + D31r * A.vi + D31i * A.vr + D32r * B.vi + D32i * B.vr + D33r * C.vi + D33i * C.vr,
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
