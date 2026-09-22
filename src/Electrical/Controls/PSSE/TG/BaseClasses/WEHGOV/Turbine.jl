# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/TG/BaseClasses/WEHGOV/Turbine.mo (model)
# Blocks: Lookup_Gate_Flow = CombiTable1Ds([G1 FLWG1; G2 FLWG2], LinearSegments), division = Division,
# product1/product2/product3 = Product, add = Add(k1 = -1), Turbine_Head_ref = Constant(1),
# integrator = Integrator(1/TW, InitialOutput, y_start = f0), Lookup_Flow_Pmech = CombiTable1Ds(the six
# (FLWP, Pmech) points, LinearSegments), add1 = Add(k1 = -1), gain1 = Gain(D_TURB). Ports as plain variables:
# Gate_Position, SPEED, PMECH0 (inputs), PMECH (output).
# Four `fixed = false` parameters (`Pmech0`, `p0`, `sG`, `f0`). `sG` is the inverse of the two-point gate/flow table,
# a single segment; `f0` is the inverse of the flow/power table written with **five** branches, not the nine of
# `Governor.mo` (the .mo keeps the ten-point version commented out above it and the five-branch one does not cover
# `Pmech2 < p0 <= Pmech3` through its own segment - the `else` does). Both quirks are reproduced literally.
# `S_b` and `M_b` are declared and used nowhere: dead parameters, kept. The `start = sG` modifier of the input
# `Gate_Position` is a guess.
# Julia-only name: the class is `Turbine` in the `.mo`, as `BaseClasses.GGOV1.Turbine` is, and the package module is
# flat, so this one is `WEHGOV_Turbine`; `WEHGOV.jl` builds it with the .mo's instance name (`Turbine`), so no
# hierarchical name changes.
# Omitted: graphical annotations.

