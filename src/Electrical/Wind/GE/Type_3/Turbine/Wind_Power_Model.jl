# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenIPSL 3.1.0 - Electrical/Wind/GE/Type_3/Turbine/Wind_Power_Model.mo (extends nothing)
# Blocks, with the names of the .mo: limiter1 = Limiter(inf, 0.1) on the wind speed, division1 = omega/limiter1.y,
# Gain_KI = Gain(KI), limiter2 = Limiter(inf, 0.1) -> Lambda, product3 = Vw^2, product2 = Vw^3 (unlimited),
# product4 = cp*Vw^3, Gain_wndtge_kp = Gain(wndtge_kp) -> Pm, cp_function1 = Cp_function. Ports are plain variables
# (Wind_Speed, Theta, omega; Pm). Omitted: the `import`, graphical annotations.

@component function Wind_Power_Model(; name, KI = 1, wndtge_kp = 1)
    KI, wndtge_kp = float.((KI, wndtge_kp))
    inf = Modelica.Constants.inf
    systems = @named begin
        limiter1 = Limiter(; uMax = inf, uMin = 0.1)
        division1 = Division()
        Gain_KI = Gain(; k = KI)
        limiter2 = Limiter(; uMax = inf, uMin = 0.1)
        Gain_wndtge_kp = Gain(; k = wndtge_kp)
        product2 = Product()
        product3 = Product()
        product4 = Product()
        cp_function1 = Cp_function()
    end
    pars = @parameters begin
        KI = KI
        wndtge_kp = wndtge_kp
    end
    vars = @variables begin
        Wind_Speed(t), [description = "Wind speed"]
        Theta(t), [description = "Pitch angle"]
        omega(t), [description = "Turbine speed"]
        Pm(t), [description = "Mechanical power"]
    end
    eqs = Equation[
        limiter1.y ~ division1.u2,               # connect(limiter1.y, division1.u2)
        Wind_Speed ~ limiter1.u,                 # connect(Wind_Speed, limiter1.u)
        omega ~ division1.u1,                    # connect(omega, division1.u1)
        division1.y ~ Gain_KI.u,                 # connect(division1.y, Gain_KI.u)
        Wind_Speed ~ product2.u1,                # connect(Wind_Speed, product2.u1)
        Wind_Speed ~ product3.u1,                # connect(Wind_Speed, product3.u1)
        Wind_Speed ~ product3.u2,                # connect(Wind_Speed, product3.u2)
        Theta ~ cp_function1.Theta,              # connect(Theta, cp_function1.Theta)
        product4.y ~ Gain_wndtge_kp.u,           # connect(product4.y, Gain_wndtge_kp.u)
        Gain_wndtge_kp.y ~ Pm,                   # connect(Gain_wndtge_kp.y, Pm)
        product2.y ~ product4.u2,                # connect(product2.y, product4.u2)
        cp_function1.y ~ product4.u1,            # connect(cp_function1.y, product4.u1)
        limiter2.y ~ cp_function1.Lambda,        # connect(limiter2.y, cp_function1.Lambda)
        Gain_KI.y ~ limiter2.u,                  # connect(Gain_KI.y, limiter2.u)
        product3.y ~ product2.u2,                # connect(product3.y, product2.u2)
    ]
    System(eqs, t, vars, pars; name, systems)
end
