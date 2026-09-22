# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/BaseClasses/RotatingExciterWithDemagnetizationLimited.mo (extends
# RotatingExciterWithDemagnetization with `redeclare replaceable LimIntegrator sISO(outMin = 0, k = 1/T_E,
# initType = InitialOutput, y_start = Efd0, outMax = inf)`). As RotatingExciterLimited.jl: the redeclare is the
# default of `sISO`. Omitted: graphical annotations.

RotatingExciterWithDemagnetizationLimited(; name, T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, Efd0, K_D,
    sISO = (; name, T_E, Efd0) -> LimIntegrator(; name, outMin = 0, k = 1 / T_E, initType = :InitialOutput, y_start = Efd0,
        outMax = Modelica.Constants.inf)) =
    RotatingExciterWithDemagnetization(; name, T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, Efd0, K_D, sISO)
