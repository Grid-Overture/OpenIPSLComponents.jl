# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/GGOV1/Min_select.mo (block)
# Ports are plain variables (`RealVectorInput u[nu]` as an MTK array variable, as in MultiSum; yMin output).
# `frs0` is the start value of `yMin`, a `missing` parameter of the parent (`fsr0`), so it is carried as a `guess`
# and never as a metadata default (F-16, F-20). Omitted: graphical annotations.

@component function Min_select(; name, nu = 0, frs0 = 0)
    vars = @variables begin
        (u(t))[1:nu], [description = "Connector of Real input signals"]
        yMin(t), [guess = frs0]
    end
    # `min(u)` over the vector, written as nested binary `min` (a symbolic `minimum` would compare Nums)
    expr = u[1]
    for i in 2:nu
        expr = min(expr, u[i])
    end
    System(Equation[yMin ~ expr], t, [u, yMin], []; name)
end
