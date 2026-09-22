# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/Lines/Line_1Ph.mo (extends Branches/BaseClasses/baseLine.mo)
# Single-phase pi line written as admittance matrices. Omitted: graphical annotations. The protected matrices
# `Vin`/`Vout`/`Iin`/`Iout` are aliases of the pins and are written inline; `Y_ser`, `Y_sht`, `A`, `B` are built
# exactly as in the .mo, with the base's `zero` (LINE_ZERO) where a shunt conductance would sit. The pin currents
# are already explicit and linear in the .mo, so nothing has to be solved for (no F-16/F-21 risk).

@component function Line_1Ph(; name, S_b = 100e6, fn = 50, Gser = 0, Bser = -10, Bsht = 0)
    @named base = baseLine(; S_b, fn)
    Gser, Bser, Bsht = float.((Gser, Bser, Bsht))   # F-21
    pars = @parameters begin
        Gser = Gser, [description = "Series conductance (pu)"]
        Bser = Bser, [description = "Series susceptance (pu)"]
        Bsht = Bsht, [description = "Shunt half susceptance (pu)"]
    end
    systems = @named begin
        Ain = PwPin()
        Aout = PwPin()
    end
    Y_ser = [Gser -Bser; Bser Gser]
    Y_sht = [LINE_ZERO -Bsht; Bsht LINE_ZERO]
    A = Y_ser + Y_sht
    B = -Y_ser
    Vin = [Ain.vr, Ain.vi]
    Vout = [Aout.vr, Aout.vi]
    Iin = [Ain.ir, Ain.ii]
    Iout = [Aout.ir, Aout.ii]
    eqs = [Iin .~ A * Vin + B * Vout; Iout .~ B * Vin + A * Vout]
    extend(System(eqs, t, [], pars; name, systems), base)
end
