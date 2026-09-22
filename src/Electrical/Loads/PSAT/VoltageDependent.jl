# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Loads/PSAT/VoltageDependent.mo (extends BaseClasses/baseLoad.mo)
# Blocks: none. Omitted: graphical annotations. V_b is kept because Example_3 sets it, although no equation uses it
# (pfComponent, through the base). The F-16 deviation of the bilinear P/Q definitions lives in the base.

@component function VoltageDependent(; name, S_b = 100e6, V_b = 400e3, fn = 50, P_0 = 1e6, Q_0 = 0, v_0 = 1,
        angle_0 = 0, Sn = S_b, alphap = 2.0, alphaq = 2.0)
    @named base = baseLoad(; S_b, V_b, fn, P_0, Q_0, v_0, angle_0, Sn)
    @unpack v, P, Q, S_b, P_0, Q_0, v_0 = base
    pars = @parameters begin
        alphap = alphap, [description = "Active power exponent"]
        alphaq = alphaq, [description = "Reactive power exponent"]
    end
    vars = @variables begin
        a(t), [description = "Auxiliary variable, voltage division"]
    end
    eqs = Equation[
        a ~ v / v_0,
        P ~ P_0 / S_b * a^alphap,
        Q ~ Q_0 / S_b * a^alphaq,
    ]
    extend(System(eqs, t, vars, pars; name), base)
end
