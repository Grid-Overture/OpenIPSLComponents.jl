# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/PSS/DisabledPSS.mo (extends PSS/BaseClasses/BasePSS.mo)
# Blocks: const = Constant(k = 0) (instance `const_`: `const` is a Julia keyword, as in SimpleLagLim).
# The two inputs V_S1/V_S2 are left unused, as in the .mo. Omitted: graphical annotations.

@component function DisabledPSS(; name)
    @named base = BasePSS()
    @unpack VOTHSG = base
    systems = @named begin
        const_ = Constant(; k = 0)
    end
    eqs = Equation[
        const_.y ~ VOTHSG,   # connect(const.y, VOTHSG)
    ]
    extend(System(eqs, t, [], []; name, systems), base)
end