@component function WEHGOV_Turbine(; name, S_b = 100e6, M_b = 100e6, G1 = 0, G2 = 0.25, FLWG1 = 0, FLWG2 = 0.25,
        TW = 0.2, FLWP1 = 0, FLWP2 = 0.2, FLWP3 = 0.23, FLWP4 = 0.4, FLWP5 = 0.6, FLWP6 = 0.8, Pmech1 = 0,
        Pmech2 = 0, Pmech3 = 0.05, Pmech4 = 0.35, Pmech5 = 0.66, Pmech6 = 0.82, D_TURB = 0)
    S_b, M_b, G1, G2, FLWG1, FLWG2, TW, FLWP1, FLWP2, FLWP3, FLWP4, FLWP5, FLWP6, Pmech1, Pmech2, Pmech3, Pmech4,
    Pmech5, Pmech6, D_TURB = float.((S_b, M_b, G1, G2, FLWG1, FLWG2, TW, FLWP1, FLWP2, FLWP3, FLWP4, FLWP5, FLWP6,
        Pmech1, Pmech2, Pmech3, Pmech4, Pmech5, Pmech6, D_TURB))
    gate_tbl = [G1 FLWG1; G2 FLWG2]
    flow_tbl = [FLWP1 Pmech1; FLWP2 Pmech2; FLWP3 Pmech3; FLWP4 Pmech4; FLWP5 Pmech5; FLWP6 Pmech6]
    n = (; TW, D_TURB)
    pars = @parameters begin
        S_b = S_b, [description = "System base"]
        M_b = M_b, [description = "System base"]
        G1 = G1, [description = "Gate position 1"]
        G2 = G2, [description = "Gate position 2"]
        FLWG1 = FLWG1, [description = "Water flow rate 1"]
        FLWG2 = FLWG2, [description = "Water flow rate 2"]
        TW = TW, [description = "Water time constant"]
        FLWP1 = FLWP1
        FLWP2 = FLWP2
        FLWP3 = FLWP3
        FLWP4 = FLWP4
        FLWP5 = FLWP5
        FLWP6 = FLWP6
        Pmech1 = Pmech1
        Pmech2 = Pmech2
        Pmech3 = Pmech3
        Pmech4 = Pmech4
        Pmech5 = Pmech5
        Pmech6 = Pmech6
        D_TURB = D_TURB, [description = "Turbine damping"]
        Pmech0, [guess = 1.0]
        f0, [guess = 0.5]
        p0, [guess = 1.0]
        sG, [guess = 0.5]
    end
    systems = @named begin
        Lookup_Gate_Flow = CombiTable1Ds(; table = gate_tbl, smoothness = :LinearSegments)
        division = Division()
        product1 = Product()
        add = Add(; k1 = -1)
        Turbine_Head_ref = Constant(; k = 1)
        integrator = Integrator(; k = 1 / n.TW, initType = :InitialOutput, y_start = f0)
        Lookup_Flow_Pmech = CombiTable1Ds(; table = flow_tbl, smoothness = :LinearSegments)
        product2 = Product()
        add1 = Add(; k1 = -1)
        gain1 = Gain(; k = n.D_TURB)
        product3 = Product()
    end
    vars = @variables begin
        Gate_Position(t), [guess = 0.5]
        PMECH(t)
        SPEED(t)
        PMECH0(t)
    end
    eqs = Equation[
        Gate_Position ~ Lookup_Gate_Flow.u,        # connect(Gate_Position, Lookup_Gate_Flow.u)
        product1.y ~ add.u1,                       # connect(product1.y, add.u1)
        Turbine_Head_ref.y ~ add.u2,               # connect(Turbine_Head_ref.y, add.u2)
        add.y ~ integrator.u,                      # connect(add.y, integrator.u)
        Lookup_Flow_Pmech.y[1] ~ product2.u1,      # connect(Lookup_Flow_Pmech.y[1], product2.u1)
        product2.u2 ~ add.u1,                      # connect(product2.u2, add.u1)
        add1.y ~ PMECH,                            # connect(add1.y, PMECH)
        product2.y ~ add1.u2,                      # connect(product2.y, add1.u2)
        SPEED ~ gain1.u,                           # connect(SPEED, gain1.u)
        gain1.y ~ product3.u1,                     # connect(gain1.y, product3.u1)
        product3.u2 ~ Lookup_Gate_Flow.u,          # connect(product3.u2, Lookup_Gate_Flow.u)
        product3.y ~ add1.u1,                      # connect(product3.y, add1.u1)
        division.y ~ product1.u2,                  # connect(division.y, product1.u2)
        product1.u1 ~ product1.u2,                 # connect(product1.u1, product1.u2)
        Lookup_Gate_Flow.y[1] ~ division.u2,       # connect(Lookup_Gate_Flow.y[1], division.u2)
        integrator.y ~ Lookup_Flow_Pmech.u,        # connect(integrator.y, Lookup_Flow_Pmech.u)
        division.u1 ~ Lookup_Flow_Pmech.u,         # connect(division.u1, Lookup_Flow_Pmech.u)
    ]
    ieqs = [
        Pmech0 ~ PMECH0,
        p0 ~ Pmech0,
        sG ~ (f0 - FLWG1) * (G2 - G1) / (FLWG2 - FLWG1) + G1,
        f0 ~ ifelse((p0 <= Pmech6) & (p0 > Pmech5), (p0 - Pmech5) * (FLWP6 - FLWP5) / (Pmech6 - Pmech5) + FLWP5,
            ifelse((p0 <= Pmech5) & (p0 > Pmech4), (p0 - Pmech4) * (FLWP5 - FLWP4) / (Pmech5 - Pmech4) + FLWP4,
                ifelse((p0 <= Pmech4) & (p0 > Pmech3), (p0 - Pmech3) * (FLWP4 - FLWP3) / (Pmech4 - Pmech3) + FLWP3,
                    ifelse(p0 <= Pmech2, (p0 - Pmech1) * (FLWP2 - FLWP1) / (Pmech2 - Pmech1) + FLWP1,
                        (p0 - Pmech2) * (FLWP3 - FLWP2) / (Pmech3 - Pmech2) + FLWP2)))),
    ]
    System(eqs, t, vars, pars; name, systems, initialization_eqs = ieqs,
        initial_conditions = Dict(Pmech0 => missing, f0 => missing, p0 => missing, sG => missing))
end
