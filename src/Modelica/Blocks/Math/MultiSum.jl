# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Math.mo, block MultiSum
# Ports are plain variables (u[1:nu], y (PartialRealMISO)). Omitted: graphical annotations; nu = 0 (y = 0) not reproduced.

@component function MultiSum(; name, nu = 1, k = fill(1, nu))
    pars = @parameters begin
        (k[1:nu] = k), [description = "Input gains"]
    end
    vars = @variables begin
        (u(t))[1:nu], [description = "Connector of Real input signals"]
        y(t), [description = "Connector of Real output signal"]
    end
    # y = k*u (nu > 0; OpenIPSL never instantiates nu = 0)
    System(Equation[y ~ sum(k[i] * u[i] for i in 1:nu)], t, [u, y], [k]; name)
end
