# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Electrical/Analog/Interfaces/Pin.mo
# The second acausal connector of the port (the first is OpenIPSL's PwPin): `v` is the potential at the pin and
# `i` the current flowing into it, a flow variable. `PositivePin` and `NegativePin` only add an icon and an
# `unassignedMessage` to `Pin`, so `Pin` is used for both, as PwPin_p/PwPin_n are for PwPin.
# Omitted: the `unassignedMessage` annotations, graphical annotations.

@connector function Pin(; name)
    vars = @variables begin
        v(t), [description = "Potential at the pin"]
        i(t), [connect = Flow, description = "Current flowing into the pin"]
    end
    System(Equation[], t, vars, []; name)
end
