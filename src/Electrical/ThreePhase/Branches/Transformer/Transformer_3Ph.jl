# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/Transformer/Transformer_3Ph.mo (extends ThreePhaseComponent.mo)
# Three-phase transformer as a pi element. Omitted: graphical annotations; the protected matrices Vin/Vout/Iin/Iout
# are aliases of the pins and are written inline.
# `Connection` selects one of the nine TransfConnection functions: in the .mo that is the local `function
# ConnectionType`, whose condition is a parameter expression OpenModelica evaluates at translation time, so it is a
# Julia `if` here (F-50). `OperPI` and the four 6x6 blocks are `parameter` expressions too: they are evaluated once
# in the constructor and enter the twelve equations as NUMBERS (F-22 point 1, as `MatrixGain.K`), which is why
# `R`, `X` and `tap` are plain numeric keyword arguments and not `@parameters`.
# Defaults are the .mo ones, X small and R large (sic).

@component function Transformer_3Ph(; name, S_b = 100e6, fn = 50, Connection = 0, tap = 1, X = 0.001, R = 0.1)
    @named base = ThreePhaseComponent(; S_b)
    X, R, tap = float.((X, R, tap))   # F-21
    # function ConnectionType(Connection, X, R, tap)
    OperPI = Connection == 0 ? TransfConnection_Yg_Yg(X, R, tap) :
             Connection == 1 ? TransfConnection_D_D(X, R, tap) :
             Connection == 2 ? TransfConnection_Y_Y(X, R, tap) :
             Connection == 3 ? TransfConnection_D_Yg(X, R, tap) :
             Connection == 4 ? TransfConnection_Yg_D(X, R, tap) :
             Connection == 5 ? TransfConnection_D_Y(X, R, tap) :
             Connection == 6 ? TransfConnection_Y_D(X, R, tap) :
             Connection == 7 ? TransfConnection_Y_Yg(X, R, tap) :
             Connection == 8 ? TransfConnection_Yg_Y(X, R, tap) :
             error("Transformer_3Ph: Connection must be 0..8, got $Connection")
    Amat = OperPI[1:6, 1:6]
    Bmat = OperPI[1:6, 7:12]
    Cmat = OperPI[7:12, 1:6]
    Dmat = OperPI[7:12, 7:12]
    systems = @named begin
        Ain = PwPin()
        Bin = PwPin()
        Cin = PwPin()
        Aout = PwPin()
        Bout = PwPin()
        Cout = PwPin()
    end
    Vin = [Ain.vr, Ain.vi, Bin.vr, Bin.vi, Cin.vr, Cin.vi]
    Vout = [Aout.vr, Aout.vi, Bout.vr, Bout.vi, Cout.vr, Cout.vi]
    Iin = [Ain.ir, Ain.ii, Bin.ir, Bin.ii, Cin.ir, Cin.ii]
    Iout = [Aout.ir, Aout.ii, Bout.ir, Bout.ii, Cout.ir, Cout.ii]
    eqs = [Iin .~ Amat * Vin + Bmat * Vout; Iout .~ Cmat * Vin + Dmat * Vout]
    extend(System(eqs, t, [], []; name, systems), base)
end
