# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Nonlinear/CeilingBlock.mo (block)
# Ports are plain variables (u, y; SISO). Omitted: graphical annotations.

@component function CeilingBlock(; name, Ae = 0, Be = 1)
    pars = @parameters begin
        Ae = Ae, [description = "First ceiling coefficient"]
        Be = Be, [description = "Second ceiling coefficient"]
    end
    vars = @variables begin
        u(t), [description = "Connector of Real input signal"]
        y(t), [description = "Connector of Real output signal"]
    end
    System(Equation[y ~ (Ae * exp(Be * abs(u))) * u], t, vars, pars; name)
end
