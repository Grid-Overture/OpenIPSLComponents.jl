# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/Lines/Line_2Ph.mo (extends Branches/BaseClasses/baseLine.mo)
# Two-phase pi line; same shape as Line_1Ph, see its header.

@component function Line_2Ph(; name, S_b = 100e6, fn = 50, Gseraa = 0, Bseraa = -10, Gserab = 0, Bserab = 0,
        Gserbb = 0, Bserbb = -10, Bshtaa = 0, Bshtab = 0, Bshtbb = 0)
    @named base = baseLine(; S_b, fn)
    Gseraa, Bseraa, Gserab, Bserab, Gserbb, Bserbb = float.((Gseraa, Bseraa, Gserab, Bserab, Gserbb, Bserbb))
    Bshtaa, Bshtab, Bshtbb = float.((Bshtaa, Bshtab, Bshtbb))
    pars = @parameters begin
        Gseraa = Gseraa, [description = "Element (1,1) in series conductance matrix (pu)"]
        Bseraa = Bseraa, [description = "Element (1,1) in series susceptance matrix (pu)"]
        Gserab = Gserab, [description = "Element (1,2) in series conductance matrix (pu)"]
        Bserab = Bserab, [description = "Element (1,2) in series susceptance matrix (pu)"]
        Gserbb = Gserbb, [description = "Element (2,2) in series conductance matrix (pu)"]
        Bserbb = Bserbb, [description = "Element (2,2) in series susceptance matrix (pu)"]
        Bshtaa = Bshtaa, [description = "Element (1,1) in shunt half susceptance matrix (pu)"]
        Bshtab = Bshtab, [description = "Element (1,2) in shunt half susceptance matrix (pu)"]
        Bshtbb = Bshtbb, [description = "Element (2,2) in shunt half susceptance matrix (pu)"]
    end
    systems = @named begin
        Ain = PwPin()
        Bin = PwPin()
        Aout = PwPin()
        Bout = PwPin()
    end
    z = LINE_ZERO
    Y_ser = [Gseraa -Bseraa Gserab -Bserab
             Bseraa Gseraa Bserab Gserab
             Gserab -Bserab Gserbb -Bserbb
             Bserab Gserab Bserbb Gserbb]
    Y_sht = [z -Bshtaa z -Bshtab
             Bshtaa z Bshtab z
             z -Bshtab z -Bshtbb
             Bshtab z Bshtbb z]
    A = Y_ser + Y_sht
    B = -Y_ser
    Vin = [Ain.vr, Ain.vi, Bin.vr, Bin.vi]
    Vout = [Aout.vr, Aout.vi, Bout.vr, Bout.vi]
    Iin = [Ain.ir, Ain.ii, Bin.ir, Bin.ii]
    Iout = [Aout.ir, Aout.ii, Bout.ir, Bout.ii]
    eqs = [Iin .~ A * Vin + B * Vout; Iout .~ B * Vin + A * Vout]
    extend(System(eqs, t, [], pars; name, systems), base)
end
