# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Controls/PSSE/ES/BaseClasses/RectifierCommutationVoltageDrop.mo (model)
# Blocks: gain2 = Gain(k = K_C), fEX = FEX, product1 = Product, division = Division. Ports are plain variables
# (V_EX, XADIFD, EFD); the causal connects are equalities. Omitted: graphical annotations.

@component function RectifierCommutationVoltageDrop(; name, K_C)
    K_C = float(K_C)
    pars = @parameters begin
        K_C = K_C, [description = "Rectifier load factor"]
    end
    systems = @named begin
        gain2 = Gain(; k = K_C)
        fEX = FEX()
        product1 = Product()
        division = Division()
    end
    vars = @variables begin
        V_EX(t)
        XADIFD(t)
        EFD(t)
    end
    eqs = Equation[
        V_EX ~ division.u2,          # connect(V_EX, division.u2)
        XADIFD ~ gain2.u,            # connect(XADIFD, gain2.u)
        gain2.y ~ division.u1,       # connect(gain2.y, division.u1)
        division.y ~ fEX.u,          # connect(division.y, fEX.u)
        product1.y ~ EFD,            # connect(product1.y, EFD)
        fEX.y ~ product1.u2,         # connect(fEX.y, product1.u2)
        product1.u1 ~ division.u2,   # connect(product1.u1, division.u2)
    ]
    System(eqs, t, vars, pars; name, systems)
end
