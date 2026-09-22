# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/MonoTri/Transformer_MT.mo
# Hybrid transformer: pin `p` on the positive-sequence side (pu of S_b), pins `A`, `B`, `C` on the three-phase side
# (pu of the phase base). The .mo does not extend ThreePhaseComponent, only declares the `outer SystemBase`:
# S_b and fn are accepted as keyword arguments and no equation reads them. Omitted: graphical annotations.
# `Connection` and `ModelType` select one of the fourteen TransformerFcn functions: in the .mo that is the local
# `function ConnectionType`, whose conditions are parameter expressions OpenModelica evaluates at translation time,
# so they are Julia `if`s here (F-50). For Connection 3..6 (the connections with a phase shift) the .mo ignores
# `ModelType`, sic: those have no finite-impedance variant.
# `Y012` and the 32 coefficients `Aux[1, k]` are `parameter` expressions: evaluated once in the constructor and
# entering the eight equations as NUMBERS (F-22 point 1), which is why R, X, tap and the six G_*/B_* are plain
# numeric keyword arguments and not `@parameters`. Defaults are the .mo ones, X small and R large (sic).

@component function Transformer_MT(; name, S_b = 100e6, fn = 50, Connection = 0, ModelType = 0,
        tap = 1, X = 0.001, R = 0.1, G_0 = 0, B_0 = 0, G_1 = 0, B_1 = 0, G_2 = 0, B_2 = 0)
    X, R, tap = float.((X, R, tap))   # F-21
    G_0, B_0, G_1, B_1, G_2, B_2 = float.((G_0, B_0, G_1, B_1, G_2, B_2))
    Y012 = [G_0, B_0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, G_1, B_1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, G_2, B_2]
    # function ConnectionType(Connection, ModelType, X, R, tap, Y012)
    Aux = Connection == 0 ? (ModelType == 0 ? TransformerFcn_Yg_Yg(X, R, tap) : TransformerFcn_Yg_Yg_FinImp(X, R, tap, Y012)) :
          Connection == 1 ? (ModelType == 0 ? TransformerFcn_D_D(X, R, tap) : TransformerFcn_D_D_FinImp(X, R, tap, Y012)) :
          Connection == 2 ? (ModelType == 0 ? TransformerFcn_Y_Y(X, R, tap) : TransformerFcn_Y_Y_FinImp(X, R, tap, Y012)) :
          Connection == 3 ? TransformerFcn_D_Yg(X, R, tap) :
          Connection == 4 ? TransformerFcn_Yg_D(X, R, tap) :
          Connection == 5 ? TransformerFcn_D_Y(X, R, tap) :
          Connection == 6 ? TransformerFcn_Y_D(X, R, tap) :
          Connection == 7 ? (ModelType == 0 ? TransformerFcn_Y_Yg(X, R, tap) : TransformerFcn_Y_Yg_FinImp(X, R, tap, Y012)) :
          Connection == 8 ? (ModelType == 0 ? TransformerFcn_Yg_Y(X, R, tap) : TransformerFcn_Yg_Y_FinImp(X, R, tap, Y012)) :
          error("Transformer_MT: Connection must be 0..8, got $Connection")
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
    System(eqs, t, [], []; name, systems)
end
