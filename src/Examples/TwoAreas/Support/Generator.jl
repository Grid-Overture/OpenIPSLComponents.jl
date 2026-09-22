# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Examples/TwoAreas/Support/Generator.mo (partial; extends Electrical/Essentials/pfComponent.mo)
# Template of the generation units of the TwoAreas examples: pfComponent plus the pin `pwPin`, nothing else (unlike
# Interfaces/Generator it defines no P, Q). Named TwoAreas_Generator (the name table): the leaf name
# collides with Interfaces.Generator. Children `@unpack pwPin = base`. Omitted: graphical annotations.

@component function TwoAreas_Generator(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    @named base = pfComponent(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0)
    systems = @named begin
        pwPin = PwPin()
    end
    extend(System(Equation[], t, [], []; name, systems), base)
end
