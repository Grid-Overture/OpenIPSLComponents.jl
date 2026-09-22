# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/PSS/BaseClasses/BasePSS.mo (partial; extends nothing)
# Base of the PSSE power system stabilizers: three causal ports as plain variables and no equations of its own.
# Omitted: graphical annotations.

@component function BasePSS(; name)
    vars = @variables begin
        V_S2(t), [description = "PSS input signal 2"]
        V_S1(t), [description = "PSS input signal 1"]
        VOTHSG(t), [description = "PSS output"]
    end
    System(Equation[], t, vars, []; name)
end
