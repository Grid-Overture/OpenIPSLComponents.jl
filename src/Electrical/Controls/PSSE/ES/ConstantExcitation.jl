# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/ConstantExcitation.mo (extends ES/BaseClasses/BaseExciter.mo)
# Feed-through excitation: the field voltage stays at its initial value. `connect(DiffV.u2, DiffV.u1)` puts both
# inputs of the error sum on the same reference (its output is 0 and unused); `V_REF = 0` is the `initial equation`
# that closes the base's third `fixed = false` parameter. Omitted: graphical annotations.

@component function ConstantExcitation(; name)
    @named base = BaseExciter()
    @unpack DiffV, EFD, EFD0, V_REF = base
    eqs = Equation[
        DiffV.u2 ~ DiffV.u1,   # connect(DiffV.u2, DiffV.u1)
        EFD0 ~ EFD,            # connect(EFD0, EFD)
    ]
    extend(System(eqs, t, [], []; name, initialization_eqs = [V_REF ~ 0]), base)
end
