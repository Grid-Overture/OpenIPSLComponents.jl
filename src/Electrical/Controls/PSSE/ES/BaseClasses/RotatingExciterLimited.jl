# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/BaseClasses/RotatingExciterLimited.mo (extends RotatingExciterBase
# with `redeclare replaceable LimIntegrator sISO(k = 1/T_E, y_start = Efd0, outMin = 0, outMax = inf,
# initType = InitialOutput)`). As RotatingExciter.jl: the redeclare is the default of `sISO`.
# Omitted: graphical annotations.

RotatingExciterLimited(; name, T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, Efd0,
    sISO = (; name, T_E, Efd0) -> LimIntegrator(; name, k = 1 / T_E, y_start = Efd0, outMin = 0, outMax = Modelica.Constants.inf,
        initType = :InitialOutput), Sum = Add) =
    RotatingExciterBase(; name, T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, Efd0, sISO, Sum)
