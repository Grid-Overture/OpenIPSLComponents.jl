# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/Lines/Line_3Ph.mo (extends Branches/BaseClasses/baseLine.mo)
# Three-phase pi line; same shape as Line_1Ph, see its header. The .mo repeats the `outer SystemBase` the base
# already declares: S_b and fn are the same keyword arguments.

@component function Line_3Ph(; name, S_b = 100e6, fn = 50,
        Gseraa = 0, Bseraa = -10, Gserab = 0, Bserab = 0, Gserac = 0, Bserac = 0,
        Gserbb = 0, Bserbb = -10, Gserbc = 0, Bserbc = 0, Gsercc = 0, Bsercc = -10,
        Bshtaa = 0, Bshtab = 0, Bshtac = 0, Bshtbb = 0, Bshtbc = 0, Bshtcc = 0)
    @named base = baseLine(; S_b, fn)
    Gseraa, Bseraa, Gserab, Bserab, Gserac, Bserac = float.((Gseraa, Bseraa, Gserab, Bserab, Gserac, Bserac))
    Gserbb, Bserbb, Gserbc, Bserbc, Gsercc, Bsercc = float.((Gserbb, Bserbb, Gserbc, Bserbc, Gsercc, Bsercc))
    Bshtaa, Bshtab, Bshtac, Bshtbb, Bshtbc, Bshtcc = float.((Bshtaa, Bshtab, Bshtac, Bshtbb, Bshtbc, Bshtcc))
    pars = @parameters begin
        Gseraa = Gseraa, [description = "Element (1,1) in series conductance matrix (pu)"]
        Bseraa = Bseraa, [description = "Element (1,1) in series susceptance matrix (pu)"]
        Gserab = Gserab, [description = "Element (1,2) in series conductance matrix (pu)"]
        Bserab = Bserab, [description = "Element (1,2) in series susceptance matrix (pu)"]
        Gserac = Gserac, [description = "Element (1,3) in series conductance matrix (pu)"]
        Bserac = Bserac, [description = "Element (1,3) in series susceptance matrix (pu)"]
        Gserbb = Gserbb, [description = "Element (2,2) in series conductance matrix (pu)"]
        Bserbb = Bserbb, [description = "Element (2,2) in series susceptance matrix (pu)"]
        Gserbc = Gserbc, [description = "Element (2,3) in series conductance matrix (pu)"]
        Bserbc = Bserbc, [description = "Element (2,3) in series susceptance matrix (pu)"]
        Gsercc = Gsercc, [description = "Element (3,3) in series conductance matrix (pu)"]
        Bsercc = Bsercc, [description = "Element (3,3) in series susceptance matrix (pu)"]
        Bshtaa = Bshtaa, [description = "Element (1,1) in shunt half susceptance matrix (pu)"]
        Bshtab = Bshtab, [description = "Element (1,2) in shunt half susceptance matrix (pu)"]
        Bshtac = Bshtac, [description = "Element (1,3) in shunt half susceptance matrix (pu)"]
        Bshtbb = Bshtbb, [description = "Element (2,2) in shunt half susceptance matrix (pu)"]
        Bshtbc = Bshtbc, [description = "Element (2,3) in shunt half susceptance matrix (pu)"]
        Bshtcc = Bshtcc, [description = "Element (3,3) in shunt half susceptance matrix (pu)"]
    end
    systems = @named begin
        Ain = PwPin()
        Bin = PwPin()
        Cin = PwPin()
        Aout = PwPin()
        Bout = PwPin()
        Cout = PwPin()
    end
    z = LINE_ZERO
    Y_ser = [Gseraa -Bseraa Gserab -Bserab Gserac -Bserac
             Bseraa Gseraa Bserab Gserab Bserac Gserac
             Gserab -Bserab Gserbb -Bserbb Gserbc -Bserbc
             Bserab Gserab Bserbb Gserbb Bserbc Gserbc
             Gserac -Bserac Gserbc -Bserbc Gsercc -Bsercc
             Bserac Gserac Bserbc Gserbc Bsercc Gsercc]
    Y_sht = [z -Bshtaa z -Bshtab z -Bshtac
             Bshtaa z Bshtab z Bshtac z
             z -Bshtab z -Bshtbb z -Bshtbc
             Bshtab z Bshtbb z Bshtbc z
             z -Bshtac z -Bshtbc z -Bshtcc
             Bshtac z Bshtbc z Bshtcc z]
    A = Y_ser + Y_sht
    B = -Y_ser
    Vin = [Ain.vr, Ain.vi, Bin.vr, Bin.vi, Cin.vr, Cin.vi]
    Vout = [Aout.vr, Aout.vi, Bout.vr, Bout.vi, Cout.vr, Cout.vi]
    Iin = [Ain.ir, Ain.ii, Bin.ir, Bin.ii, Cin.ir, Cin.ii]
    Iout = [Aout.ir, Aout.ii, Bout.ir, Bout.ii, Cout.ir, Cout.ii]
    eqs = [Iin .~ A * Vin + B * Vout; Iout .~ B * Vin + A * Vout]
    extend(System(eqs, t, [], pars; name, systems), base)
end
