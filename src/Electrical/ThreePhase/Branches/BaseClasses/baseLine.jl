# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/ThreePhase/Branches/BaseClasses/baseLine.mo (partial)
# Nominal power and frequency of a three-phase line: two parameters no equation of the family reads (accepted as
# keyword arguments S_b, fn as everywhere in the port). Omitted: graphical annotations.
# `protected parameter Real zero = Modelica.Constants.eps` is a plain Julia constant here, LINE_ZERO: the three lines
# put it where the shunt admittance would carry a conductance, and a Julia parameter cannot be `protected`.

const LINE_ZERO = Modelica.Constants.eps

@component function baseLine(; name, S_b = 100e6, fn = 50)
    S, f = float(S_b), float(fn)   # F-21
    pars = @parameters begin
        S = S, [description = "Nominal power (VA)"]
        f = f, [description = "System frequency (Hz)"]
    end
    System(Equation[], t, [], pars; name)
end
