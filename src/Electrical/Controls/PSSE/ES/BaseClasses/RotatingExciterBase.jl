# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/BaseClasses/RotatingExciterBase.mo (model, the base of the family)
# Blocks: gain = Gain(k = K_E), Sum (replaceable Add), VE = Product, se1 = ImSE(S_EE_1, S_EE_2, E_1, E_2),
# feedback = Feedback, sISO (replaceable SISO). Ports are plain variables (I_C, EFD); the causal connects are
# equalities. The two `replaceable` components are constructor keyword arguments that receive a constructor (F-20 b):
# `sISO` is mandatory (a partial SISO has no default) and `Sum` defaults to Add. The `redeclare` modifiers of the
# children refer to this base's parameters (`k = 1/T_E`, `y_start = Efd0`), so `sISO` is a closure
# `(; name, T_E, Efd0) -> Integrator(; name, k = 1/T_E, initType = :InitialOutput, y_start = Efd0)` that the base
# calls with its own symbols scoped as `@named` scopes a keyword argument (`ParentScope`, F-39: a symbol handed to
# a block is valid one level below its owner only). `Sum` takes `(; name)` (its `k3 = K_D` is the child's number).
# K_E and Efd0 may be symbolic: the exciters pass their `fixed = false` parameters (F-33, PLAN-04).
# Omitted: graphical annotations.

@component function RotatingExciterBase(; name, T_E, K_E, E_1, E_2, S_EE_1, S_EE_2, Efd0, sISO, Sum = Add)
    T_E, E_1, E_2, S_EE_1, S_EE_2 = float.((T_E, E_1, E_2, S_EE_1, S_EE_2))
    sat = (; S_EE_1, S_EE_2, E_1, E_2)   # numeric copies for ImSE, before @parameters rebinds the names (F-22)
    pars = @parameters begin
        T_E = T_E, [description = "Exciter time constant (s)"]
        K_E = K_E, [description = "Exciter field gain"]
        E_1 = E_1, [description = "Exciter saturation point 1 (pu)"]
        E_2 = E_2, [description = "Exciter saturation point 2 (pu)"]
        S_EE_1 = S_EE_1, [description = "Saturation at E_1 (pu)"]
        S_EE_2 = S_EE_2, [description = "Saturation at E_2 (pu)"]
        Efd0 = Efd0
    end
    systems = @named begin
        gain = Gain(; k = K_E)
        Sum = Sum()
        VE = Product()
        se1 = ImSE(; SE1 = sat.S_EE_1, SE2 = sat.S_EE_2, E1 = sat.E_1, E2 = sat.E_2)
        feedback = Feedback()
    end
    sISO = sISO(; name = :sISO, T_E = ParentScope(T_E), Efd0 = ParentScope(Efd0))
    push!(systems, sISO)
    vars = @variables begin
        I_C(t)
        EFD(t)
    end
    eqs = Equation[
        Sum.y ~ feedback.u2,      # connect(Sum.y, feedback.u2)
        se1.VE_OUT ~ VE.u2,       # connect(se1.VE_OUT, VE.u2)
        se1.VE_IN ~ EFD,          # connect(se1.VE_IN, EFD)
        VE.u1 ~ EFD,              # connect(VE.u1, EFD)
        gain.u ~ EFD,             # connect(gain.u, EFD)
        gain.y ~ Sum.u2,          # connect(gain.y, Sum.u2)
        VE.y ~ Sum.u1,            # connect(VE.y, Sum.u1)
        I_C ~ feedback.u1,        # connect(I_C, feedback.u1)
        feedback.y ~ sISO.u,      # connect(feedback.y, sISO.u)
        sISO.y ~ EFD,             # connect(sISO.y, EFD)
    ]
    System(eqs, t, vars, pars; name, systems)
end
