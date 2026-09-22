# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Essentials/pfComponent.mo (partial)
# The power-flow parameters every component takes: S_b and fn (the `outer SystemBase`, passed as keyword arguments,
# lot 0 decision), V_b, P_0, Q_0, v_0, angle_0. Omitted: displayPF and the enable* flags (dialog only), graphical
# annotations. Children extend this system and `@unpack` the parameters they use (PLAN-02); the batch-0/1 files carry
# these parameters flattened.

@component function pfComponent(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1, angle_0 = 0)
    S_b, V_b, fn, P_0, Q_0, v_0, angle_0 = float.((S_b, V_b, fn, P_0, Q_0, v_0, angle_0))   # F-21
    pars = @parameters begin
        S_b = S_b, [description = "System base power (VA)"]
        V_b = V_b, [description = "Base voltage of the bus (V)"]
        fn = fn, [description = "System frequency (Hz)"]
        P_0 = P_0, [description = "Initial active power (W)"]
        Q_0 = Q_0, [description = "Initial reactive power (var)"]
        v_0 = v_0, [description = "Initial voltage magnitude (pu)"]
        angle_0 = angle_0, [description = "Initial voltage angle (rad)"]
    end
    System(Equation[], t, [], pars; name)
end
