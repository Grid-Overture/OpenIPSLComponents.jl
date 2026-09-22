# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/COMP/IEEEVC.mo (extends nothing)
# Voltage regulator current compensator: two PwPin (Gen_terminal, Bus) connected to each other inside the model (a
# pass-through: the .mo's `connect(Gen_terminal, Bus)`), the output VCT as a plain variable. The protected `Complex`
# V_T = vr + j vi and I_T = ir + j ii are aliases of the Gen_terminal pin and are not written; VCT = |V_T + (RC + j XC)
# I_T| is expanded to its real and imaginary parts by hand. Omitted: graphical annotations.

@component function IEEEVC(; name, RC, XC)
    RC, XC = float.((RC, XC))
    pars = @parameters begin
        RC = RC, [description = "Compensating resistance (pu)"]
        XC = XC, [description = "Compensating reactance (pu)"]
    end
    systems = @named begin
        Gen_terminal = PwPin()
        Bus = PwPin()
    end
    vars = @variables begin
        VCT(t), [description = "Compensated terminal voltage (pu)"]
    end
    eqs = Equation[
        VCT ~ sqrt((Gen_terminal.vr + RC * Gen_terminal.ir - XC * Gen_terminal.ii)^2 +
                   (Gen_terminal.vi + RC * Gen_terminal.ii + XC * Gen_terminal.ir)^2),
        connect(Gen_terminal, Bus),
    ]
    System(eqs, t, vars, pars; name, systems)
end
