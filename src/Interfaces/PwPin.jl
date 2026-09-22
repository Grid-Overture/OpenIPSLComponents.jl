# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Interfaces/PwPin.mo
# PwPin_p and PwPin_n (used by PwLine and TwoWindingTransformer) only extend PwPin with another icon: PwPin is used for both.
# The `start = Modelica.Constants.eps` of ir/ii is not carried as `guess` metadata: in Modelica it is overridden by the
# component modifiers (baseMachine's `p(ir(start = ir0), ...)`), while in ModelingToolkit a metadata guess takes
# precedence over the parent's `guesses` and would block them (F-16).
# `irreducible` is a Julia-only keyword with no counterpart in the `.mo` (F-30): with it the pin's voltages stay
# unknowns of the network instead of being solved symbolically by ModelingToolkit's tearing, which for two branches
# with the same R and X picks a pivot that is identically zero (`R3*X4 - X3*R4`) and makes the compiled system
# evaluate to `Inf`. `Bus` sets it; every other component keeps the default.
# Omitted: graphical annotations.

@connector function PwPin(; name, irreducible = false)
    vars = @variables begin
        vr(t), [irreducible = irreducible, description = "Real part of the voltage"]
        vi(t), [irreducible = irreducible, description = "Imaginary part of the voltage"]
        ir(t), [connect = Flow, description = "Real part of the current"]
        ii(t), [connect = Flow, description = "Imaginary part of the current"]
    end
    System(Equation[], t, vars, []; name)
end
