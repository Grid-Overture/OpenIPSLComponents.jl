# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/BaseClasses/RotatingExciter.mo (extends RotatingExciterBase with
# `redeclare replaceable Integrator sISO(k = 1/T_E, initType = InitialOutput, y_start = Efd0)`)
# The redeclare is the default of the `sISO` keyword, a closure that receives the base's T_E and Efd0 (F-20 b,
# F-39); it adds no parameter, variable or equation, so the base is returned under this name. Omitted: graphical annotations.

RotatingExciter(; name, T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, Efd0,
    sISO = (; name, T_E, Efd0) -> Integrator(; name, k = 1 / T_E, initType = :InitialOutput, y_start = Efd0), Sum = Add) =
    RotatingExciterBase(; name, T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, Efd0, sISO, Sum)
