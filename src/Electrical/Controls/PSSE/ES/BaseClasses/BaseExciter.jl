# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/BaseClasses/BaseExciter.mo (partial; extends nothing)
# Base of the PSSE excitation systems: the seven causal ports as plain variables (VUEL, VOEL, EFD, EFD0, VOTHSG,
# ECOMP, XADIFD), the voltage reference and the error sum as sub-blocks.
# `Efd0`, `V_REF` and `ECOMP0` are `parameter Real (fixed = false)` resolved by an `initial equation` from an INPUT
# (`Efd0 = EFD0`, `ECOMP0 = ECOMP` here; `V_REF` in each exciter), not from other parameters: they are declared
# without a value, with a `guess`, listed as `missing` in `initial_conditions` and given their equation in
# `initialization_eqs` (F-33; a `guess` alone leaves them out of the initialization system). Omitted: graphical
# annotations.

@component function BaseExciter(; name)
    pars = @parameters begin
        Efd0, [guess = 1.0]
        V_REF, [guess = 1.0]
        ECOMP0, [guess = 1.0]
    end
    systems = @named begin
        VoltageReference = Constant(; k = V_REF)
        DiffV = Add(; k2 = -1)
    end
    vars = @variables begin
        VUEL(t), [description = "Under excitation limiter signal"]
        VOEL(t), [description = "Over excitation limiter signal"]
        EFD(t), [description = "Excitation Voltage (pu)"]
        EFD0(t), [description = "Initial excitation voltage (pu)"]
        VOTHSG(t), [description = "Additional signal input"]
        ECOMP(t), [description = "Compensated voltage (pu)"]
        XADIFD(t), [description = "Machine field current (pu)"]
    end
    eqs = Equation[
        VoltageReference.y ~ DiffV.u1,   # connect(VoltageReference.y, DiffV.u1)
    ]
    System(eqs, t, vars, pars; name, systems,
        initial_conditions = Dict(Efd0 => missing, V_REF => missing, ECOMP0 => missing),
        initialization_eqs = [Efd0 ~ EFD0, ECOMP0 ~ ECOMP])
end
