# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/ConstantPower.mo (extends TG/BaseClasses/BaseGovernor.mo)
# Feed-through governor: the mechanical power stays at its initial value. Omitted: graphical annotations.

@component function ConstantPower(; name)
    @named base = BaseGovernor()
    @unpack PMECH0, PMECH = base
    eqs = Equation[
        PMECH0 ~ PMECH,   # connect(PMECH0, PMECH)
    ]
    extend(System(eqs, t, [], []; name), base)
end
