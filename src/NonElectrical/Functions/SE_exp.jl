# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - NonElectrical/Functions/SE_exp.mo (function)

function SE_exp(u, S_EE_1, S_EE_2, E_1, E_2)
    X = log(S_EE_2 / S_EE_1) / log(E_2)
    S_EE_1 * u^X
end
