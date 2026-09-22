# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Solar/PowerFactory/DIgSILENT/Auxiliary/SLDWindV.mo (extends nothing)
# Blocks, with the names of the .mo: add = Add(k1 = -1, k2 = 1), gain = Gain(K_FRT), product = Product,
# const = Constant(Deadband) (instance `const_`, a Julia keyword), duac_abs = Abs, division = Division,
# limiter = Limiter(uMax = inf, uMin = Deadband). Ports are plain variables (duac; diq). The SDLWindV dynamic voltage
# support: `diq = K_FRT*(|duac| - Deadband)*duac/max(|duac|, Deadband)` (the division by the limited magnitude is
# essentially the sign of duac). Omitted: graphical annotations.

@component function SLDWindV(; name, Deadband, K_FRT)
    Deadband, K_FRT = float.((Deadband, K_FRT))
    inf = Modelica.Constants.inf
    pars = @parameters begin
        Deadband = Deadband, [description = "Deadband for dynamic AC voltage support (pu)"]
        K_FRT = K_FRT, [description = "Gain for dynamic AC voltage supports"]
    end
    systems = @named begin
        add = Add(; k1 = -1, k2 = 1)
        gain = Gain(; k = K_FRT)
        product = Product()
        const_ = OpenIPSLComponents.Constant(; k = Deadband)
        duac_abs = Abs()
        division = Division()
        limiter = Limiter(; uMax = inf, uMin = Deadband)
    end
    vars = @variables begin
        duac(t), [description = "Voltage deviation (pu)"]
        diq(t), [description = "Reactive current support (pu)"]
    end
    eqs = Equation[
        product.y ~ gain.u,              # connect(product.y, gain.u)
        duac_abs.u ~ duac,               # connect(duac_abs.u, duac)
        gain.y ~ diq,                    # connect(gain.y, diq)
        add.u1 ~ const_.y,               # connect(add.u1, const.y)
        add.u2 ~ duac_abs.y,             # connect(add.u2, duac_abs.y)
        division.u2 ~ limiter.y,         # connect(division.u2, limiter.y)
        division.u1 ~ duac,              # connect(division.u1, duac)
        division.y ~ product.u2,         # connect(division.y, product.u2)
        product.u1 ~ add.y,              # connect(product.u1, add.y)
        limiter.u ~ duac_abs.y,          # connect(limiter.u, duac_abs.y)
    ]
    System(eqs, t, vars, pars; name, systems)
end
