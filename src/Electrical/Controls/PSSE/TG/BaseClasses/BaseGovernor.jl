# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/BaseGovernor.mo (partial; extends nothing)
# Base of the PSSE turbine governors: three causal ports as plain variables and no equations of its own.
# Omitted: graphical annotations.

@component function BaseGovernor(; name)
    vars = @variables begin
        SPEED(t), [description = "Machine speed deviation from nominal (pu)"]
        PMECH0(t), [description = "Initial mechanical power (machine base)"]
        PMECH(t), [description = "Mechanical power (machine base)"]
    end
    System(Equation[], t, vars, []; name)
end
