# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/DIgSILENT/DCBusBar.mo (extends nothing)
# Blocks, with the names of the .mo: add = Add(k2 = -1), P_to_I = Division, integrator = Integrator(SteadyState,
# k = 1/C, y_start = Modelica.Constants.eps). Ports are plain variables (P_conv, I_pv; Udc). The DC-link capacitor,
# `C der(Udc) = I_pv - P_conv/Udc`, with `der = 0` at t = 0 and the guess `eps = 1e-15` of the .mo (sic). The
# regime `I_pv(Udc) Udc = P_conv` has two close roots on the I-V curve of the array: the guess a plant gives to
# `integrator.y` (`Udc0` in `PV_Plant`) is what selects the one OpenModelica converged to. Omitted: graphical
# annotations.

@component function DCBusBar(; name, C = 1.5e-3)
    C = float(C)
    pars = @parameters begin
        C = C, [description = "Capacity of capacitor on DC busbar (F)"]
    end
    systems = @named begin
        add = Add(; k2 = -1)
        P_to_I = Division()
        integrator = Integrator(; initType = :SteadyState, k = 1 / C, y_start = Modelica.Constants.eps)
    end
    vars = @variables begin
        P_conv(t), [description = "Converter power (W)"]
        I_pv(t), [description = "Current array (A)"]
        Udc(t), [description = "DC voltage (V)"]
    end
    eqs = Equation[
        I_pv ~ add.u1,                   # connect(I_pv, add.u1)
        P_to_I.y ~ add.u2,               # connect(P_to_I.y, add.u2)
        P_conv ~ P_to_I.u1,              # connect(P_conv, P_to_I.u1)
        integrator.u ~ add.y,            # connect(integrator.u, add.y)
        integrator.y ~ Udc,              # connect(integrator.y, Udc)
        P_to_I.u2 ~ integrator.y,        # connect(P_to_I.u2, integrator.y)
    ]
    System(eqs, t, vars, pars; name, systems)
end
