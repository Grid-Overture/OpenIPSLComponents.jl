# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/BaseClasses/RotatingExciterWithDemagnetization.mo (extends
# RotatingExciterBase with `redeclare Add3 Sum(k3 = K_D)` and `redeclare replaceable Integrator sISO(k = 1/T_E,
# initType = InitialOutput, y_start = Efd0)`)
# The two redeclares are the defaults of the `Sum` and `sISO` keywords (F-20 b; `sISO` receives the base's T_E and
# Efd0, `Sum` this constructor's K_D, F-39). The base is built with a plain call, not `@named`: `extend` merges it at
# this level and `@named` would scope the forwarded symbols one level too far (F-39). Adds the parameter K_D, the
# ports XADIFD and V_FE (plain variables) and two causal connects.
# Omitted: graphical annotations.

@component function RotatingExciterWithDemagnetization(; name, T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, Efd0, K_D,
        sISO = (; name, T_E, Efd0) -> Integrator(; name, k = 1 / T_E, initType = :InitialOutput, y_start = Efd0),
        Sum = (; name) -> Add3(; name, k3 = K_D))
    K_D = float(K_D)
    base = RotatingExciterBase(; name = :base, T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, Efd0, sISO, Sum)
    @unpack Sum, feedback = base
    pars = @parameters begin
        K_D = K_D, [description = "Exciter demagnetizing factor"]
    end
    vars = @variables begin
        XADIFD(t)
        V_FE(t)
    end
    eqs = Equation[
        XADIFD ~ Sum.u3,       # connect(XADIFD, Sum.u3)
        V_FE ~ feedback.u2,    # connect(V_FE, feedback.u2)
    ]
    extend(System(eqs, t, vars, pars; name), base)
end
