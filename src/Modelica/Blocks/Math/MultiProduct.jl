# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# Modelica Standard Library 4.0.0 - Blocks/Math.mo, block MultiProduct
# Ports are plain variables (u[1:nu], y (PartialRealMISO)). Omitted: graphical annotations; nu = 0 (y = 0) not reproduced
# (TGTypeV and TGTypeVI, the only users in OpenIPSL 3.1.0, instantiate nu = 2).

@component function MultiProduct(; name, nu = 1)
    vars = @variables begin
        (u(t))[1:nu], [description = "Connector of Real input signals"]
        y(t), [description = "Connector of Real output signal"]
    end
    # y = product(u) (nu > 0)
    System(Equation[y ~ prod(u[i] for i in 1:nu)], t, [u, y], []; name)
end
