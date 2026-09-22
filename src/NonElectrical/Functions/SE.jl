# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Functions/SE.mo (function)
# A Julia function usable with numbers (protected parameters of the machines) and with symbolic `u` inside equations
# (ImSE, the exciters): the `if` chain on `u` is an `ifelse`, the parameter tests are plain Julia. Both branches of
# an `ifelse` are evaluated, so the `sys = 0` branch is selected but B*(u - A)^2/u is still computed (u = 0 gives
# NaN in the unused branch, harmless).

function SE(u, SE1, SE2, E1, E2)
    a = SE2 != 0 ? sqrt(SE1 * E1 / (SE2 * E2)) : 0
    A = E2 - (E1 - E2) / (a - 1)
    B = abs(E1 - E2) < Modelica.Constants.eps ? 0 : SE2 * E2 * (a - 1)^2 / (E1 - E2)^2
    SE1 == 0.0 && return zero(u)
    ifelse((u <= 0.0) | (u <= A), zero(u), B * (u - A)^2 / u)
end
