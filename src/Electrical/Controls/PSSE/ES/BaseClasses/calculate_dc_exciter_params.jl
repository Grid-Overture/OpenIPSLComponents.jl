# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/BaseClasses/calculate_dc_exciter_params.mo (function)
# The three `if`s test the numeric parameters V_RMAX_init and K_E_init, so they are plain Julia; Efd0 and SE_Efd0
# may be symbolic (initialization unknowns of the DC exciters, PLAN-04). Returns the tuple (V_RMAX, V_RMIN, K_E)
# that the exciter spreads over three `initialization_eqs`.

function calculate_dc_exciter_params(V_RMAX_init, V_RMIN_init, K_E_init, E_2, S_EE_2, Efd0, SE_Efd0)
    V_RMAX = V_RMAX_init == 0 ? (K_E_init <= 0 ? S_EE_2 * E_2 : S_EE_2 + K_E_init) : V_RMAX_init
    K_E = K_E_init == 0 ? V_RMAX / (10 * Efd0) - SE_Efd0 : K_E_init
    V_RMIN = V_RMAX_init == 0 ? -V_RMAX : V_RMIN_init
    (V_RMAX, V_RMIN, K_E)
end
