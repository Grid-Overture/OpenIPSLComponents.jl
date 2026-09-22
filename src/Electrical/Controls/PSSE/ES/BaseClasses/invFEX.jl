# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/BaseClasses/invFEX.mo (function)
# Inverse of FEX for the initialization of the AC exciters: usable with numbers and with symbolic arguments inside
# `initialization_eqs` (Efd0 and Ifd0 are initialization unknowns there, PLAN-04), so the `if` chain on the arguments
# is an `ifelse` chain, as in SE. Both branches of an `ifelse` are evaluated: the square root's argument is a sum of
# squares and needs no guard, and the division of the second test may be 0/0 in an unselected branch (harmless).

function invFEX(K_C, Efd0, Ifd0)
    r = sqrt((Efd0^2 + (K_C * Ifd0)^2) / 0.75)
    ifelse(Ifd0 <= 0, Efd0,
        ifelse(K_C * Ifd0 / (Efd0 + 0.577 * K_C * Ifd0) <= 0.433, Efd0 + 0.577 * K_C * Ifd0,
            ifelse((K_C * Ifd0 / r > 0.433) & (K_C * Ifd0 / r < 0.75), r,
                (Efd0 + 1.732 * K_C * Ifd0) / 1.732)))
end
