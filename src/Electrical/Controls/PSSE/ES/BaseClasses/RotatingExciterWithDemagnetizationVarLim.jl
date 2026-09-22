# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/BaseClasses/RotatingExciterWithDemagnetizationVarLim.mo (extends
# RotatingExciterWithDemagnetization with `redeclare replaceable IntegratorLimVar sISO(K = 1/T_E, y_start = Efd0)`
# and `redeclare Add3 Sum(k3 = K_D)`, identical to the parent's)
# The .mo redeclares K_D identically (`@unpack` from the base) and repeats the Sum redeclare (the parent's default).
# Adds the ports outMin, outMax (plain variables) wired to the variable limits of the integrator. The base is built
# with a plain call (extend, F-39).
# Omitted: graphical annotations.

@component function RotatingExciterWithDemagnetizationVarLim(; name, T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, Efd0, K_D,
        sISO = (; name, T_E, Efd0) -> IntegratorLimVar(; name, K = 1 / T_E, y_start = Efd0))
    base = RotatingExciterWithDemagnetization(; name = :base, T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, Efd0, K_D, sISO)
    @unpack sISO = base
    vars = @variables begin
        outMin(t)
        outMax(t)
    end
    eqs = Equation[
        outMax ~ sISO.outMax,   # connect(outMax, sISO.outMax)
        outMin ~ sISO.outMin,   # connect(outMin, sISO.outMin)
    ]
    extend(System(eqs, t, vars, []; name), base)
end
